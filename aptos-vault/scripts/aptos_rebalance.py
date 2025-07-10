"""
Rebalance Aptos vault using PancakeSwap.
Tương thích với hackathon/rebalance.py hiện tại.
"""

import os
import logging
from typing import List

from aptos_sdk.account import Account
from aptos_sdk.client import RestClient

from api.aptos_vault_api import AptosVaultAPI, AptosVaultConfig


def rebalance():
    """Rebalance vault portfolio"""
    
    logger = logging.getLogger(__name__)
    
    # Setup configuration
    config = AptosVaultConfig()
    api = config.get_api()
    fund_manager = config.get_account()
    
    logger.info(f"Fund manager address is {fund_manager.address()}")
    
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
    
    # Get USDT balance in vault
    try:
        total_assets = vault_info.total_assets
        logger.info(f"Vault has {total_assets} USDT")
        
        if total_assets == 0:
            logger.error("No assets in vault to rebalance")
            return
            
    except Exception as e:
        logger.error(f"Error getting vault assets: {e}")
        return
    
    # Prepare rebalance trades
    # Swap 50% USDT to APT (simulated)
    swap_amount = total_assets // 2
    
    # Create trade IDs (simplified for Aptos)
    trades = [1, 2]  # Trade IDs for USDT->APT swap
    
    try:
        # Execute rebalance
        tx_hash = api.rebalance(fund_manager, 0, trades)
        logger.info(f"Rebalance successful: {tx_hash}")
        
        # Get updated vault info
        updated_vault_info = api.get_vault_info(0)
        logger.info(f"Updated vault info: {updated_vault_info}")
        
    except Exception as e:
        logger.error(f"Error rebalancing: {e}")
        return
    
    logger.info("Rebalance done")


if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO)
    rebalance() 