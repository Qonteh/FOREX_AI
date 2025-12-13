import 'package:flutter/foundation.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService.instance;
  
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _user;
  bool _isApiConnected = false;
  
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic>? get user => _user;
  bool get isAuthenticated => _user != null;
  String? get userEmail => _user?['email'];
  String? get userId => _user?['id']?.toString();
  String? get userName => _user?['name'];
  String? get userPhone => _user?['phone'];
  bool get isApiConnected => _isApiConnected;

  AuthProvider() {
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    print('🔐 AuthProvider: Initializing FastAPI Auth...');
    
    try {
      // Test API connection
      print('🔌 Testing API connection...');
      _isApiConnected = await _apiService.testConnection();
      print('🌐 API Connection Status: ${_isApiConnected ? "CONNECTED" : "DISCONNECTED"}');
      
      if (_isApiConnected) {
        // Try to load current user if token exists
        await loadCurrentUser();
      } else {
        print('⚠️ API not connected - skipping user load');
      }
    } catch (e) {
      print('❌ Auth initialization error: $e');
      _error = 'Failed to connect to backend';
    }
    
    notifyListeners();
  }

  Future<void> loadCurrentUser() async {
    try {
      print('👤 Loading current user...');
      _user = await _apiService.getCurrentUser();
      print('✅ User loaded: ${_user?['email']}');
      _error = null;
    } catch (e) {
      print('⚠️ No user session found or token expired');
      _user = null;
      await _apiService.clearAuthToken();
    }
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    print('🔐 AuthProvider: Login attempt for $email');
    _setLoading(true);
    _error = null;

    try {
      final response = await _apiService.login(
        email: email,
        password: password,
      );

      _user = response['user'];
      print('✅ Login successful: ${_user?['email']}');
      _setLoading(false);
      return true;
    } catch (e) {
      print('❌ Login failed: $e');
      _error = _extractErrorMessage(e);
      _setLoading(false);
      return false;
    }
  }

  Future<bool> signup({
    required String email,
    required String password,
    required String name,
    String? phoneNumber,
  }) async {
    print('📝 AuthProvider: Signup attempt for $email');
    _setLoading(true);
    _error = null;

    try {
      final response = await _apiService.register(
        email: email,
        password: password,
        name: name,
        phone: phoneNumber,
      );

      // DO NOT auto-login after signup - user needs to verify email first
      // _user = response['user'];  // Commented out - no auto-login
      print('✅ Signup successful: ${response['user']?['email']}');
      print('📧 Email verification required before login');
      _setLoading(false);
      return true;
    } catch (e) {
      print('❌ Signup failed: $e');
      _error = _extractErrorMessage(e);
      _setLoading(false);
      return false;
    }
  }

  Future<void> logout() async {
    print('🚪 AuthProvider: Logging out');
    _setLoading(true);

    try {
      await _apiService.logout();
      _user = null;
      _error = null;
      print('✅ Logout successful');
    } catch (e) {
      print('❌ Logout error: $e');
      // Still clear local state even if API call fails
      _user = null;
      _error = null;
    }

    _setLoading(false);
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  String _extractErrorMessage(dynamic error) {
    final errorStr = error.toString();
    
    if (errorStr.contains('Exception:')) {
      return errorStr.replaceFirst('Exception:', '').trim();
    }
    
    if (errorStr.contains('email_already_exists') || errorStr.contains('email already exists')) {
      return 'An account with this email already exists';
    }
    
    if (errorStr.contains('phone_already_exists') || errorStr.contains('phone already exists')) {
      return 'This phone number is already registered';
    }
    
    if (errorStr.contains('invalid_credentials') || errorStr.contains('Incorrect')) {
      return 'Invalid email or password';
    }
    
    if (errorStr.contains('Connection') || errorStr.contains('Failed to connect')) {
      return 'Cannot connect to server. Please check your connection.';
    }
    
    return 'An error occurred. Please try again.';
  }

  // Method to test both Firebase and API connections
  Future<Map<String, bool>> testConnections() async {
    print('🔍 Testing all connections...');
    
    _isApiConnected = await _apiService.testConnection();
    
    print('📊 Connection Test Results:');
    print('   - API: ${_isApiConnected ? "✅ CONNECTED" : "❌ DISCONNECTED"}');
    
    notifyListeners();
    
    return {
      'api': _isApiConnected,
    };
  }
}
