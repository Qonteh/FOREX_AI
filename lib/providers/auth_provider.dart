import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firebase_service.dart';
import '../services/api_service.dart'; // ADD THIS IMPORT

class AuthProvider extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService.instance;
  final ApiService _apiService = ApiService.instance; // ADD THIS
  
  bool _isLoading = false;
  String? _error;
  User? _user;
  bool _isFirebaseConnected = false;
  bool _isApiConnected = false; // ADD THIS
  
  bool get isLoading => _isLoading;
  String? get error => _error;
  User? get user => _user;
  bool get isAuthenticated => _user != null;
  String? get userEmail => _user?.email;
  String? get userId => _user?.uid;
  bool get isFirebaseConnected => _isFirebaseConnected;
  bool get isApiConnected => _isApiConnected; // ADD THIS

  AuthProvider() {
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    print('🔐 AuthProvider: Initializing Firebase Auth...');
    
    try {
      // Test Firebase connection first
      _isFirebaseConnected = await _firebaseService.testConnection();
      print('🔥 Firebase Connection Status: ${_isFirebaseConnected ? "CONNECTED" : "DISCONNECTED"}');
      
      // Test API connection
      print('🔌 Testing API connection...');
      _isApiConnected = await _apiService.testConnection();
      print('🌐 API Connection Status: ${_isApiConnected ? "CONNECTED" : "DISCONNECTED"}');
      
      if (_isFirebaseConnected) {
        // Listen to auth state changes ONLY if Firebase is connected
        _firebaseService.auth.authStateChanges().listen((User? user) {
          print('🔄 Auth State Change: ${user?.email ?? "NO USER"}');
          _user = user;
          notifyListeners();
          
          if (user != null) {
            print('✅ User authenticated: ${user.email} (UID: ${user.uid})');
            // Sync user with your API
            _syncUserWithApi(user);
          } else {
            print('❌ User logged out or not authenticated');
            // Clear API token on logout
            _apiService.clearAuthToken();
          }
        });
        
        // Check current user
        _user = _firebaseService.auth.currentUser;
        if (_user != null) {
          print('👤 Current user found: ${_user!.email}');
          // Sync with API
          _syncUserWithApi(_user!);
        } else {
          print('👤 No current user found');
        }
      } else {
        print('⚠️ Firebase not connected - Auth will not work!');
        _error = 'Firebase connection failed. Authentication disabled.';
      }
      
      notifyListeners();
    } catch (e) {
      print('❌ AuthProvider initialization error: $e');
      _error = 'Failed to initialize authentication: $e';
      _isFirebaseConnected = false;
      notifyListeners();
    }
  }

  // ADD THIS METHOD: Sync Firebase user with your API
  Future<void> _syncUserWithApi(User firebaseUser) async {
    try {
      print('🔄 Syncing Firebase user with API...');
      
      // Get Firebase ID token
      final token = await firebaseUser.getIdToken();
      print('🔑 Firebase ID Token obtained');
      
      // Save token to API service
      await _apiService.saveAuthToken(token);
      
      // Register/Login user in your API
      final response = await _apiService.post('/auth/sync-firebase-user', data: {
        'firebase_uid': firebaseUser.uid,
        'email': firebaseUser.email,
        'name': firebaseUser.displayName,
        'photo_url': firebaseUser.photoURL,
        'firebase_token': token,
      });
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ User synchronized with API successfully');
        // Save API token if provided
        if (response.data['api_token'] != null) {
          await _apiService.saveAuthToken(response.data['api_token']);
        }
      } else {
        print('⚠️ API sync returned status: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Failed to sync user with API: $e');
      // Don't throw, just log - user can still use app
    }
  }

  Future<bool> login(String email, String password) async {
    print('🔐 LOGIN ATTEMPT: $email');
    
    if (!_isFirebaseConnected) {
      _error = 'Firebase not connected. Cannot authenticate.';
      notifyListeners();
      print('❌ LOGIN FAILED: Firebase not connected');
      return false;
    }
    
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('🔍 Validating credentials with Firebase Auth...');
      
      // REAL FIREBASE AUTHENTICATION
      final user = await _firebaseService.signInWithEmailAndPassword(email, password);
      
      if (user != null) {
        _user = user;
        
        print('✅ LOGIN SUCCESS: ${user.email}');
        print('📊 User UID: ${user.uid}');
        
        // Sync with your API
        await _syncUserWithApi(user);
        
        // Update last login time in Firestore
        try {
          await _firebaseService.updateUserDocument(user.uid, {
            'lastLoginAt': FieldValue.serverTimestamp(),
            'email': email,
            'loginCount': FieldValue.increment(1),
          });
          print('✅ User login data updated in Firestore');
        } catch (firestoreError) {
          print('⚠️ Failed to update login data: $firestoreError');
        }
        
        _isLoading = false;
        notifyListeners();
        
        return true;
      } else {
        _error = 'Login failed. Invalid credentials.';
        _isLoading = false;
        notifyListeners();
        
        print('❌ LOGIN FAILED: No user returned from Firebase');
        return false;
      }
    } on FirebaseAuthException catch (e) {
      // ... keep existing error handling ...
    } catch (e) {
      _error = 'An unexpected error occurred during login: $e';
      _isLoading = false;
      notifyListeners();
      
      print('❌ LOGIN FAILED: Unexpected error: $e');
      return false;
    }
  }

  // Add this method to test API endpoints
  Future<void> testApiEndpoints() async {
    print('🧪 TESTING API ENDPOINTS...');
    
    try {
      // Test 1: Health endpoint
      print('1️⃣ Testing /health endpoint...');
      final healthResponse = await _apiService.get('/health');
      print('   ✅ /health: ${healthResponse.statusCode} - ${healthResponse.data}');
      
      // Test 2: Public endpoint
      print('2️⃣ Testing /api/public endpoint...');
      final publicResponse = await _apiService.get('/api/public');
      print('   ✅ /api/public: ${publicResponse.statusCode}');
      
      // Test 3: If user is authenticated, test protected endpoint
      if (_user != null) {
        print('3️⃣ Testing protected endpoint with auth...');
        try {
          final protectedResponse = await _apiService.get('/api/protected/user');
          print('   ✅ Protected endpoint: ${protectedResponse.statusCode}');
        } catch (e) {
          print('   ❌ Protected endpoint failed: $e');
        }
      }
      
      print('🎉 API ENDPOINT TESTS COMPLETED');
      
    } catch (e) {
      print('❌ API endpoint tests failed: $e');
    }
  }

  // ... rest of your existing methods ...
}