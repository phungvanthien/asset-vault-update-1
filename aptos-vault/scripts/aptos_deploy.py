#!/usr/bin/env python3
"""
Deploy Aptos Vault System
Deploys all 3 modules: vault_core, pancakeswap_adapter, vault_comptroller
"""

import os
import subprocess
import sys
from pathlib import Path

# Add project root to path
project_root = Path(__file__).parent.parent
sys.path.append(str(project_root))

from aptos_conf import APTOS_CONFIG

def deploy_modules():
    """Deploy all vault modules to Aptos Mainnet"""
    
    print("🚀 Deploying Aptos Vault System...")
    print(f"Network: {APTOS_CONFIG['network']}")
    print(f"Account: {APTOS_CONFIG['account']}")
    
    # Compile modules first
    print("\n📦 Compiling modules...")
    compile_result = subprocess.run([
        "aptos", "move", "compile",
        "--package-dir", ".",
        "--named-addresses", f"vault={APTOS_CONFIG['account']}"
    ], capture_output=True, text=True)
    
    if compile_result.returncode != 0:
        print("❌ Compilation failed:")
        print(compile_result.stderr)
        return False
    
    print("✅ Compilation successful!")
    
    # Deploy modules
    print("\n🚀 Deploying modules...")
    deploy_result = subprocess.run([
        "aptos", "move", "publish",
        "--package-dir", ".",
        "--named-addresses", f"vault={APTOS_CONFIG['account']}",
        "--profile", "mainnet"
    ], capture_output=True, text=True)
    
    if deploy_result.returncode != 0:
        print("❌ Deployment failed:")
        print(deploy_result.stderr)
        return False
    
    print("✅ Deployment successful!")
    
    # Extract module addresses from deployment output
    print("\n📋 Deployed module addresses:")
    for line in deploy_result.stdout.split('\n'):
        if "vault::vault_core" in line:
            print(f"  vault_core: {line.strip()}")
        elif "vault::pancakeswap_adapter" in line:
            print(f"  pancakeswap_adapter: {line.strip()}")
        elif "vault::vault_comptroller" in line:
            print(f"  vault_comptroller: {line.strip()}")
    
    return True

def create_vault():
    """Create initial vault after deployment"""
    
    print("\n🏦 Creating initial vault...")
    
    # Create vault with USDT as denomination asset
    create_result = subprocess.run([
        "aptos", "move", "run",
        "--function-id", f"{APTOS_CONFIG['account']}::vault_core::create_vault",
        "--args", 
        "address:0xf22bede237a07e121b56d91a491eb7bcdfd1f5907926a9e58338f964a01b17fa",  # USDT address
        f"address:{APTOS_CONFIG['account']}",  # fund_manager
        "u64:100",  # fee_rate (1% = 100 basis points)
        "--profile", "mainnet"
    ], capture_output=True, text=True)
    
    if create_result.returncode != 0:
        print("❌ Vault creation failed:")
        print(create_result.stderr)
        return False
    
    print("✅ Vault created successfully!")
    
    # Create comptroller for the vault
    print("\n🎛️ Creating comptroller...")
    comptroller_result = subprocess.run([
        "aptos", "move", "run",
        "--function-id", f"{APTOS_CONFIG['account']}::vault_comptroller::create_comptroller",
        "--args",
        "u64:0",  # vault_id (first vault)
        f"address:{APTOS_CONFIG['account']}",  # fund_manager
        "--profile", "mainnet"
    ], capture_output=True, text=True)
    
    if comptroller_result.returncode != 0:
        print("❌ Comptroller creation failed:")
        print(comptroller_result.stderr)
        return False
    
    print("✅ Comptroller created successfully!")
    
    return True

def main():
    """Main deployment function"""
    
    print("=" * 60)
    print("🏦 APTOS VAULT SYSTEM DEPLOYMENT")
    print("=" * 60)
    
    # Check if we're in the right directory
    if not Path("Move.toml").exists():
        print("❌ Error: Move.toml not found. Please run from aptos-vault directory.")
        return False
    
    # Deploy modules
    if not deploy_modules():
        return False
    
    # Create initial vault
    if not create_vault():
        return False
    
    print("\n" + "=" * 60)
    print("🎉 DEPLOYMENT COMPLETE!")
    print("=" * 60)
    print(f"✅ All 3 modules deployed to {APTOS_CONFIG['network']}")
    print(f"✅ Initial vault created with USDT denomination")
    print(f"✅ Comptroller created for vault management")
    print("\n📋 Next steps:")
    print("1. Fund your wallet with USDT for testing")
    print("2. Run: python scripts/aptos_deposit.py")
    print("3. Run: python scripts/aptos_rebalance.py")
    print("4. Check vault status with API")
    
    return True

if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1) 