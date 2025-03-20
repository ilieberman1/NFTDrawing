# drawing_platform.vy
# An NFT contract for storing drawing metadata on-chain with IPFS integration
# and minting drawings as NFTs for ETH.

# ------------------------------------------------------
# Compilation target: Vyper >=0.3.x
# ------------------------------------------------------

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
    ipfsHash: String[64]   # IPFS hash for the drawing data
    title: String[64]      # Drawing title
    timestamp: uint256     # When it was minted
    royaltyPercentage: uint256  # Creator royalty % (in basis points, e.g. 250 = 2.5%)

# ------------------------------------------------------
# STATE VARIABLES
# ------------------------------------------------------

owner: public(address)
tokenCounter: public(uint256)           # Tracks next tokenId to mint
drawings: public(HashMap[uint256, DrawingNFT])  # tokenId -> drawing metadata

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
    ipfsHash: String[64]
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
def mintDrawingNFT(ipfsHash: String[64], title: String[64], royaltyPercentage: uint256) -> uint256:
    """
    Mint a new drawing NFT by paying the required mint price.
    The `ipfsHash` should reference the IPFS storage of the drawing data.
    Returns the new token ID.
    """
    # Validate inputs
    assert msg.value >= self.mintPrice, "Not enough ETH sent to mint"
    assert len(ipfsHash) > 0, "IPFS hash required"
    assert royaltyPercentage <= 1000, "Royalty cannot exceed 10%"
    
    # Create a new token
    newTokenId: uint256 = self.tokenCounter
    self.tokenCounter += 1
    
    # Store drawing metadata
    self.drawings[newTokenId] = DrawingNFT({
        creator: msg.sender,
        royaltyReceiver: msg.sender,  # Default to creator as royalty receiver
        ipfsHash: ipfsHash,
        title: title,
        timestamp: block.timestamp,
        royaltyPercentage: royaltyPercentage
    })
    
    # Assign ownership (ERC721)
    self.ownerOf[newTokenId] = msg.sender
    self.balanceOf[msg.sender] += 1
    
    # Emit events
    log DrawingMinted(newTokenId, msg.sender, ipfsHash, title, msg.value)
    log Transfer(empty(address), msg.sender, newTokenId)
    
    return newTokenId

@external
def listDrawingForSale(tokenId: uint256, price: uint256):
    """
    List a drawing for sale on the secondary market (not implemented fully here for simplicity).
    """
    self.onlyTokenOwner(tokenId)
    assert price > 0, "Price must be greater than zero"
    # In a full implementation, you'd store the listing data, but for simplicity, we'll skip it here.

@external
@payable
def buyDrawing(tokenId: uint256):
    """
    Buy a drawing that's listed for sale (simplified version).
    """
    seller: address = self.ownerOf[tokenId]
    drawing: DrawingNFT = self.drawings[tokenId]
    
    # For simplicity, assume a fixed price (e.g., 0.1 ETH). In a real implementation, you'd check a listing price.
    price: uint256 = 10**17  # Example price of 0.1 ETH (0.1 * 10**18 wei = 10**17 wei)
    assert msg.value >= price, "Not enough ETH sent"
    
    # Calculate fees and royalties
    platformAmount: uint256 = (price * self.platformFee) // 10000
    royaltyAmount: uint256 = (price * drawing.royaltyPercentage) // 10000
    sellerAmount: uint256 = price - platformAmount - royaltyAmount
    
    # Transfer ownership
    self._transferFrom(seller, msg.sender, tokenId)
    
    # Send ETH to parties (using raw_call for robustness, though simplified here)
    send(self.owner, platformAmount)
    if royaltyAmount > 0:
        send(drawing.royaltyReceiver, royaltyAmount)
    send(seller, sellerAmount)
    
    # Refund excess ETH
    if msg.value > price:
        send(msg.sender, msg.value - price)
    
    log DrawingSold(tokenId, price, seller, msg.sender)

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
def getDrawingMetadata(tokenId: uint256) -> (address, address, String[64], String[64], uint256, uint256):
    """
    Return the stored metadata for a given tokenId:
    (creator, royaltyReceiver, ipfsHash, title, timestamp, royaltyPercentage)
    """
    drawing: DrawingNFT = self.drawings[tokenId]
    assert drawing.creator != empty(address), "No NFT found for that tokenId"
    return (drawing.creator, drawing.royaltyReceiver, drawing.ipfsHash, drawing.title, drawing.timestamp, drawing.royaltyPercentage)

@view
@external
def tokenURI(tokenId: uint256) -> String[128]:
    """
    Returns a URI for a given token ID.
    In this case, we return the IPFS URI.
    """
    assert self.ownerOf[tokenId] != empty(address), "Token does not exist"
    drawing: DrawingNFT = self.drawings[tokenId]
    return concat("ipfs://", drawing.ipfsHash)

@view
@external
def getRoyaltyInfo(tokenId: uint256, salePrice: uint256) -> (address, uint256):
    """
    Returns royalty information for a token (receiver and amount) based on sale price.
    """
    drawing: DrawingNFT = self.drawings[tokenId]
    royaltyAmount: uint256 = (salePrice * drawing.royaltyPercentage) // 10000
    return (drawing.royaltyReceiver, royaltyAmount)