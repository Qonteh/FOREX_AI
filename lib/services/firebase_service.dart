import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../firebase_options.dart';

class FirebaseService {
  static FirebaseService? _instance;
  static FirebaseService get instance => _instance ??= FirebaseService._();
  
  FirebaseService._();
  
  firebase_auth.FirebaseAuth get auth => firebase_auth.FirebaseAuth.instance;
  FirebaseFirestore get firestore => FirebaseFirestore.instance;
  
  static Future<void> initialize() async {
    try {
      print('🔥 FirebaseService: Starting initialization...');
      print('📱 Platform: ${DefaultFirebaseOptions.currentPlatform.runtimeType}');
      print('🎯 Project ID: ${DefaultFirebaseOptions.currentPlatform.projectId}');
      print('🔑 API Key: ${DefaultFirebaseOptions.currentPlatform.apiKey.substring(0, 10)}...');
      
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      
      print('✅ Firebase Core: Initialized successfully');
      print('🏃‍♂️ Firebase Apps: ${Firebase.apps.map((app) => app.name).toList()}');
      
      // Test Auth service immediately
      final currentUser = firebase_auth.FirebaseAuth.instance.currentUser;
      print('👤 Firebase Auth: ${currentUser?.email ?? "No current user"}');
      
      // Test Firestore service immediately
      print('🗄️ Firestore: Testing connection...');
      final firestore = FirebaseFirestore.instance;
      print('✅ Firestore: Instance created successfully');
      
      // Enable network for Firestore
      await firestore.enableNetwork();
      print('✅ Firestore: Network enabled and ready');
      
    } catch (e, stackTrace) {
      print('❌ Firebase initialization FAILED: $e');
      print('📊 Stack trace: $stackTrace');
      rethrow;
    }
  }
  
  Future<bool> testConnection() async {
    try {
      print('🧪 FirebaseService: Testing full connection...');
      
      // Test 1: Firebase Core
      final apps = Firebase.apps;
      if (apps.isEmpty) {
        print('❌ Firebase Core: No apps initialized');
        return false;
      }
      print('✅ Firebase Core: ${apps.length} app(s) initialized');
      print('📱 App names: ${apps.map((app) => app.name).toList()}');
      
      // Test 2: Authentication Service
      try {
        final authState = auth.currentUser;
        print('✅ Firebase Auth: Service accessible');
        print('👤 Current user: ${authState?.email ?? "None"}');
        print('🔐 Auth state: ${authState != null ? "Authenticated" : "Not authenticated"}');
      } catch (authError) {
        print('❌ Firebase Auth: Service error - $authError');
        return false;
      }
      
      // Test 3: Firestore Connection Test
      print('🗄️ Testing Firestore write operation...');
      final testDoc = firestore.collection('connection_test').doc('test_${DateTime.now().millisecondsSinceEpoch}');
      
      await testDoc.set({
        'timestamp': FieldValue.serverTimestamp(),
        'test': 'connection_successful',
        'service': 'FirebaseService',
        'project_id': DefaultFirebaseOptions.currentPlatform.projectId,
        'test_id': DateTime.now().millisecondsSinceEpoch,
      });
      
      print('✅ Firestore: Write test successful');
      
      // Test 4: Firestore Read
      final readDoc = await testDoc.get();
      if (readDoc.exists) {
        print('✅ Firestore: Read test successful');
        print('📊 Test data: ${readDoc.data()}');
      } else {
        print('⚠️ Firestore: Document not found after write');
      }
      
      // Test 5: Collection query
      print('🔍 Testing Firestore query...');
      final queryResult = await firestore.collection('connection_test').limit(1).get();
      print('✅ Firestore: Query test successful (${queryResult.docs.length} docs)');
      
      print('🎉 Firebase: ALL SERVICES OPERATIONAL');
      return true;
      
    } catch (e, stackTrace) {
      print('❌ Firebase connection test FAILED: $e');
      print('📊 Error type: ${e.runtimeType}');
      print('📊 Stack trace: $stackTrace');
      return false;
    }
  }
  
  Future<firebase_auth.User?> signInWithEmailAndPassword(String email, String password) async {
    try {
      print('🔐 FirebaseService: Signing in user: $email');
      
      final credential = await auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      final user = credential.user;
      if (user != null) {
        print('✅ Firebase Auth: Sign in successful');
        print('📊 User details:');
        print('   - UID: ${user.uid}');
        print('   - Email: ${user.email}');
        print('   - Verified: ${user.emailVerified}');
        print('   - Display Name: ${user.displayName ?? "Not set"}');
        print('   - Created: ${user.metadata.creationTime}');
        print('   - Last Sign In: ${user.metadata.lastSignInTime}');
      }
      
      return user;
    } on firebase_auth.FirebaseAuthException catch (e) {
      print('❌ Firebase Auth Error: ${e.code}');
      print('📝 Error message: ${e.message}');
      print('📊 Error details: $e');
      throw Exception(getFirebaseAuthErrorMessage(e.code));
    } catch (e, stackTrace) {
      print('❌ Sign in unexpected error: $e');
      print('📊 Stack trace: $stackTrace');
      throw Exception('An unexpected error occurred during sign in');
    }
  }
  
  Future<firebase_auth.User?> createUserWithEmailAndPassword(String email, String password) async {
    try {
      print('👤 FirebaseService: Creating user: $email');
      
      final credential = await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      final user = credential.user;
      if (user != null) {
        print('✅ Firebase Auth: User created successfully');
        print('📊 New user details:');
        print('   - UID: ${user.uid}');
        print('   - Email: ${user.email}');
        print('   - Verified: ${user.emailVerified}');
      }
      
      return user;
    } on firebase_auth.FirebaseAuthException catch (e) {
      print('❌ Firebase Auth Error during signup: ${e.code}');
      print('📝 Error message: ${e.message}');
      throw Exception(getFirebaseAuthErrorMessage(e.code));
    } catch (e, stackTrace) {
      print('❌ Sign up unexpected error: $e');
      print('📊 Stack trace: $stackTrace');
      throw Exception('An unexpected error occurred during sign up');
    }
  }
  
  Future<void> signOut() async {
    try {
      print('🚪 FirebaseService: Signing out user');
      await auth.signOut();
      print('✅ Firebase Auth: Sign out successful');
    } catch (e) {
      print('❌ Sign out error: $e');
      throw Exception('Failed to sign out');
    }
  }
  
  Future<void> createUserDocument(String uid, Map<String, dynamic> userData) async {
    try {
      print('📝 FirebaseService: Creating user document for UID: $uid');
      
      final docData = {
        ...userData,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLoginAt': FieldValue.serverTimestamp(),
        'uid': uid,
      };
      
      await firestore.collection('users').doc(uid).set(docData, SetOptions(merge: true));
      
      print('✅ Firestore: User document created');
      print('📊 Document data keys: ${docData.keys.toList()}');
    } catch (e) {
      print('❌ Error creating user document: $e');
      throw Exception('Failed to create user profile');
    }
  }
  
  Future<Map<String, dynamic>?> getUserDocument(String uid) async {
    try {
      print('📖 FirebaseService: Getting user document for UID: $uid');
      
      final doc = await firestore.collection('users').doc(uid).get();
      
      if (doc.exists) {
        final data = doc.data();
        print('✅ Firestore: User document retrieved');
        print('📊 Document fields: ${data?.keys.toList()}');
        return data;
      } else {
        print('⚠️ Firestore: User document does not exist');
        return null;
      }
    } catch (e) {
      print('❌ Error getting user document: $e');
      return null;
    }
  }
  
  Future<void> updateUserDocument(String uid, Map<String, dynamic> data) async {
    try {
      print('📝 FirebaseService: Updating user document for UID: $uid');
      
      final updateData = {
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      await firestore.collection('users').doc(uid).update(updateData);
      
      print('✅ Firestore: User document updated');
      print('📊 Updated fields: ${updateData.keys.toList()}');
    } catch (e) {
      print('❌ Error updating user document: $e');
      throw Exception('Failed to update user profile');
    }
  }
  
  String getFirebaseAuthErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email address.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'email-already-in-use':
        return 'An account with this email already exists.';
      case 'weak-password':
        return 'Password should be at least 6 characters long.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      case 'operation-not-allowed':
        return 'Email/password accounts are not enabled.';
      default:
        return 'An error occurred. Please try again later.';
    }
  }
  
  Future<bool> checkUserExists(String email) async {
    try {
      print('🔍 FirebaseService: Checking if user exists: $email');
      
      final methods = await auth.fetchSignInMethodsForEmail(email);
      final exists = methods.isNotEmpty;
      
      print('📊 User exists: $exists (Sign-in methods: ${methods.length})');
      return exists;
    } catch (e) {
      print('❌ Error checking user existence: $e');
      return false;
    }
  }
}