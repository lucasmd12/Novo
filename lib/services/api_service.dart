import 'dart:convert'; // Required for jsonEncode/jsonDecode
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:lucasbeatsfederacao/utils/constants.dart'; // Ensure backendBaseUrl is defined here
import 'package:lucasbeatsfederacao/utils/logger.dart'; // Ensure Logger class is defined here

class ApiService {
  // CORREÇÃO: Garantir que backendBaseUrl é reconhecido (deve vir de constants.dart)
  final String _baseUrl = backendBaseUrl;
  // CORREÇÃO: Garantir que FlutterSecureStorage é reconhecido
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  Future<String?> _getToken() async {
    return await _secureStorage.read(key: 'jwt_token');
  }

  Future<Map<String, String>> _getHeaders({bool includeAuth = true}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    };
    if (includeAuth) {
      final token = await _getToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  dynamic _handleResponse(http.Response response) {
    final statusCode = response.statusCode;
    // CORREÇÃO: Garantir que Logger é reconhecido
    Logger.info('API Response Status: $statusCode, Body: ${response.body}');

    if (statusCode >= 200 && statusCode < 300) {
      if (response.body.isNotEmpty) {
        try {
          // CORREÇÃO: Usar jsonDecode como função top-level
          return jsonDecode(response.body);
        } catch (e) {
          Logger.error('Error decoding JSON response: ${e.toString()}');
          throw Exception('Failed to decode JSON response');
        }
      } else {
        return null; // Success, but no content
      }
    } else {
      // Handle non-2xx status codes
      String errorMessage = 'API Error ($statusCode)'; // Include status code by default
      try {
        final decodedBody = jsonDecode(response.body);
        if (decodedBody is Map && decodedBody.containsKey('msg')) {
          // Use backend message and add status code for context
          errorMessage = decodedBody['msg'] + " (Code: $statusCode)";
        } else if (decodedBody is Map && decodedBody.containsKey('errors')) {
          // Handle validation errors (often an array)
          final errors = decodedBody['errors'] as List;
          errorMessage = "${errors.map((e) => e['msg']).join(', ')} (Code: $statusCode)";
        } else if (response.body.isNotEmpty) {
           // Use raw body if no specific message format is found, add status code
           errorMessage = "${response.body} (Code: $statusCode)";
        }
      } catch (_) {
        // If decoding fails, use raw body if available, add status code
        errorMessage = response.body.isNotEmpty ? "${response.body} (Code: $statusCode)" : errorMessage;
      }
      Logger.error('API Error: $statusCode - $errorMessage');
      // Throw exception with detailed message including status code
      throw Exception(errorMessage);
    }
  }

  Future<dynamic> get(String endpoint, {bool requireAuth = true}) async {
    final url = Uri.parse('$_baseUrl$endpoint');
    Logger.info('API GET Request: $url');
    try {
      // CORREÇÃO: Garantir que http.get é chamado corretamente
      final response = await http.get(
        url,
        headers: await _getHeaders(includeAuth: requireAuth),
      );
      return _handleResponse(response);
    } catch (e) {
      Logger.error('API GET Error ($endpoint): ${e.toString()}');
      rethrow; // Re-throw the exception caught or thrown by _handleResponse
    }
  }

  Future<dynamic> post(String endpoint, Map<String, dynamic> data, {bool requireAuth = true}) async {
    final url = Uri.parse('$_baseUrl$endpoint');
    // CORREÇÃO: Usar jsonEncode como função top-level
    Logger.info('API POST Request: $url, Data: ${jsonEncode(data)}');
    try {
      final response = await http.post(
        url,
        headers: await _getHeaders(includeAuth: requireAuth),
        body: jsonEncode(data),
      );
      return _handleResponse(response);
    } catch (e) {
      Logger.error('API POST Error ($endpoint): ${e.toString()}');
      rethrow;
    }
  }

  Future<dynamic> put(String endpoint, Map<String, dynamic> data, {bool requireAuth = true}) async {
    final url = Uri.parse('$_baseUrl$endpoint');
    Logger.info('API PUT Request: $url, Data: ${jsonEncode(data)}');
    try {
      final response = await http.put(
        url,
        headers: await _getHeaders(includeAuth: requireAuth),
        body: jsonEncode(data),
      );
      return _handleResponse(response);
    } catch (e) {
      Logger.error('API PUT Error ($endpoint): ${e.toString()}');
      rethrow;
    }
  }

  Future<dynamic> delete(String endpoint, {bool requireAuth = true}) async {
    final url = Uri.parse('$_baseUrl$endpoint');
    Logger.info('API DELETE Request: $url');
    try {
      final response = await http.delete(
        url,
        headers: await _getHeaders(includeAuth: requireAuth),
      );
      return _handleResponse(response);
    } catch (e) {
      Logger.error('API DELETE Error ($endpoint): ${e.toString()}');
      rethrow;
    }
  }

  Future<dynamic> patch(String endpoint, Map<String, dynamic> data, {bool requireAuth = true}) async {
    final url = Uri.parse('$_baseUrl$endpoint');
    Logger.info('API PATCH Request: $url, Data: ${jsonEncode(data)}');
    try {
      final response = await http.patch(
        url,
        headers: await _getHeaders(includeAuth: requireAuth),
        body: jsonEncode(data),
      );
      return _handleResponse(response);
    } catch (e) {
      Logger.error('API PATCH Error ($endpoint): ${e.toString()}');
      rethrow;
    }
  }
}