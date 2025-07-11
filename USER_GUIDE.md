# 🚀 Aptos Vault - User Guide

## 📋 Tổng quan

Aptos Vault là một hệ thống DeFi trên Aptos Mainnet cho phép người dùng:
- ✅ Kết nối ví Pontem
- 💰 Nạp USDT LayerZero vào vault
- 💸 Rút USDT từ vault
- ⚖️ Tự động rebalance giữa USDT và APT
- 📊 Theo dõi hiệu suất vault

## 🔗 Kết nối Ví

### 1. Cài đặt Pontem Wallet
- Tải Pontem Wallet extension từ [pontem.network](https://pontem.network)
- Tạo ví mới hoặc import ví hiện có
- Đảm bảo có APT để trả phí gas

### 2. Kết nối với Vault
- Truy cập: http://localhost:5174/
- Click "🔗 Connect Pontem Wallet"
- Chấp nhận kết nối trong extension
- Hoặc nhập địa chỉ ví thủ công

## 💰 Các tính năng chính

### 📥 Nạp USDT
1. Kết nối ví
2. Nhập số lượng USDT muốn nạp
3. Click "Deposit"
4. Xác nhận giao dịch trong ví

### 📤 Rút USDT
1. Kết nối ví
2. Nhập số shares muốn đốt
3. Click "Withdraw"
4. Xác nhận giao dịch trong ví

### ⚖️ Rebalance
1. Kết nối ví (chỉ owner)
2. Nhập số USDT muốn swap thành APT
3. Click "Rebalance"
4. Xác nhận giao dịch

## 📊 Theo dõi

### Vault Status
- **Total Shares**: Tổng số shares đã phát hành
- **Total USDT**: Tổng USDT trong vault
- **Total APT**: Tổng APT trong vault

### User Balance
- **Your Shares**: Số shares bạn sở hữu
- **USDT Value**: Giá trị USDT tương ứng

## 🔧 Thông tin kỹ thuật

### USDT LayerZero trên Aptos Mainnet
- **Token Address**: `0xf22bede237a07e121b56d91a491eb7bcdfd1f5907926a9e58338f964a01b17fa::asset::USDT`
- **Explorer**: https://explorer.aptoslabs.com/coin/0xf22bede237a07e121b56d91a491eb7bcdfd1f5907926a9e58338f964a01b17fa::asset::USDT?network=mainnet
- **Type**: LayerZero USDT (Cross-chain)
- **Decimals**: 6
- **Network**: Aptos Mainnet

### Địa chỉ quan trọng
- **Vault Address**: `0xb380dc1036ffeed2f2fe06977a17275e4a71d9ca3a3df58b370aa7faba336c4d`
- **USDT LayerZero**: `0xf22bede237a07e121b56d91a491eb7bcdfd1f5907926a9e58338f964a01b17fa::asset::USDT`
- **APT Token**: `0x1::aptos_coin::AptosCoin`
- **PancakeSwap Router**: `0xc7efb4076dbe143cbcd98cfaaa929ecfc8f299405d018d7e18f75ac2b0e95f60`

### Network
- **Network**: Aptos Mainnet
- **Explorer**: https://explorer.aptoslabs.com/
- **RPC**: https://fullnode.mainnet.aptoslabs.com

## 🚨 Lưu ý quan trọng

1. **Gas Fees**: Mọi giao dịch đều cần APT để trả phí gas
2. **Slippage**: Giao dịch swap có thể bị slippage
3. **Minimum Amount**: Nạp tối thiểu 1 USDT
4. **Security**: Luôn kiểm tra địa chỉ trước khi giao dịch
5. **USDT LayerZero**: Đây là USDT cross-chain qua LayerZero, có thể có phí bridge

## 🆘 Hỗ trợ

Nếu gặp vấn đề:
1. Kiểm tra kết nối internet
2. Đảm bảo có đủ APT cho gas
3. Refresh trang và thử lại
4. Liên hệ support nếu cần

## 🎯 Tính năng nâng cao

### Auto-rebalance
- Vault tự động rebalance mỗi 24h
- Tỷ lệ USDT/APT được tối ưu hóa
- Giảm thiểu rủi ro biến động

### Performance Tracking
- Theo dõi APY theo thời gian thực
- Lịch sử giao dịch chi tiết
- Báo cáo hiệu suất định kỳ

### USDT LayerZero Integration
- Hỗ trợ USDT cross-chain
- Tích hợp với LayerZero protocol
- Bridge USDT từ các chain khác

---

**🎉 Chúc bạn sử dụng Aptos Vault hiệu quả!** 