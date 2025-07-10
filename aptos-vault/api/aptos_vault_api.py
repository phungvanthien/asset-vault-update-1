"""
Aptos Vault API Layer
=====================

Chuẩn hóa API endpoints để kết nối Aptos vault với UI và Trading Bot hiện tại.
Tương thích với cấu trúc dự án EVM hiện tại.
"""

import os
import json
import logging
from typing import Dict, List, Optional, Tuple, Any
from dataclasses import dataclass
from decimal import Decimal

from aptos_sdk.client import RestClient
from aptos_sdk.account import Account
from aptos_sdk.transactions import TransactionArgument, TransactionPayload
from aptos_sdk.type_tag import TypeTag, StructTag

logger = logging.getLogger(__name__)


@dataclass
class VaultInfo:
    """Thông tin vault tương thích với EVM version"""
    vault_id: int
    total_shares: int
    total_assets: int
    denomination_asset: str
    fund_manager: str
    fee_rate: int
    is_active: bool
    vault_address: str


@dataclass
class UserPosition:
    """Thông tin position của user"""
    user_address: str
    vault_id: int
    shares: int
    assets: int
    share_price: Decimal


@dataclass
class TradeInfo:
    """Thông tin trade"""
    token_in: str
    token_out: str
    amount_in: int
    amount_out: int
    path: List[str]
    timestamp: int


class AptosVaultAPI:
    """
    API Layer cho Aptos Vault
    Tương thích với cấu trúc dự án EVM hiện tại
    """
    
    def __init__(self, node_url: str = "https://fullnode.mainnet.aptoslabs.com"):
        self.client = RestClient(node_url)
        self.module_address = None
        self.vault_registry_address = None
        
    def set_module_address(self, address: str):
        """Set module address sau khi deploy"""
        self.module_address = address
        self.vault_registry_address = address
        
    def get_vault_info(self, vault_id: int) -> VaultInfo:
        """
        Lấy thông tin vault (tương thích với EVM version)
        """
        try:
            # Gọi view function từ vault_core
            result = self.client.view(
                self.module_address,
                "vault_core",
                "get_vault_info",
                [vault_id]
            )
            
            # Parse result
            total_shares, total_assets, vault_id, denomination_asset, fund_manager, fee_rate, is_active = result
            
            return VaultInfo(
                vault_id=vault_id,
                total_shares=total_shares,
                total_assets=total_assets,
                denomination_asset=denomination_asset,
                fund_manager=fund_manager,
                fee_rate=fee_rate,
                is_active=is_active,
                vault_address=self.module_address  # Aptos không có vault address riêng
            )
        except Exception as e:
            logger.error(f"Error getting vault info: {e}")
            raise
            
    def get_user_position(self, user_address: str, vault_id: int) -> UserPosition:
        """
        Lấy thông tin position của user
        """
        try:
            # Gọi balance_of function
            shares = self.client.view(
                self.module_address,
                "vault_core", 
                "balance_of",
                [user_address, vault_id]
            )
            
            # Tính assets từ shares
            assets = self.client.view(
                self.module_address,
                "vault_core",
                "convert_to_assets", 
                [vault_id, shares]
            )
            
            # Tính share price
            total_shares = self.client.view(
                self.module_address,
                "vault_core",
                "total_shares",
                [vault_id]
            )
            
            total_assets = self.client.view(
                self.module_address,
                "vault_core", 
                "total_assets",
                [vault_id]
            )
            
            share_price = Decimal(total_assets) / Decimal(total_shares) if total_shares > 0 else Decimal(0)
            
            return UserPosition(
                user_address=user_address,
                vault_id=vault_id,
                shares=shares,
                assets=assets,
                share_price=share_price
            )
        except Exception as e:
            logger.error(f"Error getting user position: {e}")
            raise
            
    def deposit(self, user_account: Account, vault_id: int, amount: int) -> str:
        """
        Deposit vào vault (tương thích với EVM version)
        """
        try:
            # Tạo transaction payload
            payload = TransactionPayload(
                function=f"{self.module_address}::vault_core::deposit",
                type_arguments=[f"{self.module_address}::coin::USDT"],
                arguments=[
                    vault_id,
                    amount
                ]
            )
            
            # Submit transaction
            tx_hash = self.client.submit_transaction(user_account, payload)
            self.client.wait_for_transaction(tx_hash)
            
            logger.info(f"Deposit successful: {tx_hash}")
            return tx_hash
            
        except Exception as e:
            logger.error(f"Error depositing: {e}")
            raise
            
    def withdraw(self, user_account: Account, vault_id: int, shares: int) -> str:
        """
        Withdraw từ vault (tương thích với EVM version)
        """
        try:
            # Tạo transaction payload
            payload = TransactionPayload(
                function=f"{self.module_address}::vault_core::withdraw",
                type_arguments=[f"{self.module_address}::coin::USDT"],
                arguments=[
                    vault_id,
                    shares
                ]
            )
            
            # Submit transaction
            tx_hash = self.client.submit_transaction(user_account, payload)
            self.client.wait_for_transaction(tx_hash)
            
            logger.info(f"Withdraw successful: {tx_hash}")
            return tx_hash
            
        except Exception as e:
            logger.error(f"Error withdrawing: {e}")
            raise
            
    def create_vault(self, vault_manager: Account, fund_manager: str, fee_rate: int = 100) -> int:
        """
        Tạo vault mới (tương thích với EVM version)
        """
        try:
            # Lấy USDT address
            usdt_address = self.client.view(
                self.module_address,
                "vault_core",
                "get_usdt_address",
                []
            )
            
            # Tạo transaction payload
            payload = TransactionPayload(
                function=f"{self.module_address}::vault_core::create_vault",
                type_arguments=[],
                arguments=[
                    usdt_address,
                    fund_manager,
                    fee_rate
                ]
            )
            
            # Submit transaction
            tx_hash = self.client.submit_transaction(vault_manager, payload)
            self.client.wait_for_transaction(tx_hash)
            
            # Lấy vault ID mới
            registry = self.client.view(
                self.module_address,
                "vault_core",
                "get_vault_info",
                [0]  # Vault đầu tiên
            )
            
            vault_id = registry[2]  # vault_id là index 2
            
            logger.info(f"Vault created successfully: {vault_id}")
            return vault_id
            
        except Exception as e:
            logger.error(f"Error creating vault: {e}")
            raise
            
    def rebalance(self, fund_manager: Account, vault_id: int, trades: List[int]) -> str:
        """
        Rebalance vault (tương thích với EVM version)
        """
        try:
            # Tạo transaction payload
            payload = TransactionPayload(
                function=f"{self.module_address}::vault_core::rebalance",
                type_arguments=[],
                arguments=[
                    vault_id,
                    trades
                ]
            )
            
            # Submit transaction
            tx_hash = self.client.submit_transaction(fund_manager, payload)
            self.client.wait_for_transaction(tx_hash)
            
            logger.info(f"Rebalance successful: {tx_hash}")
            return tx_hash
            
        except Exception as e:
            logger.error(f"Error rebalancing: {e}")
            raise
            
    def get_quote(self, token_in: str, token_out: str, amount_in: int) -> int:
        """
        Lấy quote cho swap (tương thích với PancakeSwap)
        """
        try:
            # Tạo path
            path = [token_in, token_out]
            
            # Tạo router
            router_address = self.client.view(
                self.module_address,
                "pancakeswap_adapter",
                "get_pancakeswap_router_address",
                []
            )
            
            # Gọi get_quote
            quote = self.client.view(
                self.module_address,
                "pancakeswap_adapter",
                "get_quote",
                [router_address, amount_in, path]
            )
            
            return quote
            
        except Exception as e:
            logger.error(f"Error getting quote: {e}")
            raise
            
    def vault_swap(self, vault_id: int, amount_in: int, amount_out_min: int, path: List[str]) -> str:
        """
        Swap trong vault (tương thích với EVM version)
        """
        try:
            # Tạo transaction payload
            payload = TransactionPayload(
                function=f"{self.module_address}::pancakeswap_adapter::vault_swap",
                type_arguments=[f"{self.module_address}::coin::USDT", f"{self.module_address}::coin::AptosCoin"],
                arguments=[
                    vault_id,
                    amount_in,
                    amount_out_min,
                    path,
                    int(time.time()) + 3600  # 1 hour deadline
                ]
            )
            
            # Submit transaction
            tx_hash = self.client.submit_transaction(user_account, payload)
            self.client.wait_for_transaction(tx_hash)
            
            logger.info(f"Vault swap successful: {tx_hash}")
            return tx_hash
            
        except Exception as e:
            logger.error(f"Error vault swap: {e}")
            raise
    
    # ===== COMPTROLLER FUNCTIONS =====
    
    def create_comptroller(self, vault_owner: Account, vault_id: int, fund_manager: str) -> int:
        """Create comptroller for a vault"""
        try:
            payload = TransactionPayload(
                function=f"{self.module_address}::vault_comptroller::create_comptroller",
                type_arguments=[],
                arguments=[
                    str(vault_id),
                    fund_manager
                ]
            )
            
            txn_hash = self.client.submit_transaction(vault_owner, payload)
            self.client.wait_for_transaction(txn_hash)
            
            # Get comptroller ID from events
            comptroller_id = self._get_comptroller_id_from_events(txn_hash)
            return comptroller_id
            
        except Exception as e:
            logger.error(f"Error creating comptroller: {e}")
            raise
    
    def execute_trade(self, fund_manager: Account, comptroller_id: int, trade_data: dict) -> bool:
        """Execute trade through comptroller"""
        try:
            payload = TransactionPayload(
                function=f"{self.module_address}::vault_comptroller::execute_trade",
                type_arguments=[],
                arguments=[
                    str(comptroller_id),
                    trade_data
                ]
            )
            
            txn_hash = self.client.submit_transaction(fund_manager, payload)
            self.client.wait_for_transaction(txn_hash)
            return True
            
        except Exception as e:
            logger.error(f"Error executing trade: {e}")
            raise
    
    def execute_rebalance(self, fund_manager: Account, comptroller_id: int, trades: list) -> bool:
        """Execute rebalance through comptroller"""
        try:
            payload = TransactionPayload(
                function=f"{self.module_address}::vault_comptroller::execute_rebalance",
                type_arguments=[],
                arguments=[
                    str(comptroller_id),
                    trades
                ]
            )
            
            txn_hash = self.client.submit_transaction(fund_manager, payload)
            self.client.wait_for_transaction(txn_hash)
            return True
            
        except Exception as e:
            logger.error(f"Error executing rebalance: {e}")
            raise
    
    def buy_shares(self, user: Account, comptroller_id: int, amount: int, min_shares: int) -> bool:
        """Buy shares through comptroller"""
        try:
            payload = TransactionPayload(
                function=f"{self.module_address}::vault_comptroller::buy_shares",
                type_arguments=[],
                arguments=[
                    str(comptroller_id),
                    str(amount),
                    str(min_shares)
                ]
            )
            
            txn_hash = self.client.submit_transaction(user, payload)
            self.client.wait_for_transaction(txn_hash)
            return True
            
        except Exception as e:
            logger.error(f"Error buying shares: {e}")
            raise
    
    def sell_shares(self, user: Account, comptroller_id: int, shares: int, min_amount: int) -> bool:
        """Sell shares through comptroller"""
        try:
            payload = TransactionPayload(
                function=f"{self.module_address}::vault_comptroller::sell_shares",
                type_arguments=[],
                arguments=[
                    str(comptroller_id),
                    str(shares),
                    str(min_amount)
                ]
            )
            
            txn_hash = self.client.submit_transaction(user, payload)
            self.client.wait_for_transaction(txn_hash)
            return True
            
        except Exception as e:
            logger.error(f"Error selling shares: {e}")
            raise
    
    def get_comptroller_info(self, comptroller_id: int) -> dict:
        """Get comptroller information"""
        try:
            result = self.client.view(
                self.module_address,
                "vault_comptroller",
                "get_comptroller_info",
                [str(comptroller_id)]
            )
            
            return {
                "id": result[0],
                "vault_id": result[1],
                "fund_manager": result[2],
                "vault_owner": result[3],
                "is_active": result[4],
                "total_trades": result[5],
                "total_volume": result[6]
            }
            
        except Exception as e:
            logger.error(f"Error getting comptroller info: {e}")
            raise
    
    def _get_comptroller_id_from_events(self, txn_hash: str) -> int:
        """Extract comptroller ID from transaction events"""
        try:
            txn = self.client.get_transaction(txn_hash)
            # Parse events to find comptroller creation
            # This is a simplified implementation
            return 0  # Default to first comptroller
        except Exception as e:
            logger.error(f"Error parsing comptroller events: {e}")
            return 0


# ===== COMPATIBILITY LAYER =====

class AptosVaultCompatibility:
    """
    Compatibility layer để tương thích với cấu trúc dự án EVM hiện tại
    """
    
    def __init__(self, api: AptosVaultAPI):
        self.api = api
        
    def get_vault_address(self) -> str:
        """Tương thích với EVM vault address"""
        return self.api.module_address
        
    def get_comptroller_address(self) -> str:
        """Tương thích với EVM comptroller address"""
        return self.api.module_address
        
    def get_usdt_address(self) -> str:
        """Tương thích với EVM USDC address"""
        return self.api.client.view(
            self.api.module_address,
            "vault_core",
            "get_usdt_address",
            []
        )
        
    def get_user_balance(self, user_address: str) -> int:
        """Tương thích với EVM balance check"""
        # Trong Aptos, balance được check trực tiếp từ coin module
        # Đây là placeholder cho compatibility
        return 0
        
    def approve_tokens(self, user_account: Account, spender: str, amount: int) -> str:
        """Tương thích với EVM approve"""
        # Trong Aptos, approval được handle tự động
        # Đây là placeholder cho compatibility
        return "0x0000000000000000000000000000000000000000000000000000000000000000"


# ===== CONFIGURATION =====

class AptosVaultConfig:
    """Configuration cho Aptos Vault"""
    
    def __init__(self):
        self.node_url = os.getenv("APTOS_NODE_URL", "https://fullnode.mainnet.aptoslabs.com")
        self.module_address = os.getenv("APTOS_MODULE_ADDRESS")
        self.private_key = os.getenv("APTOS_PRIVATE_KEY")
        
    def get_api(self) -> AptosVaultAPI:
        """Tạo API instance"""
        api = AptosVaultAPI(self.node_url)
        if self.module_address:
            api.set_module_address(self.module_address)
        return api
        
    def get_account(self) -> Account:
        """Tạo account từ private key"""
        if not self.private_key:
            raise ValueError("APTOS_PRIVATE_KEY environment variable is required")
        return Account.load_key(self.private_key) 