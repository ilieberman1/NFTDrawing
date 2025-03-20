# NFTDrawing
I'm glad everything is working perfectly now! Below is a detailed and easy-to-read `README.md` file for your `NFTDRAWING` project. It describes the project, its functionality, setup instructions, and usage in a clear and organized manner. I've used Markdown formatting to ensure it's well-structured and readable.

---

# NFTDRAWING - Drawing NFT Platform

Welcome to **NFTDRAWING**, a web-based platform that lets you create digital drawings, mint them as NFTs (Non-Fungible Tokens) on the Ethereum blockchain (Sepolia testnet), and trade them in a marketplace. This project uses Pinata IPFS for decentralized storage, Firebase Hosting for deployment, and MetaMask for blockchain interactions.

## Table of Contents
- [What Does This Project Do?](#what-does-this-project-do)
- [Features](#features)
- [How It Works](#how-it-works)
- [Project Structure](#project-structure)
- [Prerequisites](#prerequisites)
- [Setup Instructions](#setup-instructions)
- [Usage](#usage)
- [Testing](#testing)
- [Deployment](#deployment)
- [Potential Issues](#potential-issues)
- [Future Improvements](#future-improvements)
- [License](#license)

---

## What Does This Project Do?

NFTDRAWING is a fun and creative platform where you can:
1. **Draw**: Create digital drawings using a canvas with a brush tool and color picker.
2. **Mint NFTs**: Save your drawings to Pinata IPFS (a decentralized storage system) and mint them as NFTs on the Ethereum Sepolia testnet.
3. **Trade NFTs**: List your NFTs for sale in a marketplace and buy NFTs from other users.
4. **View Your NFTs**: Add minted NFTs to your MetaMask wallet for easy viewing.

The platform is deployed on Firebase Hosting, making it accessible online, and integrates with MetaMask for secure blockchain transactions.

---

## Features

- **Drawing Canvas**:
  - Draw freely with a brush tool.
  - Choose your brush color using a gradient color picker.
  - Adjust the brush size with a slider.
  - Clear the canvas to start over.

- **NFT Minting**:
  - Save your drawing to Pinata IPFS for decentralized storage.
  - Mint your drawing as an ERC721 NFT on the Sepolia testnet.
  - Pay a small minting fee (set by the smart contract) plus an IPFS upload fee (0.001 ETH).
  - Automatically add the minted NFT to your MetaMask wallet.

- **Marketplace**:
  - List your NFTs for sale at a price you set (in Sepolia ETH).
  - Buy NFTs listed by other users.
  - Only the NFT owner can list it for sale.
  - Buying an NFT transfers ownership to the buyer.

- **User-Friendly Interface**:
  - Clean and simple design with clear status messages.
  - Error handling for transaction cancellations and other issues.
  - Responsive layout for easy use on desktop and mobile.

- **Blockchain Integration**:
  - Connects to MetaMask for wallet management.
  - Interacts with a deployed smart contract on the Sepolia testnet.
  - Uses Ethers.js to handle Ethereum transactions.

---

## How It Works

### Drawing
- The platform provides a canvas where you can draw using your mouse.
- Select a brush color from a gradient color picker (red to violet).
- Adjust the brush size using a slider.
- Clear the canvas if you want to start over.

### Minting an NFT
1. Draw something on the canvas.
2. Enter a title for your drawing.
3. Click "Save to Pinata IPFS and Mint".
4. The drawing is uploaded to Pinata IPFS, and metadata (title, description, and image URL) is generated and uploaded too.
5. A transaction is sent to the smart contract to mint the NFT (requires MetaMask confirmation).
6. The minted NFT is added to your MetaMask wallet, and you can see the IPFS links and token ID on the page.

### Marketplace
- **Listing an NFT**:
  - Enter the token ID of your NFT and the price (in Sepolia ETH).
  - Only the NFT owner can list it for sale.
  - Click "List for Sale" to list the NFT in the marketplace.
- **Buying an NFT**:
  - View all listed NFTs in the marketplace with their images, titles, token IDs, and prices.
  - Enter the token ID of the NFT you want to buy.
  - Click "Buy NFT" to purchase it (requires MetaMask confirmation).
  - Ownership of the NFT is transferred to you upon successful purchase.

---

## Project Structure

The project is organized as follows:

```
NFTDRAWING/
├── public/                  # Directory for files to be deployed to Firebase Hosting
│   ├── index.html           # Main HTML file with the app's UI and JavaScript
│   └── abi.json             # Smart contract ABI (copied here for deployment)
├── abi.json                 # Smart contract ABI (Application Binary Interface)
├── firebase.json            # Firebase configuration file for deployment
├── .firebaserc              # Firebase project configuration
├── .gitignore               # Git ignore file
└── README.md                # This README file
```

- **`public/index.html`**: Contains the entire application, including HTML, CSS, and JavaScript. It handles the drawing canvas, NFT minting, and marketplace functionality.
- **`abi.json`**: The ABI of the smart contract deployed on the Sepolia testnet. It defines the contract's functions (e.g., `mintDrawingNFT`, `listDrawingForSale`, `buyDrawing`).
- **`firebase.json`**: Configures Firebase Hosting, specifying the `public` directory as the deployment source and setting up rewrite rules for a single-page app.

---

## Prerequisites

Before setting up the project, ensure you have the following:

1. **MetaMask**:
   - Install the MetaMask browser extension (available for Chrome, Firefox, etc.).
   - Create or import a wallet.
   - Switch to the Sepolia testnet.
   - Fund your wallet with Sepolia ETH (use a faucet like [Sepolia Faucet](https://sepoliafaucet.com/)).

2. **A Web Browser**:
   - Use a modern browser like Chrome or Firefox with MetaMask installed.

---

## Setup Instructions

Follow these steps to set up the project locally:

1. **Clone or Download the Project**:
   - Clone the repository or download the project files to your computer.
   - Navigate to the project directory:
     ```bash
     cd /path/to/NFTDRAWING
     ```

2. **Right Click the File Titled "index.html" and press "Open With Live Server"**:

---

## Usage

### Running Locally
1. **Start a Local Server**:
   - Since the app fetches `abi.json` using `fetch`, you need to run it on a web server (not directly from the file system).
   - Use a simple HTTP server, such as the one provided by VSCode's Live Server extension, or run:
     ```bash
     npx http-server public
     ```
   - Open your browser and go to `http://localhost:8080` (or the port shown in the terminal).

2. **Connect MetaMask**:
   - The app will automatically prompt you to connect your MetaMask wallet.
   - Ensure you're on the Sepolia testnet and have Sepolia ETH in your wallet.

3. **Draw and Mint an NFT**:
   - Draw something on the canvas using the brush tool.
   - Enter a title for your drawing.
   - Click "Save to Pinata IPFS and Mint".
   - Confirm the transaction in MetaMask.
   - Once minted, you'll see the IPFS links and token ID, and the NFT will be added to your MetaMask wallet.

4. **Use the Marketplace**:
   - **List an NFT**:
     - Enter the token ID of your NFT and a price (in Sepolia ETH).
     - Click "List for Sale".
   - **Buy an NFT**:
     - Browse the listed NFTs in the marketplace.
     - Enter the token ID of an NFT you want to buy.
     - Click "Buy NFT" and confirm the transaction in MetaMask.

---

## Testing

### Test Drawing and Minting
1. Draw a simple shape on the canvas.
2. Enter a title and click "Save to Pinata IPFS and Mint".
3. Confirm the transaction in MetaMask.
4. Verify that:
   - The drawing is uploaded to Pinata IPFS (check the "Image IPFS Link").
   - Metadata is uploaded (check the "Metadata IPFS Link").
   - The NFT is minted (check the "Token ID").
   - The NFT appears in your MetaMask wallet.

### Test Transaction Cancellation
1. Start the minting process.
2. When MetaMask prompts for confirmation, click "Reject".
3. Ensure a message appears: "Transaction cancelled by user."

### Test Marketplace
1. **Listing**:
   - Mint an NFT and note its token ID.
   - Switch to a different MetaMask account (not the owner).
   - Try to list the NFT for sale. You should see an error: "You are not the owner of this NFT and cannot list it for sale."
   - Switch back to the owner account and list the NFT successfully.
2. **Buying**:
   - List an NFT for sale.
   - Switch to a different MetaMask account (the buyer).
   - Ensure the buyer has enough Sepolia ETH.
   - Buy the NFT and confirm the transaction.
   - Verify that ownership has transferred (the NFT should appear in the buyer's MetaMask wallet).

---

## Potential Issues

- **MetaMask Connection**:
  - If MetaMask fails to connect, ensure it's installed, unlocked, and set to the Sepolia testnet.
- **Insufficient Funds**:
  - Minting and buying require Sepolia ETH. Use a Sepolia faucet to fund your wallet.
- **Pinata IPFS Upload**:
  - If IPFS uploads fail, check the Pinata JWT token in `index.html`. Replace it with your own token if needed.
  - Ensure your drawing is not too large (Pinata has file size limits for free accounts).
- **CORS Issues**:
  - When deployed on Firebase, Pinata requests might fail due to CORS. Use a proxy or update Pinata settings to allow requests from your Firebase domain.
- **Smart Contract Errors**:
  - If minting or marketplace transactions fail, check the smart contract logs on Sepolia Etherscan (contract address: `0xAaeae7E1b59ee74AD9FB9a077E40C801D2aEDC75`).

---

## Future Improvements

- **Replace Hardcoded Pinata JWT**:
  - Store the Pinata JWT in an environment variable or a secure backend to avoid hardcoding it in the client-side code.
- **Add a Backend**:
  - Use a backend server (e.g., Node.js with Express) to handle Pinata uploads securely and manage user data.
- **Improve the Marketplace**:
  - Add filters to sort NFTs by price or date.
  - Display the owner of each NFT in the marketplace.
- **Enhance Drawing Tools**:
  - Add more drawing tools (e.g., shapes, text, undo/redo).
  - Allow saving drawings locally before minting.
- **Support Multiple Networks**:
  - Add support for other Ethereum networks (e.g., Mainnet, Polygon) by allowing users to switch networks.

---

## License

This project is licensed under the MIT License. Feel free to use, modify, and distribute it as you wish.

---

