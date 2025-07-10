# Aptos Vault - USDT DeFi Vault

Vault DeFi trên Aptos blockchain sử dụng USDT làm denomination asset và tích hợp với PancakeSwap.

## 🚀 **Tính năng chính**

- ✅ **ERC4626 Equivalent**: Vault tương thích với chuẩn ERC4626
- ✅ **USDT Integration**: Sử dụng USDT trên Aptos Mainnet
- ✅ **PancakeSwap Integration**: Tích hợp với PancakeSwap để swap tokens
- ✅ **Compatibility Layer**: Tương thích với cấu trúc dự án EVM hiện tại
- ✅ **API Standardization**: Chuẩn hóa API endpoints cho UI và Trading Bot

## 📁 **Cấu trúc dự án**

```
aptos-vault/
├── sources/
│   ├── vault_core.move          # Core vault logic (ERC4626 equivalent)
│   ├── pancakeswap_adapter.move # PancakeSwap integration
│   ├── vault_tests.move         # Tests
│   └── deploy.move              # Deploy script
├── scripts/
│   ├── aptos_deploy.py          # Deploy script (tương thích với hackathon/deploy.py)
│   ├── aptos_deposit.py         # Deposit script (tương thích với hackathon/deposit.py)
│   └── aptos_rebalance.py       # Rebalance script (tương thích với hackathon/rebalance.py)
├── api/
│   └── aptos_vault_api.py       # API layer chuẩn hóa
├── aptos_conf.py                # Configuration (tương thích với hackathon/conf.py)
├── requirements.txt              # Python dependencies
└── README.md                    # This file
```

## 🔧 **Setup Environment**

### 1. **Install Aptos CLI**
```bash
curl -fsSL "https://aptos.dev/scripts/install_cli.py" | python3
```

### 2. **Install Python Dependencies**
```bash
pip install -r requirements.txt
```

### 3. **Setup Environment Variables**
```bash
export APTOS_PRIVATE_KEY="your_private_key_here"
export APTOS_MODULE_ADDRESS="your_module_address_after_deploy"
```

## 🚀 **Deploy Instructions**

### **Bước 1: Tạo tài khoản Aptos**
```bash
# Tạo tài khoản mới
aptos init --profile mainnet

# Hoặc import private key hiện có
aptos key import --profile mainnet
```

### **Bước 2: Compile và Deploy**
```bash
# Compile modules
aptos move compile

# Deploy modules
aptos move publish --named-addresses vault=<your-account-address>

# Set module address
export APTOS_MODULE_ADDRESS=<your-account-address>
```

### **Bước 3: Tạo Vault**
```bash
# Chạy deploy script
python scripts/aptos_deploy.py
```

### **Bước 4: Test Vault**
```bash
# Test deposit
python scripts/aptos_deposit.py

# Test rebalance
python scripts/aptos_rebalance.py
```

## 🔌 **API Integration**

### **Tương thích với UI hiện tại**

```python
from api.aptos_vault_api import AptosVaultAPI, AptosVaultConfig

# Setup API
config = AptosVaultConfig()
api = config.get_api()

# Get vault info (tương thích với EVM version)
vault_info = api.get_vault_info(0)

# Get user position
position = api.get_user_position(user_address, 0)

# Deposit
tx_hash = api.deposit(user_account, 0, amount)

# Withdraw
tx_hash = api.withdraw(user_account, 0, shares)
```

### **Tương thích với Trading Bot**

```python
# Rebalance vault
trades = [1, 2]  # Trade IDs
tx_hash = api.rebalance(fund_manager, 0, trades)

# Get quote
quote = api.get_quote(token_in, token_out, amount_in)

# Vault swap
tx_hash = api.vault_swap(vault_id, amount_in, amount_out_min, path)
```

## 🔄 **Migration từ EVM sang Aptos**

### **Thay đổi chính:**

1. **Token**: USDC → USDT
2. **Chain**: Polygon → Aptos
3. **DEX**: SushiSwap → PancakeSwap
4. **Language**: Solidity → Move

### **Tương thích API:**

| EVM Function | Aptos Equivalent | Status |
|--------------|------------------|---------|
| `vault.deposit()` | `api.deposit()` | ✅ |
| `vault.withdraw()` | `api.withdraw()` | ✅ |
| `vault.rebalance()` | `api.rebalance()` | ✅ |
| `sushi.getQuote()` | `api.get_quote()` | ✅ |
| `vault.getInfo()` | `api.get_vault_info()` | ✅ |

## 📊 **Configuration**

### **Environment Variables**
```bash
APTOS_PRIVATE_KEY=your_private_key
APTOS_MODULE_ADDRESS=your_module_address
APTOS_NODE_URL=https://fullnode.mainnet.aptoslabs.com
```

### **Vault Configuration**
```python
# aptos_conf.py
USDT_ADDRESS = "0xf22bede237a07e121b56d91a491eb7bcdfd1f5907926a9e58338f964a01b17fa"
FEE_RATE = 100  # 1%
MIN_DEPOSIT_AMOUNT = 1000000  # 1 USDT
```

## 🧪 **Testing**

### **Run Tests**
```bash
# Compile tests
aptos move compile

# Run tests
aptos move test
```

### **Test Scripts**
```bash
# Test deposit
python scripts/aptos_deposit.py

# Test rebalance
python scripts/aptos_rebalance.py

# Test full deployment
python scripts/aptos_deploy.py
```

## 🔗 **Integration với Frontend**

### **Update Frontend Configuration**
```javascript
// Thay đổi từ EVM sang Aptos
const APTOS_CONFIG = {
  nodeUrl: "https://fullnode.mainnet.aptoslabs.com",
  moduleAddress: "your_module_address",
  vaultId: 0
};
```

### **Update API Calls**
```javascript
// Thay đổi từ Web3 sang Aptos SDK
import { AptosClient, Account } from "aptos";

const client = new AptosClient(APTOS_CONFIG.nodeUrl);
const account = Account.loadKey(privateKey);
```

## 🚨 **Lưu ý quan trọng**

1. **Private Key Security**: Không commit private key vào git
2. **Testnet First**: Test trên testnet trước khi deploy mainnet
3. **Gas Fees**: Aptos sử dụng gas fees khác với EVM
4. **Token Decimals**: USDT trên Aptos có 6 decimals

## 📞 **Support**

- **Documentation**: [Aptos Move](https://aptos.dev/move/)
- **SDK**: [Aptos Python SDK](https://github.com/aptos-labs/aptos-core/tree/main/ecosystem/python/sdk)
- **Examples**: [Aptos Examples](https://github.com/aptos-labs/aptos-core/tree/main/ecosystem/python/sdk/examples)

## 🎯 **Next Steps**

1. ✅ Deploy lên Aptos Mainnet
2. ✅ Test với USDT thực
3. ✅ Tích hợp với PancakeSwap thực
4. 🔄 Update UI để support Aptos
5. 🔄 Update Trading Bot để support Aptos
6. 🔄 Add more advanced features

---

**Vault đã sẵn sàng để deploy lên Aptos Mainnet! 🚀** 