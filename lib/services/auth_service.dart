import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../utils/constants.dart'; // Importar constantes (URL base da API)

class AuthService {
  final _storage = const FlutterSecureStorage();
  final String _apiUrl = AppConstants.apiBaseUrl; // Usar URL base do Render

  // Chave para armazenar o token JWT
  final String _tokenKey = 'jwt_token';

  // Obter token armazenado
  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  // Armazenar token
  Future<void> _persistToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  // Remover token (logout)
  Future<void> deleteToken() async {
    await _storage.delete(key: _tokenKey);
  }

  // Registrar com API
  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String username,
    required String gameName,
    required String whatsapp,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_apiUrl/auth/register'), // Endpoint de registro no backend
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'username': username,
          'gameName': gameName,
          'whatsapp': whatsapp,
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 201) {
        // Registro bem-sucedido, pode retornar dados do usuário ou mensagem
        return responseData;
      } else {
        // Tratar erros de registro (ex: email já existe)
        throw Exception(responseData['message'] ?? 'Falha ao registrar');
      }
    } catch (e) {
      debugPrint('Erro ao registrar usuário via API: $e');
      throw Exception('Falha ao registrar: ${e.toString()}');
    }
  }

  // Login com API
  Future<String> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_apiUrl/auth/login'), // Endpoint de login no backend
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['token'] != null) {
        // Login bem-sucedido, armazena o token
        final token = responseData['token'];
        await _persistToken(token);
        return token;
      } else {
        // Tratar erros de login
        throw Exception(responseData['message'] ?? 'Falha ao fazer login');
      }
    } catch (e) {
      debugPrint('Erro ao fazer login via API: $e');
      throw Exception('Falha ao fazer login: ${e.toString()}');
    }
  }

  // Logout (apenas remove o token localmente)
  Future<void> signOut() async {
    await deleteToken();
    // Nenhuma chamada de API necessária para logout simples baseado em token
  }

  // Obter dados do usuário atual (requer token)
  Future<UserModel?> getCurrentUserData() async {
    try {
      String? token = await getToken();
      if (token == null) {
        return null; // Não está logado
      }

      final response = await http.get(
        Uri.parse('$_apiUrl/users/me'), // Endpoint para obter perfil do usuário
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token', // Envia o token JWT
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        // Assumindo que a API retorna dados compatíveis com UserModel
        // Pode ser necessário ajustar UserModel.fromMap se a estrutura da API for diferente
        return UserModel.fromMap(responseData);
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        // Token inválido ou expirado, deslogar
        await signOut();
        return null;
      } else {
        // Outros erros
        throw Exception('Falha ao obter dados do usuário: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Erro ao obter dados do usuário via API: $e');
      // Em caso de erro (ex: rede), não deslogar automaticamente, mas retornar null
      return null;
    }
  }

  // Atualizar perfil do usuário (requer token)
  Future<void> updateUserProfile(UserModel user) async {
    try {
      String? token = await getToken();
      if (token == null) {
        throw Exception('Usuário não autenticado');
      }

      final response = await http.put(
        Uri.parse('$_apiUrl/users/me'), // Endpoint para atualizar perfil
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(user.toMap()), // Envia os dados atualizados
      );

      if (response.statusCode != 200) {
        final responseData = jsonDecode(response.body);
        throw Exception(responseData['message'] ?? 'Falha ao atualizar perfil');
      }
      // Atualização bem-sucedida
    } catch (e) {
      debugPrint('Erro ao atualizar perfil via API: $e');
      throw Exception('Falha ao atualizar perfil: ${e.toString()}');
    }
  }

  // Verificar se o usuário é administrador ou dono (requer token e endpoint específico)
  Future<bool> isAdminOrOwner() async {
    try {
      UserModel? user = await getCurrentUserData(); // Reutiliza a função que já busca o usuário
      return user != null && (user.role == 'admin' || user.role == 'owner');
    } catch (e) {
      debugPrint('Erro ao verificar permissões: $e');
      return false;
    }
  }

  // Verificar se o usuário é dono (requer token)
  Future<bool> isOwner() async {
    try {
      UserModel? user = await getCurrentUserData();
      return user != null && user.role == 'owner';
    } catch (e) {
      debugPrint('Erro ao verificar permissões de dono: $e');
      return false;
    }
  }

  // // Função _getErrorMessage removida pois os erros agora vêm da API
}

