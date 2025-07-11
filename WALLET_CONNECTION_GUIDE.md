# 🔗 Wallet Connection Guide - Aptos Vault

## Overview

The Aptos Vault now includes a comprehensive wallet connection feature that allows users to connect their Pontem wallet to interact with the vault directly from the UI. This feature provides real-time balance checking, secure transaction signing, and seamless integration with the Aptos blockchain.

## Features

### ✅ Available Features

1. **Pontem Wallet Integration**
   - Automatic detection of Pontem wallet extension
   - Secure connection to user's wallet
   - Real-time balance display (APT and USDT)
   - Automatic address detection

2. **Manual Address Input**
   - Fallback option for users without Pontem wallet
   - Manual address entry for testing
   - Support for any valid Aptos address

3. **Real-time Balance Tracking**
   - Live APT balance from wallet
   - USDT balance display (with LayerZero support)
   - Automatic balance refresh
   - Visual balance indicators

4. **Enhanced UI/UX**
   - Connection status indicators
   - Loading states during operations
   - Error handling and user feedback
   - Responsive design for mobile/desktop

5. **Security Features**
   - Secure wallet disconnection
   - Input validation
   - Error boundary handling
   - Safe transaction signing

## How to Use

### 1. Install Pontem Wallet

If you don't have Pontem wallet installed:

1. Visit [Pontem Network](https://pontem.network/)
2. Click "Install Wallet" or download from browser extension store
3. Create a new wallet or import existing one
4. Switch to Aptos Mainnet network

### 2. Connect Your Wallet

#### Option A: Pontem Wallet (Recommended)

1. **Open the Vault UI**
   - Navigate to the Aptos Vault section
   - Look for the "Connect Wallet" section

2. **Connect Pontem Wallet**
   - Click "🔗 Connect Pontem Wallet" button
   - Approve the connection in your Pontem wallet
   - Your address will be automatically detected

3. **Verify Connection**
   - Green dot indicator shows connected status
   - Your address will be displayed (shortened format)
   - APT and USDT balances will be shown

#### Option B: Manual Address Entry

1. **Enter Address Manually**
   - If Pontem wallet is not available, use the manual input
   - Enter your Aptos address in the text field
   - Address format: `0x...` (64 characters)

2. **Use the Vault**
   - All vault operations will work with manual address
   - Balance tracking will use API data

### 3. Using Connected Wallet

Once connected, you can:

- **View Balances**: See your APT and USDT balances in real-time
- **Deposit USDT**: Deposit USDT into the vault
- **Withdraw USDT**: Withdraw USDT from the vault
- **Rebalance**: Swap USDT for APT through the vault
- **Refresh Balance**: Click refresh button to update balances

### 4. Disconnect Wallet

- Click "Disconnect" button to safely disconnect
- All wallet data will be cleared
- You can reconnect anytime

## Technical Details

### Wallet Manager Architecture

The wallet connection uses a modular architecture:

```
WalletConnection.svelte (UI Component)
    ↓
wallet.ts (Wallet Manager)
    ↓
Pontem Wallet Extension
    ↓
Aptos Blockchain
```

### Key Components

1. **WalletConnection.svelte**
   - UI component for wallet connection
   - Handles user interactions
   - Displays connection status and balances

2. **wallet.ts**
   - Core wallet management logic
   - Pontem wallet integration
   - Balance fetching and state management

3. **Pontem Wallet Extension**
   - Browser extension for wallet functionality
   - Secure key management
   - Transaction signing

### Balance Types

- **APT Balance**: Native Aptos coin balance
- **USDT Balance**: USDT LayerZero token balance
- **Vault Shares**: User's share of the vault
- **USDT Value**: Equivalent USDT value of vault shares

## Error Handling

### Common Issues and Solutions

1. **"Pontem wallet not detected"**
   - Install Pontem wallet extension
   - Refresh the page after installation
   - Ensure extension is enabled

2. **"Failed to connect wallet"**
   - Check if Pontem wallet is unlocked
   - Try refreshing the page
   - Ensure you're on Aptos Mainnet

3. **"Failed to load wallet balance"**
   - Check network connection
   - Try refreshing the balance
   - Use manual address entry as fallback

4. **"Address already in use"**
   - Disconnect current wallet first
   - Try connecting again
   - Clear browser cache if needed

## Security Considerations

### Best Practices

1. **Always verify the connection**
   - Check the displayed address matches your wallet
   - Verify you're on the correct network (Aptos Mainnet)

2. **Keep your wallet secure**
   - Never share your private keys
   - Use hardware wallets for large amounts
   - Regularly update your wallet software

3. **Monitor transactions**
   - Review transaction details before signing
   - Check gas fees and slippage
   - Verify recipient addresses

### Privacy Features

- Addresses are displayed in shortened format
- No private keys are stored in the application
- All wallet operations happen locally in your browser
- Connection can be terminated at any time

## API Integration

The wallet connection integrates with the vault API:

```typescript
// Example API calls with connected wallet
const deposit = async (amount: number, userAddress: string) => {
  const response = await fetch('/api/vault/deposit', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ amount, user_address: userAddress })
  });
  return response.json();
};
```

## Development Notes

### Adding New Features

To extend the wallet functionality:

1. **Add new balance types**
   - Update `WalletBalance` interface in `wallet.ts`
   - Add balance fetching logic
   - Update UI components

2. **Support additional wallets**
   - Create new wallet manager class
   - Implement wallet interface
   - Update connection logic

3. **Add transaction signing**
   - Integrate with Pontem transaction API
   - Add transaction confirmation UI
   - Handle transaction status updates

### Testing

- Test with Pontem wallet extension
- Test with manual address entry
- Test error scenarios
- Test on different networks

## Support

If you encounter issues:

1. **Check browser console** for error messages
2. **Verify Pontem wallet installation**
3. **Ensure you're on Aptos Mainnet**
4. **Try refreshing the page**
5. **Contact support with error details**

## Future Enhancements

Planned improvements:

- [ ] Support for additional wallets (Petra, Martian)
- [ ] Transaction history display
- [ ] Multi-signature wallet support
- [ ] Hardware wallet integration
- [ ] Advanced balance analytics
- [ ] Cross-chain wallet support

---

**Note**: This wallet connection feature is designed for Aptos Mainnet. For testing, use Aptos Testnet with test tokens. 