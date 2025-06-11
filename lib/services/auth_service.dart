import 'package:flutter/foundation.dart'; // Para ChangeNotifier
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:lucasbeatsfederacao/models/user_model.dart';
import 'package:lucasbeatsfederacao/services/api_service.dart';
import 'package:lucasbeatsfederacao/utils/logger.dart';

class AuthService extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  bool _isAuthenticated = false;
  bool _isLoading = true;
  String? _token;
  UserModel? _currentUser;
  String? _lastErrorMessage;

  // Getters
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get token => _token;
  UserModel? get currentUser => _currentUser;
  String? get errorMessage => _lastErrorMessage;

  AuthService() {
    _checkInitialAuthStatus();
  }

  Future<void> _checkInitialAuthStatus() async {
    Logger.info("Checking initial authentication status...");
    final storedToken = await _secureStorage.read(key: "jwt_token");
    if (storedToken != null) {
      Logger.info("Token found, attempting to fetch profile...");
      _token = storedToken;
      try {
        await fetchUserProfile();
        if (_currentUser != null) {
          _isAuthenticated = true;
          Logger.info("User authenticated from stored token.");
        } else {
          await logout(); // Clear invalid token/state
        }
      } catch (e) {
        Logger.error("Failed to fetch profile with stored token: ${e.toString()}");
        _lastErrorMessage = e.toString();
        await logout(); // Clear invalid token/state
      }
    } else {
      Logger.info("No stored token found.");
      _isAuthenticated = false;
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchUserProfile() async {
    if (_token == null) {
      Logger.warning("Cannot fetch profile without a token.");
      _lastErrorMessage = "Not authenticated";
      throw Exception(_lastErrorMessage);
    }
    try {
      // Assume profile endpoint returns user data upon success
      final response = await _apiService.get("/api/auth/profile", requireAuth: true);
      // ADICIONANDO LOG AQUI
      Logger.info("AuthService: fetchUserProfile received response: $response");
      if (response != null && response is Map<String, dynamic>) {
        _currentUser = UserModel.fromJson(response);
        Logger.info("User profile fetched successfully: ${_currentUser?.username}");
        _lastErrorMessage = null;
        notifyListeners(); // Notify listeners about the updated user
      } else {
        Logger.warning("Failed to parse user profile from response.");
        _currentUser = null;
        _lastErrorMessage = "Failed to get user profile";
        throw Exception(_lastErrorMessage);
      }
    } catch (e) {
      Logger.error("Error fetching user profile: ${e.toString()}");
      _lastErrorMessage = e.toString();
      _currentUser = null;
      // Don't logout here automatically, let the caller handle it
      // await logout();
      rethrow; // Rethrow the exception to be handled by the caller
    }
  }

  // *** CORRECTION: Changed 'email' parameter to 'username' ***
  Future<bool> login(String username, String password) async {
    setLoading(true);
    _lastErrorMessage = null;
    try {
      final response = await _apiService.post(
        "/api/auth/login",
        // *** CORRECTION: Send 'username' instead of 'email' ***
        {"username": username, "password": password},
        requireAuth: false,
      );

      // ADICIONANDO LOG AQUI
      Logger.info("AuthService: login received response: $response");
      // FIM DO LOG
      if (response != null && response is Map<String, dynamic> && response.containsKey("token")) {
        final newToken = response["token"] as String?;
        if (newToken != null) {
          await _secureStorage.write(key: "jwt_token", value: newToken);
          _token = newToken;
          await fetchUserProfile(); // Fetch profile after getting token
          if (_currentUser != null) {
             setAuthenticated(true);
             Logger.info("Login successful for user: ${_currentUser?.username}");
             return true;
          } else {
            // If profile fetch fails after successful login/token retrieval
            _lastErrorMessage = "Profile fetch failed after login";
            await _clearAuthData(); // Clear partial auth state
            setAuthenticated(false);
            return false;
          }
        } else {
           _lastErrorMessage = "Token not found in login response";
           throw Exception(_lastErrorMessage); // Throw exception for unexpected response
        }
      } else {
         // Use backend message if available, otherwise generic message
         _lastErrorMessage = response?["msg"] ?? "Invalid login response format";
         throw Exception(_lastErrorMessage);
      }
    } catch (e) {
      Logger.error("Login error: ${e.toString()}");
      _lastErrorMessage = e.toString().replaceFirst("Exception: ", "");
      await _clearAuthData();
      setAuthenticated(false);
      return false;
    } finally {
      setLoading(false);
    }
  }

  Future<bool> register(String username, String password) async {
    setLoading(true);
    _lastErrorMessage = null;
    try {
      // Assume registration endpoint returns user data or just success message
      final response = await _apiService.post(
        "/api/auth/register",
        {"username": username, "password": password},
        requireAuth: false,
      );

      // ADICIONANDO LOG AQUI
      Logger.info("AuthService: register received response: $response");
      // FIM DO LOG
      // *** CORRECTION: Check for successful status code (200-299) ***
      // Instead of requiring a token, check if the request was successful.
      // We assume a successful registration means the user can now log in.
      // The API response might contain a message, user details, or nothing.
      if (response != null) { // Check if response is not null (implies success status code)
          Logger.info("Registration request successful for user: $username. User should now log in.");
          // Don't automatically authenticate or fetch profile here.
          // Registration success means the account is created, login is the next step.
          return true; // Indicate registration API call was successful
      } else {
          // If _handleResponse didn't throw an error but response is null (e.g., 204 No Content)
          // This case might need specific handling depending on API design.
          // For now, assume non-map response means success but no data.
          Logger.info("Registration request successful (no content) for user: $username. User should now log in.");
          return true;
      }

    } catch (e) {
      Logger.error("Registration error: ${e.toString()}");
      _lastErrorMessage = e.toString().replaceFirst("Exception: ", "");
      // No need to clear auth data as registration doesn't set it
      // No need to setAuthenticated(false) as it wasn't set to true
      return false;
    } finally {
      setLoading(false);
    }
  }

  Future<void> logout() async {
    Logger.info("Logging out user...");
    setLoading(true);
    await _clearAuthData();
    setAuthenticated(false);
    Logger.info("Logout successful");
    setLoading(false);
  }

  Future<void> _clearAuthData() async {
     _currentUser = null;
     _token = null;
     // Keep last error message for potential display
     // _lastErrorMessage = null;
     await _secureStorage.delete(key: "jwt_token");
  }

  void setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  void setAuthenticated(bool authenticated) {
    if (_isAuthenticated != authenticated) {
        _isAuthenticated = authenticated;
        notifyListeners();
    }
  }

  @override
  void dispose() {
    Logger.info("Disposing AuthService.");
    // Note: ApiService and FlutterSecureStorage typically do not need explicit disposal
    // in this context unless they manage heavy resources or streams that need closing.
    // Assuming their lifecycle is managed by the app framework or are stateless.
    super.dispose(); // Call dispose on ChangeNotifier
  }
}