#!/usr/bin/env python3
"""
Improved APT to USDT Swap Script for Dexonic Asset Vault
Enhanced with security features, proper error handling, and comprehensive validation
"""

import asyncio
import logging
import time
from decimal import Decimal, ROUND_DOWN
from typing import Optional, Tuple, Dict, Any
from dataclasses import dataclass

from aptos_sdk.account import Account
from aptos_sdk.client import RestClient
from aptos_sdk.transactions import TransactionArgument, TransactionPayload
from aptos_sdk.type_tag import TypeTag, StructTag

# Configure logging with different levels
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('vault_swap.log'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

@dataclass
class SwapConfig:
    """Configuration for swap operations"""
    vault_address: str = "0xf9bf1298a04a1fe13ed75059e9e6950ec1ec2d6ed95f8a04a6e11af23c87381e"
    pancakeswap_router: str = "0xc7efb4076dbe143cbcd98cfaaa929ecfc8f299405d018d7e18f75ac2b0e95f60"
    usdt_address: str = "0xf22bede237a07e121b56d91a491eb7bcdfd1f5907926a9e58338f964a01b17fa"
    apt_address: str = "0x1"
    
    # Security parameters
    max_slippage: float = 0.05  # 5%
    min_amount: int = 100000  # 0.1 APT
    max_amount: int = 1000000000  # 1000 APT
    cooldown_period: int = 3600  # 1 hour
    max_retries: int = 3
    retry_delay: float = 2.0
    
    # Network configuration
    node_url: str = "https://fullnode.mainnet.aptoslabs.com"
    gas_unit_price: int = 100
    max_gas_amount: int = 200000

class VaultSwapClient:
    """Enhanced client for vault swap operations with comprehensive security features"""
    
    def __init__(self, private_key: str, config: SwapConfig = None):
        self.config = config or SwapConfig()
        self.account = Account.load_key(private_key)
        self.client = RestClient(self.config.node_url)
        
        # Initialize security state
        self.last_swap_time = 0
        self.swap_count = 0
        self.total_volume = 0
        
        logger.info(f"Initialized VaultSwapClient for account: {self.account.address()}")
    
    async def check_network_status(self) -> bool:
        """Check if the network is healthy"""
        try:
            ledger_info = await self.client.ledger_info()
            logger.info(f"Network height: {ledger_info['block_height']}")
            return True
        except Exception as e:
            logger.error(f"Network check failed: {e}")
            return False
    
    async def get_account_balance(self, token_address: str = None) -> Dict[str, int]:
        """Get account balances with comprehensive error handling"""
        try:
            if token_address is None:
                token_address = self.config.apt_address
            
            resources = await self.client.account_resources(self.account.address())
            balances = {}
            
            for resource in resources:
                if resource["type"] == "0x1::coin::CoinStore<0x1::aptos_coin::AptosCoin>":
                    balances["APT"] = int(resource["data"]["coin"]["value"])
                elif "0x1::coin::CoinStore<" in resource["type"] and token_address in resource["type"]:
                    balances["USDT"] = int(resource["data"]["coin"]["value"])
            
            logger.info(f"Account balances: {balances}")
            return balances
        except Exception as e:
            logger.error(f"Failed to get account balance: {e}")
            return {}
    
    async def validate_swap_parameters(self, apt_amount: int) -> Tuple[bool, str]:
        """Comprehensive validation of swap parameters"""
        try:
            # Check amount limits
            if apt_amount < self.config.min_amount:
                return False, f"Amount too small: {apt_amount} < {self.config.min_amount}"
            
            if apt_amount > self.config.max_amount:
                return False, f"Amount too large: {apt_amount} > {self.config.max_amount}"
            
            # Check cooldown
            current_time = int(time.time())
            if current_time - self.last_swap_time < self.config.cooldown_period:
                remaining = self.config.cooldown_period - (current_time - self.last_swap_time)
                return False, f"Cooldown active: {remaining}s remaining"
            
            # Check account balance
            balances = await self.get_account_balance()
            if "APT" not in balances or balances["APT"] < apt_amount:
                return False, f"Insufficient APT balance: {balances.get('APT', 0)} < {apt_amount}"
            
            # Check network status
            if not await self.check_network_status():
                return False, "Network is unhealthy"
            
            return True, "Validation passed"
        except Exception as e:
            logger.error(f"Validation error: {e}")
            return False, f"Validation error: {e}"
    
    async def get_swap_quote(self, apt_amount: int) -> Tuple[Optional[int], float]:
        """Get swap quote with price impact calculation"""
        try:
            # In a real implementation, this would call PancakeSwap's getAmountsOut
            # For demo purposes, we'll use a simple 1:1 ratio
            expected_usdt = apt_amount
            
            # Calculate price impact (simplified)
            price_impact = 0.0  # Would be calculated from actual pool reserves
            
            logger.info(f"Quote: {apt_amount} APT -> {expected_usdt} USDT (impact: {price_impact:.2%})")
            return expected_usdt, price_impact
        except Exception as e:
            logger.error(f"Failed to get quote: {e}")
            return None, 0.0
    
    async def calculate_slippage(self, expected_amount: int, actual_amount: int) -> float:
        """Calculate slippage percentage"""
        if expected_amount == 0:
            return 0.0
        return max(0.0, (expected_amount - actual_amount) / expected_amount)
    
    async def execute_swap_with_fallback(self, apt_amount: int) -> Tuple[bool, str, Dict[str, Any]]:
        """Execute swap with comprehensive fallback strategy"""
        try:
            # Validate parameters
            is_valid, error_msg = await self.validate_swap_parameters(apt_amount)
            if not is_valid:
                return False, error_msg, {}
            
            # Get quote
            expected_usdt, price_impact = await self.get_swap_quote(apt_amount)
            if expected_usdt is None:
                return False, "Failed to get quote", {}
            
            # Check price impact
            if price_impact > self.config.max_slippage:
                return False, f"Price impact too high: {price_impact:.2%} > {self.config.max_slippage:.2%}", {}
            
            # Calculate minimum output with slippage protection
            min_output = int(expected_usdt * (1 - self.config.max_slippage))
            
            logger.info(f"Executing swap: {apt_amount} APT -> min {min_output} USDT")
            
            # Try vault swap first
            success, tx_hash, result = await self._execute_vault_swap(apt_amount, min_output)
            if success:
                return True, "Vault swap successful", {"tx_hash": tx_hash, "method": "vault", **result}
            
            # Fallback to direct PancakeSwap
            logger.warning("Vault swap failed, trying direct PancakeSwap")
            success, tx_hash, result = await self._execute_direct_swap(apt_amount, min_output)
            if success:
                return True, "Direct swap successful", {"tx_hash": tx_hash, "method": "direct", **result}
            
            return False, "All swap methods failed", {}
            
        except Exception as e:
            logger.error(f"Swap execution error: {e}")
            return False, f"Swap execution error: {e}", {}
    
    async def _execute_vault_swap(self, apt_amount: int, min_usdt: int) -> Tuple[bool, Optional[str], Dict[str, Any]]:
        """Execute swap through vault contract"""
        try:
            payload = {
                "function": f"{self.config.vault_address}::pancakeswap_adapter::swap_apt_for_usdt",
                "type_arguments": [],
                "arguments": [str(apt_amount), str(min_usdt)]
            }
            
            tx_hash = await self.client.submit_transaction(self.account, TransactionPayload(**payload))
            await self.client.wait_for_transaction(tx_hash)
            
            # Update security state
            self.last_swap_time = int(time.time())
            self.swap_count += 1
            self.total_volume += apt_amount
            
            logger.info(f"Vault swap successful: {tx_hash}")
            return True, tx_hash, {"input_amount": apt_amount, "min_output": min_usdt}
            
        except Exception as e:
            logger.error(f"Vault swap failed: {e}")
            return False, None, {"error": str(e)}
    
    async def _execute_direct_swap(self, apt_amount: int, min_usdt: int) -> Tuple[bool, Optional[str], Dict[str, Any]]:
        """Execute swap directly through PancakeSwap"""
        try:
            # Create swap path
            path = [self.config.apt_address, self.config.usdt_address]
            
            payload = {
                "function": f"{self.config.pancakeswap_router}::router::swap_exact_input",
                "type_arguments": [],
                "arguments": [
                    str(apt_amount),
                    str(min_usdt),
                    path,
                    self.account.address(),
                    str(int(time.time()) + 3600)  # 1 hour deadline
                ]
            }
            
            tx_hash = await self.client.submit_transaction(self.account, TransactionPayload(**payload))
            await self.client.wait_for_transaction(tx_hash)
            
            # Update security state
            self.last_swap_time = int(time.time())
            self.swap_count += 1
            self.total_volume += apt_amount
            
            logger.info(f"Direct swap successful: {tx_hash}")
            return True, tx_hash, {"input_amount": apt_amount, "min_output": min_usdt}
            
        except Exception as e:
            logger.error(f"Direct swap failed: {e}")
            return False, None, {"error": str(e)}
    
    async def get_vault_status(self) -> Dict[str, Any]:
        """Get comprehensive vault status"""
        try:
            # Get vault info
            vault_info = await self.client.view(
                self.config.vault_address,
                "vault::vault::get_vault_status",
                []
            )
            
            # Get integration status
            integration_info = await self.client.view(
                self.config.vault_address,
                "vault::vault_integration::get_integration_status",
                [self.config.vault_address]
            )
            
            return {
                "vault_info": vault_info,
                "integration_info": integration_info,
                "swap_stats": {
                    "swap_count": self.swap_count,
                    "total_volume": self.total_volume,
                    "last_swap_time": self.last_swap_time
                }
            }
        except Exception as e:
            logger.error(f"Failed to get vault status: {e}")
            return {}
    
    async def monitor_swap(self, tx_hash: str, timeout: int = 300) -> Dict[str, Any]:
        """Monitor swap transaction with detailed status"""
        try:
            start_time = time.time()
            while time.time() - start_time < timeout:
                try:
                    tx_info = await self.client.transaction_by_hash(tx_hash)
                    
                    if tx_info["success"]:
                        logger.info(f"Transaction successful: {tx_hash}")
                        return {
                            "status": "success",
                            "tx_hash": tx_hash,
                            "gas_used": tx_info.get("gas_used", 0),
                            "timestamp": tx_info.get("timestamp", 0)
                        }
                    else:
                        logger.error(f"Transaction failed: {tx_hash}")
                        return {
                            "status": "failed",
                            "tx_hash": tx_hash,
                            "error": tx_info.get("vm_status", "Unknown error")
                        }
                        
                except Exception as e:
                    logger.debug(f"Transaction not yet confirmed: {e}")
                    await asyncio.sleep(2)
            
            return {"status": "timeout", "tx_hash": tx_hash}
            
        except Exception as e:
            logger.error(f"Monitor error: {e}")
            return {"status": "error", "error": str(e)}

async def main():
    """Main function with comprehensive error handling and logging"""
    # Configuration
    PRIVATE_KEY = "your_private_key_here"  # Replace with actual private key
    APT_AMOUNT = 100000  # 0.1 APT
    
    # Initialize client
    config = SwapConfig()
    client = VaultSwapClient(PRIVATE_KEY, config)
    
    try:
        logger.info("=== Dexonic Asset Vault Swap Client ===")
        logger.info(f"Target amount: {APT_AMOUNT} APT")
        
        # Check initial balances
        balances = await client.get_account_balance()
        logger.info(f"Initial balances: {balances}")
        
        # Get vault status
        vault_status = await client.get_vault_status()
        logger.info(f"Vault status: {vault_status}")
        
        # Execute swap with retries
        for attempt in range(config.max_retries):
            logger.info(f"Swap attempt {attempt + 1}/{config.max_retries}")
            
            success, message, result = await client.execute_swap_with_fallback(APT_AMOUNT)
            
            if success:
                logger.info(f"Swap successful: {message}")
                logger.info(f"Result: {result}")
                
                # Monitor transaction
                if "tx_hash" in result:
                    monitor_result = await client.monitor_swap(result["tx_hash"])
                    logger.info(f"Transaction monitoring: {monitor_result}")
                
                break
            else:
                logger.warning(f"Swap failed (attempt {attempt + 1}): {message}")
                if attempt < config.max_retries - 1:
                    logger.info(f"Retrying in {config.retry_delay} seconds...")
                    await asyncio.sleep(config.retry_delay)
                else:
                    logger.error("All swap attempts failed")
        
        # Final balance check
        final_balances = await client.get_account_balance()
        logger.info(f"Final balances: {final_balances}")
        
    except Exception as e:
        logger.error(f"Main execution error: {e}")
        raise

if __name__ == "__main__":
    asyncio.run(main()) 