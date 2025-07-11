#!/usr/bin/env python3
"""
Aptos Vault API Server
Connects the Aptos vault with the existing UI and Trading Bot
"""

import os
import json
import subprocess
import requests
from flask import Flask, request, jsonify
from flask_cors import CORS
import time

app = Flask(__name__)
CORS(app)

# Configuration
VAULT_ADDRESS = "0xb380dc1036ffeed2f2fe06977a17275e4a71d9ca3a3df58b370aa7faba336c4d"  # Mainnet address
NETWORK = "mainnet"
APTOS_CLI_PATH = "aptos"

# USDT LayerZero address on Aptos Mainnet
USDT_ADDRESS = "0xf22bede237a07e121b56d91a491eb7bcdfd1f5907926a9e58338f964a01b17fa"
APT_ADDRESS = "0x1"
PANCAKESWAP_ROUTER = "0xc7efb4076dbe143cbcd98cfaaa929ecfc8f299405d018d7e18f75ac2b0e95f60"

class AptosVaultAPI:
    def __init__(self):
        self.vault_address = VAULT_ADDRESS
        self.network = NETWORK
        
    def call_vault_function(self, function_name, type_args=None, args=None):
        """Call vault function using Aptos CLI"""
        try:
            # Temporary mock implementation for testing
            if function_name == "deposit":
                return {"success": True, "data": "Mock deposit successful"}
            elif function_name == "withdraw":
                return {"success": True, "data": "Mock withdraw successful"}
            elif function_name == "rebalance":
                return {"success": True, "data": "Mock rebalance successful"}
            elif function_name == "swap_exact_tokens_for_tokens":
                return {"success": True, "data": "Mock swap successful"}
            else:
                return {"success": False, "error": "Unknown function"}
            
            # Original code (commented out for now)
            cmd = [
                APTOS_CLI_PATH, "move", "run",
                "--function-id", f"{self.vault_address}::vault::{function_name}",
                "--profile", "mainnet"
            ]
            # 
            # if type_args:
            #     cmd.extend(["--type-args", *type_args])
            # 
            # if args:
            #     cmd.extend(["--args", *args])
            # 
            # result = subprocess.run(cmd, capture_output=True, text=True)
            # 
            # if result.returncode == 0:
            #     return {"success": True, "data": result.stdout}
            # else:
            #     return {"success": False, "error": result.stderr}
                
        except Exception as e:
            return {"success": False, "error": str(e)}
    
    def get_vault_status(self):
        """Get vault status"""
        try:
            # Temporary mock data while contract is being deployed
            return {
                "success": True, 
                "data": {
                    "total_shares": 100000000,
                    "total_usdt": 50000000,
                    "total_apt": 25000000,
                    "created_at": 1731234567
                }
            }
            
            # Original code (commented out for now)
            cmd = [
                APTOS_CLI_PATH, "move", "view",
                "--function-id", f"{self.vault_address}::vault::get_vault_status",
                "--profile", "mainnet"
            ]
            # 
            # result = subprocess.run(cmd, capture_output=True, text=True)
            # 
            # if result.returncode == 0:
            #     # Parse the output to extract values
            #     output = result.stdout.strip()
            #     # Extract values from output (simplified parsing)
            #     return {"success": True, "data": output}
            # else:
            #     return {"success": False, "error": result.stderr}
                
        except Exception as e:
            return {"success": False, "error": str(e)}
    
    def get_user_balance(self, user_address):
        """Get user balance"""
        try:
            # Temporary mock data
            return {
                "success": True,
                "data": {
                    "shares": 50000000,
                    "usdt_balance": 25000000
                }
            }
            
            # Original code (commented out for now)
            cmd = [
                APTOS_CLI_PATH, "move", "view",
                "--function-id", f"{self.vault_address}::vault::get_user_balance",
                "--args", f"address:{user_address}",
                "--profile", "mainnet"
            ]
            # 
            # result = subprocess.run(cmd, capture_output=True, text=True)
            # 
            # if result.returncode == 0:
            #     return {"success": True, "data": result.stdout}
            # else:
            #     return {"success": False, "error": result.stderr}
                
        except Exception as e:
            return {"success": False, "error": str(e)}

# Initialize API
vault_api = AptosVaultAPI()

@app.route('/')
def home():
    return jsonify({
        "message": "Aptos Vault API Server",
        "version": "1.0.0",
        "vault_address": VAULT_ADDRESS,
        "network": NETWORK
    })

@app.route('/api/vault/status', methods=['GET'])
def get_vault_status():
    """Get vault status"""
    try:
        result = vault_api.get_vault_status()
        return jsonify(result)
    except Exception as e:
        return jsonify({"success": False, "error": str(e)}), 500

@app.route('/api/vault/balance/<user_address>', methods=['GET'])
def get_user_balance(user_address):
    """Get user balance"""
    try:
        result = vault_api.get_user_balance(user_address)
        return jsonify(result)
    except Exception as e:
        return jsonify({"success": False, "error": str(e)}), 500

@app.route('/api/vault/deposit', methods=['POST'])
def deposit():
    """Deposit USDT into vault"""
    try:
        data = request.get_json()
        amount = data.get('amount', 0)
        user_address = data.get('user_address')
        
        if not amount or amount <= 0:
            return jsonify({"success": False, "error": "Invalid amount"}), 400
        
        if not user_address:
            return jsonify({"success": False, "error": "User address required"}), 400
        
        # Call vault deposit function
        result = vault_api.call_vault_function(
            "deposit",
            args=[f"u64:{amount}"]
        )
        
        return jsonify(result)
        
    except Exception as e:
        return jsonify({"success": False, "error": str(e)}), 500

@app.route('/api/vault/withdraw', methods=['POST'])
def withdraw():
    """Withdraw USDT from vault"""
    try:
        data = request.get_json()
        shares = data.get('shares', 0)
        user_address = data.get('user_address')
        
        if not shares or shares <= 0:
            return jsonify({"success": False, "error": "Invalid shares amount"}), 400
        
        if not user_address:
            return jsonify({"success": False, "error": "User address required"}), 400
        
        # Call vault withdraw function
        result = vault_api.call_vault_function(
            "withdraw",
            args=[f"u64:{shares}"]
        )
        
        return jsonify(result)
        
    except Exception as e:
        return jsonify({"success": False, "error": str(e)}), 500

@app.route('/api/vault/rebalance', methods=['POST'])
def rebalance():
    """Rebalance vault (swap USDT for APT)"""
    try:
        data = request.get_json()
        usdt_amount = data.get('usdt_amount', 0)
        owner_address = data.get('owner_address')
        
        if not usdt_amount or usdt_amount <= 0:
            return jsonify({"success": False, "error": "Invalid USDT amount"}), 400
        
        if not owner_address:
            return jsonify({"success": False, "error": "Owner address required"}), 400
        
        # Call vault rebalance function
        result = vault_api.call_vault_function(
            "rebalance",
            args=[f"u64:{usdt_amount}"]
        )
        
        return jsonify(result)
        
    except Exception as e:
        return jsonify({"success": False, "error": str(e)}), 500

@app.route('/api/vault/swap', methods=['POST'])
def swap_tokens():
    """Swap tokens using PancakeSwap"""
    try:
        data = request.get_json()
        input_token = data.get('input_token')
        output_token = data.get('output_token')
        amount_in = data.get('amount_in', 0)
        
        if not amount_in or amount_in <= 0:
            return jsonify({"success": False, "error": "Invalid amount"}), 400
        
        if not input_token or not output_token:
            return jsonify({"success": False, "error": "Token addresses required"}), 400
        
        # Call PancakeSwap adapter
        result = vault_api.call_vault_function(
            "swap_exact_tokens_for_tokens",
            args=[
                f"u64:{amount_in}",
                "u64:0",  # amount_out_min
                f"vector<address>:[{input_token},{output_token}]",
                "u64:0"   # deadline
            ]
        )
        
        return jsonify(result)
        
    except Exception as e:
        return jsonify({"success": False, "error": str(e)}), 500

@app.route('/api/vault/info', methods=['GET'])
def get_vault_info():
    """Get vault information"""
    return jsonify({
        "vault_address": VAULT_ADDRESS,
        "network": NETWORK,
        "usdt_address": USDT_ADDRESS,
        "apt_address": APT_ADDRESS,
        "pancakeswap_router": PANCAKESWAP_ROUTER
    })

if __name__ == '__main__':
    print("🚀 Starting Aptos Vault API Server...")
    print(f"📊 Vault Address: {VAULT_ADDRESS}")
    print(f"🌐 Network: {NETWORK}")
    print("🔗 API Endpoints:")
    print("   POST /api/vault/deposit")
    print("   POST /api/vault/withdraw")
    print("   POST /api/vault/rebalance")
    print("   POST /api/vault/swap")
    print("   GET  /api/vault/status")
    print("   GET  /api/vault/balance/<user_address>")
    print("   GET  /api/vault/info")
    print("🌍 Server running on http://localhost:5001")
    
    app.run(host='0.0.0.0', port=5001, debug=True) 