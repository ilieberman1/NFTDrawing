# drawing_platform.vy
# An NFT contract for storing drawing metadata on-chain with IPFS integration
# and minting drawings as NFTs for ETH with marketplace support.

# ------------------------------------------------------
# Compilation target: Vyper >=0.3.x
# ------------------------------------------------------

# ------------------------------------------------------
# CONSTANTS
# ------------------------------------------------------
MAX_TOKENS: constant(uint256) = 1000  # Maximum number of tokens to iterate over

# ------------------------------------------------------
# INTERFACES
# ------------------------------------------------------

interface ERC721Receiver:
    def onERC721Received(operator: address, from_addr: address, tokenId: uint256, data: Bytes[1024]) -> bytes4: view

# ------------------------------------------------------
# DATA STRUCTURES
# ------------------------------------------------------

# Drawing NFT metadata structure
struct DrawingNFT:
    creator: address       # Who created/minted it
    royaltyReceiver: address  # Who receives royalties (default: creator)
    imageIpfsHash: String[64]  # IPFS hash for the raw image
    metadataIpfsHash: String[64]  # IPFS hash for the metadata JSON
    title: String[64]      # Drawing title
    timestamp: uint256     # When it was minted
    royaltyPercentage: uint256  # Creator royalty % (in basis points, e.g. 250 = 2.5%)

# Listing structure for marketplace
struct Listing:
    seller: address
    price: uint256
    isActive: bool

# ------------------------------------------------------
# STATE VARIABLES
# ------------------------------------------------------

owner: public(address)
tokenCounter: public(uint256)           # Tracks next tokenId to mint
drawings: public(HashMap[uint256, DrawingNFT])  # tokenId -> drawing metadata
listings: public(HashMap[uint256, Listing])  # tokenId -> listing details

# ERC721 compliance variables
name: public(String[32])
symbol: public(String[8])
balanceOf: public(HashMap[address, uint256])
ownerOf: public(HashMap[uint256, address])
getApproved: public(HashMap[uint256, address])
isApprovedForAll: public(HashMap[address, HashMap[address, bool]])

# Secondary market
mintPrice: public(uint256)  # Price to mint a drawing, changeable by owner
platformFee: public(uint256)  # Fee percentage in basis points (e.g. 500 = 5%)

# ------------------------------------------------------
# EVENTS
# ------------------------------------------------------

event OwnershipTransferred:
    previousOwner: address
    newOwner: address

event DrawingMinted:
    tokenId: uint256
    creator: address
    imageIpfsHash: String[64]
    metadataIpfsHash: String[64]
    title: String[64]
    pricePaid: uint256

event Transfer:
    sender: address
    receiver: address
    tokenId: uint256

event Approval:
    owner: address
    approved: address
    tokenId: uint256

event ApprovalForAll:
    owner: address
    operator: address
    approved: bool

event DrawingListed:
    tokenId: uint256
    seller: address
    price: uint256

event DrawingSold:
    tokenId: uint256
    price: uint256
    seller: address
    buyer: address

event MintPriceChanged:
    oldPrice: uint256
    newPrice: uint256

# ------------------------------------------------------
# CONSTRUCTOR
# ------------------------------------------------------

@deploy
def __init__():
    """
    Initialize contract state.
    """
    self.owner = msg.sender
    self.tokenCounter = 1  # Start token IDs at 1
    self.mintPrice = 10**16  # Default 0.01 ETH (0.01 * 10**18 wei = 10**16 wei)
    self.platformFee = 250  # 2.5% fee
    self.name = "DrawingPlatform"
    self.symbol = "DRAW"

# ------------------------------------------------------
# MODIFIERS (INLINE)
# ------------------------------------------------------

@internal
def onlyOwner():
    """
    Restrict function to the contract owner.
    """
    assert msg.sender == self.owner, "Only owner can call this function"

@internal
def onlyTokenOwner(tokenId: uint256):
    """
    Restrict function to the token owner.
    """
    assert msg.sender == self.ownerOf[tokenId], "Only token owner can call this function"

# ------------------------------------------------------
# CORE FUNCTIONS
# ------------------------------------------------------

@external
@payable
def mintDrawingNFT(imageIpfsHash: String[64], metadataIpfsHash: String[64], title: String[64], royaltyPercentage: uint256) -> uint256:
    """
    Mint a new drawing NFT by paying the required mint price.
    The `imageIpfsHash` is the raw image, and `metadataIpfsHash` is the JSON metadata.
    Returns the new token ID.
    """
    # Validate inputs
    assert msg.value >= self.mintPrice, "Not enough ETH sent to mint"
    assert len(imageIpfsHash) > 0, "Image IPFS hash required"
    assert len(metadataIpfsHash) > 0, "Metadata IPFS hash required"
    assert royaltyPercentage <= 1000, "Royalty cannot exceed 10%"
    
    # Create a new token
    newTokenId: uint256 = self.tokenCounter
    self.tokenCounter += 1
    
    # Store drawing metadata
    self.drawings[newTokenId] = DrawingNFT({
        creator: msg.sender,
        royaltyReceiver: msg.sender,  # Default to creator as royalty receiver
        imageIpfsHash: imageIpfsHash,
        metadataIpfsHash: metadataIpfsHash,
        title: title,
        timestamp: block.timestamp,
        royaltyPercentage: royaltyPercentage
    })
    
    # Assign ownership (ERC721)
    self.ownerOf[newTokenId] = msg.sender
    self.balanceOf[msg.sender] += 1
    
    # Emit events
    log DrawingMinted(newTokenId, msg.sender, imageIpfsHash, metadataIpfsHash, title, msg.value)
    log Transfer(empty(address), msg.sender, newTokenId)
    
    return newTokenId

@external
def listDrawingForSale(tokenId: uint256, price: uint256):
    """
    List a drawing for sale on the secondary market.
    """
    self.onlyTokenOwner(tokenId)
    assert price > 0, "Price must be greater than zero"
    assert self.listings[tokenId].isActive == False, "NFT is already listed"
    
    self.listings[tokenId] = Listing({
        seller: msg.sender,
        price: price,
        isActive: True
    })
    
    log DrawingListed(tokenId, msg.sender, price)

@external
@payable
def buyDrawing(tokenId: uint256):
    """
    Buy a drawing that's listed for sale.
    """
    listing: Listing = self.listings[tokenId]
    assert listing.isActive, "NFT is not listed for sale"
    assert msg.value >= listing.price, "Not enough ETH sent"
    
    seller: address = listing.seller
    drawing: DrawingNFT = self.drawings[tokenId]
    
    # Calculate fees and royalties
    platformAmount: uint256 = (listing.price * self.platformFee) // 10000
    royaltyAmount: uint256 = (listing.price * drawing.royaltyPercentage) // 10000
    sellerAmount: uint256 = listing.price - platformAmount - royaltyAmount
    
    # Transfer ownership
    self._transferFrom(seller, msg.sender, tokenId)
    
    # Send ETH to parties
    send(self.owner, platformAmount)
    if royaltyAmount > 0:
        send(drawing.royaltyReceiver, royaltyAmount)
    send(seller, sellerAmount)
    
    # Deactivate listing
    self.listings[tokenId].isActive = False
    
    # Refund excess ETH
    if msg.value > listing.price:
        send(msg.sender, msg.value - listing.price)
    
    log DrawingSold(tokenId, listing.price, seller, msg.sender)

# ------------------------------------------------------
# OWNER FUNCTIONS
# ------------------------------------------------------

@external
def changeMintPrice(newPrice: uint256):
    """
    Update the price to mint a drawing.
    """
    self.onlyOwner()
    oldPrice: uint256 = self.mintPrice
    self.mintPrice = newPrice
    log MintPriceChanged(oldPrice, newPrice)

@external
def changeOwner(newOwner: address):
    """
    Transfer contract ownership to a new owner.
    """
    self.onlyOwner()
    assert newOwner != empty(address), "New owner cannot be zero address"
    assert newOwner != self.owner, "New owner must be different from current owner"

    previousOwner: address = self.owner
    self.owner = newOwner

    log OwnershipTransferred(previousOwner, newOwner)

# ------------------------------------------------------
# ERC721 IMPLEMENTATION (Simplified for Brevity)
# ------------------------------------------------------

@external
def approve(to: address, tokenId: uint256):
    """
    Approve an address to transfer a token.
    """
    owner: address = self.ownerOf[tokenId]
    assert msg.sender == owner or self.isApprovedForAll[owner][msg.sender], "Not authorized"
    self.getApproved[tokenId] = to
    log Approval(owner, to, tokenId)

@external
def transferFrom(from_addr: address, to: address, tokenId: uint256):
    """
    Transfer a token - the msg.sender must be the current owner, an authorized
    operator, or approved address.
    """
    assert self._isApprovedOrOwner(msg.sender, tokenId), "Not authorized"
    self._transferFrom(from_addr, to, tokenId)

@internal
def _transferFrom(from_addr: address, to: address, tokenId: uint256):
    """
    Internal function to transfer token ownership.
    """
    assert from_addr == self.ownerOf[tokenId], "From address is not owner"
    assert to != empty(address), "Cannot transfer to zero address"
    
    # Clear approvals
    self.getApproved[tokenId] = empty(address)
    
    # Update balances
    self.balanceOf[from_addr] -= 1
    self.balanceOf[to] += 1
    
    # Update ownership
    self.ownerOf[tokenId] = to
    
    # Deactivate listing if active
    if self.listings[tokenId].isActive:
        self.listings[tokenId].isActive = False
    
    # Emit event
    log Transfer(from_addr, to, tokenId)

@view
@internal
def _isApprovedOrOwner(spender: address, tokenId: uint256) -> bool:
    """
    Returns whether the spender is allowed to manage the token.
    """
    owner: address = self.ownerOf[tokenId]
    return (spender == owner or 
            spender == self.getApproved[tokenId] or 
            self.isApprovedForAll[owner][spender])

# ------------------------------------------------------
# VIEW / READ-ONLY FUNCTIONS
# ------------------------------------------------------

@view
@external
def getDrawingMetadata(tokenId: uint256) -> (address, address, String[64], String[64], String[64], uint256, uint256):
    """
    Return the stored metadata for a given tokenId:
    (creator, royaltyReceiver, imageIpfsHash, metadataIpfsHash, title, timestamp, royaltyPercentage)
    """
    drawing: DrawingNFT = self.drawings[tokenId]
    assert drawing.creator != empty(address), "No NFT found for that tokenId"
    return (drawing.creator, drawing.royaltyReceiver, drawing.imageIpfsHash, drawing.metadataIpfsHash, drawing.title, drawing.timestamp, drawing.royaltyPercentage)

@view
@external
def tokenURI(tokenId: uint256) -> String[128]:
    """
    Returns a URI for a given token ID.
    Returns the IPFS URI for the metadata JSON file.
    """
    assert self.ownerOf[tokenId] != empty(address), "Token does not exist"
    drawing: DrawingNFT = self.drawings[tokenId]
    return concat("ipfs://", drawing.metadataIpfsHash)

@view
@external
def getRoyaltyInfo(tokenId: uint256, salePrice: uint256) -> (address, uint256):
    """
    Returns royalty information for a token (receiver and amount) based on sale price.
    """
    drawing: DrawingNFT = self.drawings[tokenId]
    royaltyAmount: uint256 = (salePrice * drawing.royaltyPercentage) // 10000
    return (drawing.royaltyReceiver, royaltyAmount)

@view
@external
def getListingPrice(tokenId: uint256) -> uint256:
    """
    Returns the price of a listed NFT, or 0 if not listed.
    """
    if self.listings[tokenId].isActive:
        return self.listings[tokenId].price
    return 0

@external
@view
def getListedNFTs() -> DynArray[uint256, 100]:
    """
    Return an array of token IDs currently listed for sale.
    Limited to 100 listings for gas efficiency.
    """
    listedTokens: DynArray[uint256, 100] = []
    for tokenId: uint256 in range(1, MAX_TOKENS):
        if len(listedTokens) >= 100:
            break
        if self.listings[tokenId].isActive:
            listedTokens.append(tokenId)
    return listedTokens