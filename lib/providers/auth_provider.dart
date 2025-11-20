import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

class AuthProvider extends ChangeNotifier {
  User? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get error => _errorMessage; // Add this getter for compatibility
  bool get isAuthenticated => _currentUser != null;

  AuthProvider() {
    _loadUserFromStorage();
  }

  Future<void> _loadUserFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('current_user');
      if (userJson != null) {
        final userMap = jsonDecode(userJson) as Map<String, dynamic>;
        _currentUser = User.fromJson(userMap);
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Failed to load user data';
      notifyListeners();
    }
  }

  Future<void> _saveUserToStorage(User user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = jsonEncode(user.toJson());
      await prefs.setString('current_user', userJson);
    } catch (e) {
      _errorMessage = 'Failed to save user data';
      notifyListeners();
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      // Simulate API call delay
      await Future.delayed(const Duration(seconds: 2));
      
      // Mock successful login validation
      if (email.isEmpty || password.isEmpty) {
        _errorMessage = 'Please enter both email and password';
        _setLoading(false);
        return false;
      }

      if (!email.contains('@')) {
        _errorMessage = 'Please enter a valid email address';
        _setLoading(false);
        return false;
      }

      if (password.length < 6) {
        _errorMessage = 'Password must be at least 6 characters';
        _setLoading(false);
        return false;
      }

      // Create mock user for successful login
      final mockUser = User(
        id: '1',
        email: email,
        name: email.split('@')[0],
        phoneNumber: null, // Phone number might not be available during login
        avatar: null,
        createdAt: DateTime.now(),
        isPremium: false,
      );
      
      _currentUser = mockUser;
      await _saveUserToStorage(mockUser);
      _setLoading(false);
      return true;
      
    } catch (e) {
      _errorMessage = 'Login failed: ${e.toString()}';
      _setLoading(false);
      return false;
    }
  }

  // Updated signup method with phone number support
  Future<bool> signup(String email, String password, String name, {String? phoneNumber}) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      // Simulate API call delay
      await Future.delayed(const Duration(seconds: 2));
      
      // Validate input fields
      if (email.isEmpty || password.isEmpty || name.isEmpty) {
        _errorMessage = 'Please fill in all required fields';
        _setLoading(false);
        return false;
      }

      if (!email.contains('@') || !email.contains('.')) {
        _errorMessage = 'Please enter a valid email address';
        _setLoading(false);
        return false;
      }

      if (password.length < 6) {
        _errorMessage = 'Password must be at least 6 characters long';
        _setLoading(false);
        return false;
      }

      if (name.trim().length < 2) {
        _errorMessage = 'Please enter a valid full name';
        _setLoading(false);
        return false;
      }

      // Validate phone number if provided
      if (phoneNumber != null && phoneNumber.isNotEmpty) {
        // Remove non-digit characters for validation
        String digitsOnly = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
        if (digitsOnly.length < 10) {
          _errorMessage = 'Please enter a valid phone number';
          _setLoading(false);
          return false;
        }
      }

      // Mock successful signup - Create new user
      final mockUser = User(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        email: email.toLowerCase().trim(),
        name: name.trim(),
        phoneNumber: phoneNumber, // Include phone number
        avatar: null,
        createdAt: DateTime.now(),
        isPremium: false,
      );
      
      _currentUser = mockUser;
      await _saveUserToStorage(mockUser);
      _setLoading(false);
      return true;
      
    } catch (e) {
      _errorMessage = 'Signup failed: ${e.toString()}';
      _setLoading(false);
      return false;
    }
  }

  // Method to update user profile with phone number
  Future<bool> updateUserProfile({
    String? name,
    String? phoneNumber,
    String? avatar,
  }) async {
    if (_currentUser == null) {
      _errorMessage = 'No user logged in';
      notifyListeners();
      return false;
    }

    _setLoading(true);

    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));

      // Create updated user
      final updatedUser = User(
        id: _currentUser!.id,
        email: _currentUser!.email,
        name: name ?? _currentUser!.name,
        phoneNumber: phoneNumber ?? _currentUser!.phoneNumber,
        avatar: avatar ?? _currentUser!.avatar,
        createdAt: _currentUser!.createdAt,
        isPremium: _currentUser!.isPremium,
      );

      _currentUser = updatedUser;
      await _saveUserToStorage(updatedUser);
      _setLoading(false);
      return true;
      
    } catch (e) {
      _errorMessage = 'Failed to update profile: ${e.toString()}';
      _setLoading(false);
      return false;
    }
  }

  // Method to verify phone number (for future SMS verification)
  Future<bool> verifyPhoneNumber(String phoneNumber, String verificationCode) async {
    _setLoading(true);
    
    try {
      // Simulate phone verification API call
      await Future.delayed(const Duration(seconds: 2));
      
      // Mock verification (in real app, this would verify with SMS service)
      if (verificationCode == '123456') {
        if (_currentUser != null) {
          final updatedUser = User(
            id: _currentUser!.id,
            email: _currentUser!.email,
            name: _currentUser!.name,
            phoneNumber: phoneNumber,
            avatar: _currentUser!.avatar,
            createdAt: _currentUser!.createdAt,
            isPremium: _currentUser!.isPremium,
          );
          
          _currentUser = updatedUser;
          await _saveUserToStorage(updatedUser);
        }
        _setLoading(false);
        return true;
      } else {
        _errorMessage = 'Invalid verification code';
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _errorMessage = 'Phone verification failed: ${e.toString()}';
      _setLoading(false);
      return false;
    }
  }

  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('current_user');
      _currentUser = null;
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Logout failed: ${e.toString()}';
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Method to check if phone number is verified
  bool get isPhoneVerified => _currentUser?.phoneNumber != null && _currentUser!.phoneNumber!.isNotEmpty;

  // Method to get formatted phone number
  String? get formattedPhoneNumber {
    if (_currentUser?.phoneNumber == null) return null;
    
    final phoneNumber = _currentUser!.phoneNumber!;
    if (phoneNumber.length >= 10) {
      // Format phone number for display (e.g., +1 (555) 123-4567)
      return phoneNumber;
    }
    return phoneNumber;
  }
}