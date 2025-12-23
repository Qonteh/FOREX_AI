#!/usr/bin/env python
"""Test script to verify bcrypt password hashing works correctly."""

import sys
import os

# Add the current directory to the path
sys.path.insert(0, os.path.dirname(__file__))

from app.crud import get_password_hash, verify_password


def test_password_hashing():
    """Test that password hashing works."""
    print("Testing password hashing...")
    
    # Test with normal password
    password1 = "testpassword123"
    hashed1 = get_password_hash(password1)
    print(f"✅ Normal password hashed: {hashed1[:30]}...")
    
    # Verify the password
    assert verify_password(password1, hashed1), "Password verification failed!"
    print("✅ Password verification works")
    
    # Test with long password (>72 bytes)
    # This was causing the error in the problem statement
    long_password = "a" * 100  # 100 character password
    hashed2 = get_password_hash(long_password)
    print(f"✅ Long password hashed: {hashed2[:30]}...")
    
    # Verify the long password
    assert verify_password(long_password, hashed2), "Long password verification failed!"
    print("✅ Long password verification works")
    
    # Test with very long UTF-8 characters (which can take more than 1 byte per char)
    utf8_password = "password123" + "é" * 30  # Some multi-byte characters
    hashed3 = get_password_hash(utf8_password)
    print(f"✅ UTF-8 password hashed: {hashed3[:30]}...")
    
    # Verify the UTF-8 password
    assert verify_password(utf8_password, hashed3), "UTF-8 password verification failed!"
    print("✅ UTF-8 password verification works")
    
    print("\n🎉 All password hashing tests passed!")


if __name__ == "__main__":
    test_password_hashing()
