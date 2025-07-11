# 🚀 Aptos Vault - DeFi Investment Platform

Dự án vault DeFi trên blockchain Aptos, tích hợp với PancakeSwap và giao diện web hiện đại.

## 📋 Tính năng

- ✅ **Vault Management**: Deposit/Withdraw USDT
- ✅ **Rebalancing**: Tự động swap USDT ↔ APT
- ✅ **PancakeSwap Integration**: Tích hợp với DEX
- ✅ **Modern UI**: Giao diện SvelteKit đẹp mắt
- ✅ **REST API**: API chuẩn cho frontend và trading bot
- ✅ **Aptos Blockchain**: Smart contract bằng Move language

## 🏗️ Kiến trúc

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Frontend      │    │   API Server    │    │   Aptos Vault   │
│   (SvelteKit)   │◄──►│   (Flask)       │◄──►│   (Move)        │
│   Port: 5173    │    │   Port: 5001    │    │   Testnet       │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## 🚀 Khởi động nhanh

### Cách 1: Sử dụng script tự động
```bash
./start_project.sh
```

### Cách 2: Khởi động thủ công

#### Bước 1: Khởi động API Server
```bash
# Tạo virtual environment
python3 -m venv aptos_vault_env
source aptos_vault_env/bin/activate

# Cài đặt dependencies
pip install flask flask-cors requests

# Khởi động API server
python aptos_vault_api.py
```

#### Bước 2: Khởi động Frontend
```bash
cd frontend
npm install
npm run dev
```

## 🌐 Truy cập

- **Frontend UI**: http://localhost:5173
- **API Server**: http://localhost:5001
- **API Docs**: http://localhost:5001/api/vault/info

## 📊 API Endpoints

### Vault Operations
- `GET /api/vault/status` - Lấy trạng thái vault
- `GET /api/vault/balance/<address>` - Lấy balance của user
- `POST /api/vault/deposit` - Deposit USDT vào vault
- `POST /api/vault/withdraw` - Withdraw USDT từ vault
- `POST /api/vault/rebalance` - Rebalance vault (swap USDT ↔ APT)

### Example API Calls
```bash
# Get vault status
curl http://localhost:5001/api/vault/status

# Deposit USDT
curl -X POST http://localhost:5001/api/vault/deposit \
  -H "Content-Type: application/json" \
  -d '{"amount": 1000000, "user_address": "0x..."}'

# Rebalance vault
curl -X POST http://localhost:5001/api/vault/rebalance \
  -H "Content-Type: application/json" \
  -d '{"usdt_amount": 500000, "owner_address": "0x..."}'
```

## 🔧 Cấu hình

### Vault Address
- **Testnet**: `0xc8fa51ab7f319d232099afe32ebc9f57b898879dc724fb4f71b4d92f62ea0a77`
- **Mainnet**: `0xb380dc1036ffeed2f2fe06977a17275e4a71d9ca3a3df58b370aa7faba336c4d`

### Token Addresses
- **USDT**: `0xf22bede237a07e121b56d91a491eb7bcdfd1f5907926a9e58338f964a01b17fa`
- **APT**: `0x1`
- **PancakeSwap Router**: `0xc7efb4076dbe143cbcd98cfaaa929ecfc8f299405d018d7e18f75ac2b0e95f60`

## 📁 Cấu trúc dự án

```
ethdubai-2023-hackathon/
├── aptos-vault/                 # Smart contracts (Move)
│   ├── sources/
│   │   ├── vault.move          # Vault core logic
│   │   └── pancakeswap_adapter.move  # PancakeSwap integration
│   └── Move.toml
├── frontend/                    # SvelteKit UI
│   ├── src/routes/+page.svelte # Main UI
│   └── package.json
├── aptos_vault_api.py          # Flask API server
├── start_project.sh            # Auto-start script
└── README_APTOS_VAULT.md      # This file
```

## 🧪 Testing

### Test Smart Contract
```bash
cd aptos-vault
aptos move test
```

### Test API
```bash
# Test vault status
curl http://localhost:5001/api/vault/status

# Test deposit
curl -X POST http://localhost:5001/api/vault/deposit \
  -H "Content-Type: application/json" \
  -d '{"amount": 1000000, "user_address": "0x123..."}'
```

### Test Frontend
1. Mở http://localhost:5173
2. Nhập địa chỉ ví Aptos
3. Thử deposit/withdraw/rebalance

## 🔍 Debug

### API Server Logs
```bash
# Xem logs API server
tail -f aptos_vault_api.log
```

### Frontend Logs
```bash
# Xem logs frontend
cd frontend
npm run dev
```

### Smart Contract Logs
```bash
# Xem transaction logs
aptos move view --function-id <vault_address>::vault::get_vault_status
```

## 🚨 Troubleshooting

### Port 5001 đã được sử dụng
```bash
# Tìm process đang sử dụng port
lsof -i :5001
# Kill process
kill -9 <PID>
```

### Frontend không load
```bash
cd frontend
npm install
npm run dev
```

### API không kết nối được
```bash
# Kiểm tra API server
curl http://localhost:5001/api/vault/status
```

## 📈 Tính năng nâng cao

- [ ] **Automated Trading Bot**: Bot tự động rebalance
- [ ] **Performance Analytics**: Phân tích hiệu suất vault
- [ ] **Multi-token Support**: Hỗ trợ nhiều token
- [ ] **Governance**: DAO voting cho vault parameters
- [ ] **Insurance**: Bảo hiểm cho vault

## 🤝 Contributing

1. Fork dự án
2. Tạo feature branch
3. Commit changes
4. Push to branch
5. Tạo Pull Request

## 📄 License

MIT License - xem file LICENSE để biết thêm chi tiết.

---

**🎉 Chúc mừng! Bạn đã có một dự án DeFi vault hoàn chỉnh trên Aptos!** 