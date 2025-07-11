# 💰 USDT LayerZero trên Aptos Mainnet

## 📊 Thông tin Token

### 🔗 Địa chỉ Token
```
0xf22bede237a07e121b56d91a491eb7bcdfd1f5907926a9e58338f964a01b17fa::asset::USDT
```

### 🌐 Explorer Link
https://explorer.aptoslabs.com/coin/0xf22bede237a07e121b56d91a491eb7bcdfd1f5907926a9e58338f964a01b17fa::asset::USDT?network=mainnet

## 📋 Thông tin chi tiết

### Token Details
- **Name**: USDT (Tether USD)
- **Symbol**: USDT
- **Decimals**: 6
- **Type**: LayerZero Cross-chain Token
- **Network**: Aptos Mainnet
- **Protocol**: LayerZero

### Smart Contract
- **Module**: `0xf22bede237a07e121b56d91a491eb7bcdfd1f5907926a9e58338f964a01b17fa::asset`
- **Resource**: `USDT`
- **Standard**: Aptos Coin Standard

## 🔄 Cross-chain Bridge

### LayerZero Integration
USDT LayerZero cho phép:
- ✅ Bridge USDT từ Ethereum
- ✅ Bridge USDT từ BSC
- ✅ Bridge USDT từ Polygon
- ✅ Bridge USDT từ các chain khác

### Bridge Process
1. **Source Chain**: Gửi USDT đến LayerZero bridge
2. **LayerZero**: Xử lý cross-chain message
3. **Aptos**: Nhận USDT và mint token
4. **User**: Nhận USDT LayerZero trên Aptos

## 💡 Sử dụng trong Vault

### Vault Integration
```move
// USDT LayerZero address
const USDT_ADDRESS: address = @0xf22bede237a07e121b56d91a491eb7bcdfd1f5907926a9e58338f964a01b17fa;
```

### Deposit Process
1. User bridge USDT từ chain khác
2. USDT LayerZero được mint trên Aptos
3. User approve USDT cho vault
4. Vault nhận USDT và mint shares

### Withdraw Process
1. User burn shares
2. Vault trả USDT LayerZero
3. User có thể bridge về chain khác

## 🚨 Lưu ý quan trọng

### Bridge Fees
- LayerZero bridge có phí
- Phí thay đổi theo network
- Cần có native token cho gas

### Slippage
- Bridge có thể có slippage
- Thời gian bridge: 5-30 phút
- Kiểm tra trạng thái bridge

### Security
- Luôn verify địa chỉ contract
- Kiểm tra LayerZero bridge status
- Không share private key

## 🔧 Technical Details

### Move Module Structure
```move
module 0xf22bede237a07e121b56d91a491eb7bcdfd1f5907926a9e58338f964a01b17fa::asset {
    struct USDT has key, store {
        value: u64,
    }
}
```

### Integration với Vault
```move
// Import USDT
use 0xf22bede237a07e121b56d91a491eb7bcdfd1f5907926a9e58338f964a01b17fa::asset::USDT;

// Transfer USDT
coin::transfer<USDT>(user_address, vault_address, amount);
```

## 📈 Market Data

### Current Status
- **Circulating Supply**: Dynamic (cross-chain)
- **Market Cap**: Tied to USDT market cap
- **Price**: 1:1 với USDT
- **Liquidity**: Available on PancakeSwap

### Trading Pairs
- **USDT/APT**: PancakeSwap
- **USDT/USDC**: Cross-chain
- **USDT/BUSD**: Cross-chain

## 🎯 Benefits

### Cho Users
- ✅ Cross-chain USDT access
- ✅ Stable value (1:1 với USDT)
- ✅ High liquidity
- ✅ Fast transactions

### Cho Vault
- ✅ Stable asset backing
- ✅ Cross-chain capital inflow
- ✅ Diversified user base
- ✅ Reduced volatility

---

**💡 USDT LayerZero là giải pháp cross-chain tốt nhất cho stablecoin trên Aptos!** 