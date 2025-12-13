import 'package:flutter/foundation.dart';

class AuthProvider extends ChangeNotifier {
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _user;
  
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic>? get user => _user;
  bool get isAuthenticated => _user != null;
  String? get userEmail => _user?['email'];
  String? get userId => _user?['id'];

  AuthProvider() {
    print('🔐 AuthProvider: Initialized (No Firebase)');
  }

  Future<bool> login(String email, String password) async {
    print('🔐 LOGIN ATTEMPT: $email');
    
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Simulate login - in production, connect to your backend API
      await Future.delayed(const Duration(seconds: 1));
      
      // Mock successful login
      _user = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'email': email,
        'name': email.split('@')[0],
      };
      
      print('✅ LOGIN SUCCESS: $email');
      
      _isLoading = false;
      notifyListeners();
      
      return true;
    } catch (e) {
      _error = 'An unexpected error occurred during login: $e';
      _isLoading = false;
      notifyListeners();
      
      print('❌ LOGIN FAILED: Unexpected error: $e');
      return false;
    }
  }

  Future<bool> signup(String email, String password, String name) async {
    print('👤 SIGNUP ATTEMPT: $email');
    
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Simulate signup - in production, connect to your backend API
      await Future.delayed(const Duration(seconds: 1));
      
      // Mock successful signup
      _user = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'email': email,
        'name': name,
      };
      
      print('✅ SIGNUP SUCCESS: $email');
      
      _isLoading = false;
      notifyListeners();
      
      return true;
    } catch (e) {
      _error = 'An unexpected error occurred during signup: $e';
      _isLoading = false;
      notifyListeners();
      
      print('❌ SIGNUP FAILED: Unexpected error: $e');
      return false;
    }
  }

  Future<void> logout() async {
    print('🚪 LOGOUT');
    _user = null;
    notifyListeners();
  }
}