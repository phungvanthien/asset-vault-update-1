# Dexonic Asset Vault - Improved Swap Implementation

## Overview

This repository contains an improved implementation of the Dexonic Asset Vault with enhanced security features, comprehensive error handling, and proper smart contract fixes.

## Key Improvements

### 1. Smart Contract Fixes

#### PancakeSwap Adapter (`pancakeswap_adapter.move`)
- ✅ **Complete swap functions**: Added `swap_exact_tokens_for_tokens`, `swap_apt_for_usdt`, `swap_usdt_for_apt`
- ✅ **Token approval system**: Added `TokenApproval` struct and approval functions
- ✅ **Event handling**: Proper event emission for swap operations
- ✅ **Router storage**: Complete `RouterStorage` with statistics tracking
- ✅ **Slippage protection**: Built-in slippage calculation and validation
- ✅ **Error handling**: Comprehensive error codes and validation

#### Vault Core Simple (`vault_core_simple.move`)
- ✅ **Complete mint/redeem functions**: Full ERC4626 implementation
- ✅ **AssetPool struct**: Proper asset tracking and management
- ✅ **Share calculation**: Accurate share minting/burning with proper arithmetic
- ✅ **Event emission**: Deposit, withdraw, and rebalance events
- ✅ **Access control**: Manager-only functions with proper validation

#### Vault Integration (`vault_integration.move`)
- ✅ **Complete integration functions**: Full rebalancing orchestration
- ✅ **Cooldown enforcement**: Proper cooldown period validation
- ✅ **Slippage checks**: Price impact and slippage protection
- ✅ **Access control**: Manager-only rebalancing with proper validation
- ✅ **Event emission**: Rebalance events with detailed information

#### Main Vault (`vault.move`)
- ✅ **Complete vault functions**: Deposit, withdraw, redeem, rebalance
- ✅ **Proper address handling**: Fixed `@vault` vs owner address issues
- ✅ **Checked arithmetic**: Safe math operations to prevent underflow
- ✅ **Event emission**: All vault operations emit proper events
- ✅ **Access control**: Owner-only functions with proper validation

#### Test Suite (`vault_tests.move`)
- ✅ **Comprehensive tests**: 51 test cases covering all functionality
- ✅ **Fixed syntax errors**: Proper semicolons and address constants
- ✅ **Edge case testing**: Zero amounts, insufficient balances, access control
- ✅ **Integration testing**: Cross-module function testing

### 2. Python Client Improvements

#### Security Features
- 🔒 **Amount limits**: Min/max amount validation
- 🔒 **Cooldown periods**: Prevents rapid successive swaps
- 🔒 **Slippage protection**: Configurable max slippage (5% default)
- 🔒 **Network health checks**: Validates network status before operations
- 🔒 **Balance validation**: Ensures sufficient funds before swap

#### Error Handling
- 🛡️ **Comprehensive validation**: Parameter validation with detailed error messages
- 🛡️ **Retry mechanism**: Automatic retry with exponential backoff
- 🛡️ **Fallback strategy**: Vault swap → Direct PancakeSwap fallback
- 🛡️ **Transaction monitoring**: Real-time transaction status tracking
- 🛡️ **Detailed logging**: Multi-level logging with file and console output

#### Performance Features
- ⚡ **Async operations**: Non-blocking API calls
- ⚡ **Connection pooling**: Efficient network resource usage
- ⚡ **Caching**: Balance and status caching
- ⚡ **Batch operations**: Efficient multiple operation handling

## Installation

### Prerequisites
- Python 3.8+
- Aptos CLI
- Node.js (for frontend)

### Setup

1. **Clone the repository**
```bash
git clone https://github.com/your-username/Dexonic_Asset_Vault.git
cd Dexonic_Asset_Vault
```

2. **Install Python dependencies**
```bash
pip install -r requirements.txt
```

3. **Install Aptos CLI**
```bash
curl -fsSL "https://aptos.dev/scripts/install_cli.py" | python3
```

4. **Configure environment**
```bash
cp .env.example .env
# Edit .env with your configuration
```

## Usage

### Smart Contract Deployment

1. **Deploy contracts**
```bash
cd aptos-vault
aptos move compile
aptos move publish --named-addresses vault=0xf9bf1298a04a1fe13ed75059e9e6950ec1ec2d6ed95f8a04a6e11af23c87381e
```

2. **Initialize vault**
```bash
aptos move run --function-id '0xf9bf1298a04a1fe13ed75059e9e6950ec1ec2d6ed95f8a04a6e11af23c87381e::vault::initialize_vault'
```

### Python Client Usage

1. **Basic swap**
```python
from apt_usdt_swap_improved import VaultSwapClient, SwapConfig

# Initialize client
config = SwapConfig()
client = VaultSwapClient("your_private_key", config)

# Execute swap
success, message, result = await client.execute_swap_with_fallback(100000)  # 0.1 APT
```

2. **Advanced configuration**
```python
config = SwapConfig(
    max_slippage=0.03,  # 3% max slippage
    min_amount=50000,   # 0.05 APT minimum
    max_amount=500000,  # 0.5 APT maximum
    cooldown_period=1800,  # 30 minutes
    max_retries=5
)
```

3. **Monitor vault status**
```python
status = await client.get_vault_status()
print(f"Vault info: {status['vault_info']}")
print(f"Integration info: {status['integration_info']}")
print(f"Swap stats: {status['swap_stats']}")
```

### Configuration Options

#### SwapConfig Parameters
- `max_slippage`: Maximum allowed slippage (default: 5%)
- `min_amount`: Minimum swap amount in base units (default: 0.1 APT)
- `max_amount`: Maximum swap amount in base units (default: 1000 APT)
- `cooldown_period`: Time between swaps in seconds (default: 1 hour)
- `max_retries`: Maximum retry attempts (default: 3)
- `retry_delay`: Delay between retries in seconds (default: 2.0)

#### Security Features
- **Amount validation**: Prevents dust attacks and excessive trades
- **Cooldown enforcement**: Prevents rapid successive operations
- **Slippage protection**: Protects against MEV and price manipulation
- **Network validation**: Ensures network health before operations
- **Balance checks**: Validates sufficient funds before execution

## Testing

### Smart Contract Tests
```bash
cd aptos-vault
aptos move test
```

### Python Client Tests
```bash
python -m pytest tests/ -v
```

### Integration Tests
```bash
python test_integration.py
```

## Security Considerations

### Smart Contract Security
- ✅ **Access control**: Owner-only functions properly protected
- ✅ **Reentrancy protection**: Safe external calls
- ✅ **Integer overflow**: Checked arithmetic operations
- ✅ **Input validation**: Comprehensive parameter validation
- ✅ **Event emission**: All state changes properly logged

### Python Client Security
- 🔒 **Private key protection**: Never log or expose private keys
- 🔒 **Amount limits**: Prevents excessive trades
- 🔒 **Cooldown periods**: Prevents rapid successive operations
- 🔒 **Slippage protection**: Protects against price manipulation
- 🔒 **Network validation**: Ensures network health

## Monitoring and Logging

### Log Levels
- `DEBUG`: Detailed debugging information
- `INFO`: General operational information
- `WARNING`: Warning messages for potential issues
- `ERROR`: Error messages for failed operations
- `CRITICAL`: Critical errors requiring immediate attention

### Log Files
- `vault_swap.log`: Main application log
- `error.log`: Error-specific log
- `transaction.log`: Transaction-specific log

## Error Handling

### Common Errors and Solutions

1. **Insufficient Balance**
   - Check account balance before swap
   - Ensure sufficient APT for gas fees

2. **Network Issues**
   - Verify network connectivity
   - Check node URL configuration

3. **Slippage Exceeded**
   - Reduce swap amount
   - Increase max slippage tolerance
   - Wait for better market conditions

4. **Cooldown Active**
   - Wait for cooldown period to expire
   - Check last swap timestamp

5. **Transaction Failed**
   - Check gas fees
   - Verify transaction parameters
   - Retry with different parameters

## Performance Optimization

### Best Practices
1. **Use appropriate gas settings**
2. **Monitor network congestion**
3. **Implement proper retry logic**
4. **Cache frequently accessed data**
5. **Use async operations for I/O**

### Monitoring
- Track swap success rates
- Monitor gas usage
- Log performance metrics
- Alert on failures

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For support and questions:
- Create an issue on GitHub
- Check the documentation
- Review the test cases
- Consult the security guidelines 