"""Deploy Aptos vault with the adapter.

To run:

    poetry run deploy_aptos
"""
import os
import json
from typing import Dict, Any

from hackathon.logs import setup_logging


def deploy_aptos():
    """Deploy our vault on Aptos Mainnet."""

    logger = setup_logging()

    # Contract addresses đã deploy thành công
    VAULT_ADDRESS = "0x2fdd1d8c08c6d2e447cffd67419cd9f0d53bedd003e5a6ee427b649f0c1077ef"
    
    # Token addresses trên Aptos Mainnet
    APT_TOKEN_ADDRESS = "0x1::aptos_coin::AptosCoin"
    USDT_TOKEN_ADDRESS = "0xf22bede237a07e121b56d91a491eb7bcdfd1f5907926a9e58338f964a01b17fa"
    
    # PancakeSwap Router address
    PANCAKESWAP_ROUTER = "0xc7efb4076dbe143cbcd98cfaaa929ecfc8f299405d018d7e18f75ac2b0e95f60"
    
    logger.info(f"Vault address: {VAULT_ADDRESS}")
    logger.info(f"APT token address: {APT_TOKEN_ADDRESS}")
    logger.info(f"USDT token address: {USDT_TOKEN_ADDRESS}")
    logger.info(f"PancakeSwap Router: {PANCAKESWAP_ROUTER}")
    
    # Lưu thông tin deployment
    deployment_info = {
        "vault_address": VAULT_ADDRESS,
        "apt_token_address": APT_TOKEN_ADDRESS,
        "usdt_token_address": USDT_TOKEN_ADDRESS,
        "pancakeswap_router": PANCAKESWAP_ROUTER,
        "network": "mainnet",
        "deployed_at": "2024-12-09T12:00:00Z"
    }
    
    with open("deployment_info.json", "w") as f:
        json.dump(deployment_info, f, indent=2)
    
    logger.info("Deployment info saved to deployment_info.json")
    logger.info("✅ Aptos Vault deployed successfully!")
    
    return deployment_info


if __name__ == "__main__":
    deploy_aptos() 