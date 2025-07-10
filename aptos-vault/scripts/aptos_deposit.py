"""
User deposits USDT into the Aptos vault.
Tương thích với hackathon/deposit.py hiện tại.
"""

import os
import logging
from decimal import Decimal

from aptos_sdk.account import Account
from aptos_sdk.client import RestClient

from api.aptos_vault_api import AptosVaultAPI, AptosVaultConfig


def deposit():
    """Deposit USDT vào Aptos vault"""
    
    logger = logging.getLogger(__name__)
    
    # Setup configuration
    config = AptosVaultConfig()
    api = config.get_api()
    user_account = config.get_account()
    
    logger.info(f"User address is {user_account.address()}")
    
    # Get user balance
    try:
        # Check USDT balance
        usdt_balance = api.client.account_balance(user_account.address())
        logger.info(f"User has {usdt_balance} APT")
        
        # Check if user has enough balance
        if usdt_balance < 1000000:  # 1 APT minimum
            logger.error("Insufficient balance for transaction fees")
            return
            
    except Exception as e:
        logger.error(f"Error checking balance: {e}")
        return
    
    # Get vault info
    try:
        vault_info = api.get_vault_info(0)  # First vault
        logger.info(f"Vault info: {vault_info}")
        
        if not vault_info.is_active:
            logger.error("Vault is not active")
            return
            
    except Exception as e:
        logger.error(f"Error getting vault info: {e}")
        return
    
    # Deposit amount (3 USDT equivalent)
    deposit_amount = 3 * 1000000  # 3 USDT with 6 decimals
    
    try:
        # Perform deposit
        tx_hash = api.deposit(user_account, 0, deposit_amount)
        logger.info(f"Deposit successful: {tx_hash}")
        
        # Get updated position
        position = api.get_user_position(user_account.address(), 0)
        logger.info(f"User position after deposit: {position}")
        
    except Exception as e:
        logger.error(f"Error depositing: {e}")
        return
    
    logger.info("Deposit done")


if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO)
    deposit() 