import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // FastAPI backend URL - change this to match your backend
  static const String baseUrl = 'http://localhost:8001';
  late Dio _dio;
  static ApiService? _instance;

  ApiService._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));
    
    // Add logging interceptor for debugging
    _dio.interceptors.add(LogInterceptor(
      request: true,
      requestBody: true,
      responseBody: true,
      responseHeader: false,
      error: true,
      requestHeader: true,
    ));
    
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        print('📡 API Request: ${options.method} ${options.uri}');
        print('📦 Headers: ${options.headers}');
        
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('auth_token');
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
          print('🔑 Token attached: ${token.substring(0, 20)}...');
        } else {
          print('⚠️ No auth token found');
        }
        handler.next(options);
      },
      onResponse: (response, handler) {
        print('✅ API Response [${response.statusCode}]: ${response.requestOptions.uri}');
        print('📊 Response Data: ${response.data}');
        handler.next(response);
      },
      onError: (error, handler) async {
        print('❌ API Error: ${error.type}');
        print('🔗 URL: ${error.requestOptions.uri}');
        print('📝 Method: ${error.requestOptions.method}');
        print('💥 Error Message: ${error.message}');
        
        if (error.response != null) {
          print('📊 Status Code: ${error.response!.statusCode}');
          print('📦 Response Headers: ${error.response!.headers}');
          print('📄 Response Data: ${error.response!.data}');
          
          // Handle 401 Unauthorized
          if (error.response!.statusCode == 401) {
            print('🚫 Unauthorized access - clearing token');
            final prefs = await SharedPreferences.getInstance();
            await prefs.remove('auth_token');
          }
        }
        
        handler.next(error);
      },
    ));
  }

  static ApiService get instance {
    _instance ??= ApiService._internal();
    return _instance!;
  }

  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) async {
    try {
      return await _dio.get(path, queryParameters: queryParameters);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> post(String path, {dynamic data, Map<String, dynamic>? queryParameters}) async {
    try {
      return await _dio.post(path, data: data, queryParameters: queryParameters);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> put(String path, {dynamic data}) async {
    try {
      return await _dio.put(path, data: data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> patch(String path, {dynamic data}) async {
    try {
      return await _dio.patch(path, data: data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> delete(String path) async {
    try {
      return await _dio.delete(path);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Add this method to test API connection
  Future<bool> testConnection() async {
    try {
      print('🔌 Testing API connection to $baseUrl...');
      final response = await _dio.get('/health', queryParameters: {
        'timestamp': DateTime.now().millisecondsSinceEpoch
      }).timeout(const Duration(seconds: 10));
      
      print('✅ API Connection Test Result: ${response.statusCode}');
      print('📊 API Response: ${response.data}');
      return response.statusCode == 200;
    } catch (e) {
      print('❌ API Connection Test Failed: $e');
      return false;
    }
  }

  // Add this method to get API status
  Future<Map<String, dynamic>?> getApiStatus() async {
    try {
      final response = await _dio.get('/status');
      return response.data;
    } catch (e) {
      print('❌ Failed to get API status: $e');
      return null;
    }
  }

  Exception _handleError(DioException error) {
    String errorMessage = 'Unknown error occurred';
    
    if (error.response != null) {
      final data = error.response!.data;
      if (data is Map && data['message'] != null) {
        errorMessage = data['message'].toString();
      } else if (data is String) {
        errorMessage = data;
      } else {
        errorMessage = 'Server error: ${error.response!.statusCode}';
      }
    } else {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.sendTimeout:
          errorMessage = 'Connection timeout. Please check your internet connection.';
          break;
        case DioExceptionType.badCertificate:
          errorMessage = 'Security certificate error.';
          break;
        case DioExceptionType.badResponse:
          errorMessage = 'Server returned an error: ${error.response?.statusCode}';
          break;
        case DioExceptionType.cancel:
          errorMessage = 'Request cancelled.';
          break;
        case DioExceptionType.connectionError:
          errorMessage = 'Failed to connect to server. Please check your internet connection.';
          break;
        default:
          errorMessage = 'Network error: ${error.message}';
      }
    }
    
    print('🚨 API Error Details:');
    print('   - Type: ${error.type}');
    print('   - Message: ${error.message}');
    print('   - URL: ${error.requestOptions.uri}');
    
    return Exception(errorMessage);
  }

  // Method to save token after login
  Future<void> saveAuthToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    print('💾 Auth token saved to shared preferences');
  }

  // Method to clear token on logout
  Future<void> clearAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    print('🗑️ Auth token cleared from shared preferences');
  }

  // Authentication methods for FastAPI backend
  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String name,
    String? phone,
  }) async {
    try {
      print('📝 Registering user: $email');
      final response = await post('/auth/register', data: {
        'email': email,
        'password': password,
        'name': name,
        if (phone != null) 'phone': phone,
      });
      
      print('✅ Registration successful');
      final data = response.data as Map<String, dynamic>;
      
      // Save token
      if (data['access_token'] != null) {
        await saveAuthToken(data['access_token']);
      }
      
      return data;
    } catch (e) {
      print('❌ Registration failed: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      print('🔐 Logging in user: $email');
      final response = await post('/auth/login', data: {
        'email': email,
        'password': password,
      });
      
      print('✅ Login successful');
      final data = response.data as Map<String, dynamic>;
      
      // Save token
      if (data['access_token'] != null) {
        await saveAuthToken(data['access_token']);
      }
      
      return data;
    } catch (e) {
      print('❌ Login failed: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getCurrentUser() async {
    try {
      print('👤 Getting current user info');
      final response = await get('/auth/me');
      
      print('✅ User info retrieved');
      return response.data as Map<String, dynamic>;
    } catch (e) {
      print('❌ Failed to get user info: $e');
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      print('🚪 Logging out');
      await clearAuthToken();
      print('✅ Logout successful');
    } catch (e) {
      print('❌ Logout failed: $e');
      rethrow;
    }
  }
}