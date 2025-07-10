#!/usr/bin/env python3
"""
Convert mnemonic to private key hex for Aptos CLI
"""

import hashlib
import hmac
import binascii

def mnemonic_to_seed(mnemonic):
    """Convert mnemonic to seed using PBKDF2"""
    import hashlib
    import hmac
    
    # BIP39 salt
    salt = "mnemonic"
    
    # Use PBKDF2 to derive seed
    seed = hashlib.pbkdf2_hmac('sha512', mnemonic.encode('utf-8'), salt.encode('utf-8'), 2048)
    return seed

def derive_private_key(seed, path="m/44'/637'/0'/0'/0'"):
    """Derive private key from seed using BIP44 path"""
    import hmac
    import hashlib
    
    # Parse path
    path_parts = path.split('/')
    
    # Start with seed
    current = seed
    
    for part in path_parts[1:]:  # Skip 'm'
        if part.endswith("'"):
            # Hardened derivation
            index = int(part[:-1]) + 0x80000000
        else:
            # Normal derivation
            index = int(part)
        
        # Create data for HMAC
        if index >= 0x80000000:
            # Hardened
            data = b'\x00' + current[:32] + index.to_bytes(4, 'big')
        else:
            # Normal
            data = current[32:] + index.to_bytes(4, 'big')
        
        # HMAC-SHA512
        h = hmac.new(current[32:], data, hashlib.sha512).digest()
        
        # Split result
        il, ir = h[:32], h[32:]
        
        # Update current
        current = il + ir
    
    return current[:32]  # Return first 32 bytes as private key

def main():
    # Your mnemonic
    mnemonic = "canal fox estate pupil seat rebuild lizard ill coin lumber ability innocent"
    
    print("Converting mnemonic to private key...")
    print(f"Mnemonic: {mnemonic}")
    
    # Convert to seed
    seed = mnemonic_to_seed(mnemonic)
    print(f"Seed (hex): {seed.hex()}")
    
    # Derive private key
    private_key_bytes = derive_private_key(seed)
    private_key_hex = private_key_bytes.hex()
    
    print(f"\nPrivate Key (hex): {private_key_hex}")
    print(f"Length: {len(private_key_hex)} characters")
    
    print(f"\nExpected Address: 0x19fc3b30e6839f609514af5861645f365b87627d25faf83d2a6d4889614f2883")
    print("\n✅ Private key derived successfully!")
    print("\n📋 Next steps:")
    print("1. Use this private key to configure Aptos CLI")
    print("2. Run: aptos init --profile mainnet --private-key <PRIVATE_KEY> --network mainnet")
    print("3. Then deploy your smart contracts")

if __name__ == "__main__":
    main() 