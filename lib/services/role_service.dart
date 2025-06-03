import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import '../models/user_model.dart'; // Assuming UserModel exists and is relevant
import '../utils/constants.dart'; // Importar constantes (URL base da API)
import 'auth_service.dart'; // Importar AuthService para obter o token

class RoleService {
  final String _apiUrl = AppConstants.apiBaseUrl; // Usar URL base do Render
  final AuthService _authService = AuthService(); // Instância para obter token

  // Helper para obter headers autenticados
  Future<Map<String, String>> _getAuthHeaders() async {
    String? token = await _authService.getToken();
    if (token == null) {
      throw Exception('Usuário não autenticado');
    }
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Obter todos os usuários (requer permissão de admin/owner no backend)
  Future<List<UserModel>> getAllUsers() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$_apiUrl/users'), // Endpoint GET /users (protegido)
        headers: headers,
      );

      if (response.statusCode == 200) {
        List<dynamic> usersJson = jsonDecode(response.body);
        // Mapear para UserModel
        return usersJson.map((json) => UserModel.fromMap(json)).toList();
      } else {
        final responseData = jsonDecode(response.body);
        throw Exception(responseData['message'] ?? 'Falha ao obter usuários: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Erro ao obter usuários via API: $e');
      throw Exception('Falha ao obter usuários: ${e.toString()}');
    }
  }

  // Atualizar função do usuário (requer permissão de admin/owner no backend)
  Future<void> updateUserRole(String userId, String newRole) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.patch( // Usar PATCH ou PUT conforme a API
        Uri.parse('$_apiUrl/users/$userId/role'), // Endpoint PATCH /users/:userId/role
        headers: headers,
        body: jsonEncode({'role': newRole}),
      );

      if (response.statusCode != 200) {
        final responseData = jsonDecode(response.body);
        throw Exception(responseData['message'] ?? 'Falha ao atualizar função: ${response.statusCode}');
      }
      // Atualização bem-sucedida
    } catch (e) {
      debugPrint('Erro ao atualizar função do usuário via API: $e');
      throw Exception('Falha ao atualizar função do usuário: ${e.toString()}');
    }
  }

  // Verificar se o usuário atual tem permissão para gerenciar funções
  // Esta lógica agora reside principalmente no AuthService (isAdminOrOwner)
  // Pode ser removida daqui ou adaptada se houver um endpoint específico
  Future<bool> canManageRoles() async {
    // Reutiliza a lógica do AuthService que já busca o usuário atual
    return await _authService.isAdminOrOwner();
  }

  // Verificar se o usuário atual é o dono
  // Esta lógica agora reside principalmente no AuthService (isOwner)
  Future<bool> isOwner() async {
     // Reutiliza a lógica do AuthService que já busca o usuário atual
    return await _authService.isOwner();
  }
}

