import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import '../models/mission_model.dart';
import '../utils/constants.dart'; // Importar constantes (URL base da API)
import 'auth_service.dart'; // Importar AuthService para obter o token

class MissionService {
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

  // Criar nova missão
  Future<MissionModel> createMission(MissionModel mission) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse('$_apiUrl/missions'), // Endpoint POST /missions
        headers: headers,
        body: jsonEncode(mission.toMap()),
      );

      if (response.statusCode == 201) {
        return MissionModel.fromMap(jsonDecode(response.body));
      } else {
        final responseData = jsonDecode(response.body);
        throw Exception(responseData['message'] ?? 'Falha ao criar missão: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Erro ao criar missão via API: $e');
      throw Exception('Falha ao criar missão: ${e.toString()}');
    }
  }

  // Obter todas as missões (Alterado de Stream para Future)
  Future<List<MissionModel>> getMissions() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$_apiUrl/missions'), // Endpoint GET /missions
        headers: headers,
      );

      if (response.statusCode == 200) {
        List<dynamic> missionsJson = jsonDecode(response.body);
        return missionsJson.map((json) => MissionModel.fromMap(json)).toList();
      } else {
         final responseData = jsonDecode(response.body);
        throw Exception(responseData['message'] ?? 'Falha ao obter missões: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Erro ao obter missões via API: $e');
      throw Exception('Falha ao obter missões: ${e.toString()}');
    }
  }

  // Obter missões de um usuário específico (Alterado de Stream para Future)
  // Assumindo um endpoint como /users/me/missions ou /missions?userId=...
  // Vamos usar /users/me/missions como exemplo
  Future<List<MissionModel>> getUserMissions() async {
     try {
      final headers = await _getAuthHeaders();
      // Ajuste o endpoint conforme a sua API real
      final response = await http.get(
        Uri.parse('$_apiUrl/users/me/missions'), // Exemplo de endpoint
        headers: headers,
      );

      if (response.statusCode == 200) {
        List<dynamic> missionsJson = jsonDecode(response.body);
        return missionsJson.map((json) => MissionModel.fromMap(json)).toList();
      } else {
         final responseData = jsonDecode(response.body);
        throw Exception(responseData['message'] ?? 'Falha ao obter missões do usuário: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Erro ao obter missões do usuário via API: $e');
      throw Exception('Falha ao obter missões do usuário: ${e.toString()}');
    }
  }

  // Atualizar missão
  Future<MissionModel> updateMission(MissionModel mission) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.put(
        Uri.parse('$_apiUrl/missions/${mission.id}'), // Endpoint PUT /missions/:id
        headers: headers,
        body: jsonEncode(mission.toMap()),
      );

      if (response.statusCode == 200) {
         return MissionModel.fromMap(jsonDecode(response.body));
      } else {
        final responseData = jsonDecode(response.body);
        throw Exception(responseData['message'] ?? 'Falha ao atualizar missão: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Erro ao atualizar missão via API: $e');
      throw Exception('Falha ao atualizar missão: ${e.toString()}');
    }
  }

  // Excluir missão
  Future<void> deleteMission(String missionId) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.delete(
        Uri.parse('$_apiUrl/missions/$missionId'), // Endpoint DELETE /missions/:id
        headers: headers,
      );

      if (response.statusCode != 200 && response.statusCode != 204) { // 204 No Content também é sucesso
        final responseData = jsonDecode(response.body);
        throw Exception(responseData['message'] ?? 'Falha ao excluir missão: ${response.statusCode}');
      }
      // Exclusão bem-sucedida
    } catch (e) {
      debugPrint('Erro ao excluir missão via API: $e');
      throw Exception('Falha ao excluir missão: ${e.toString()}');
    }
  }

  // Atualizar status da missão
  // Assumindo um endpoint PATCH /missions/:id/status
  Future<void> updateMissionStatus(String missionId, String status) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.patch(
        Uri.parse('$_apiUrl/missions/$missionId/status'), // Exemplo de endpoint PATCH
        headers: headers,
        body: jsonEncode({'status': status}),
      );

       if (response.statusCode != 200) {
        final responseData = jsonDecode(response.body);
        throw Exception(responseData['message'] ?? 'Falha ao atualizar status da missão: ${response.statusCode}');
      }
      // Atualização bem-sucedida
    } catch (e) {
      debugPrint('Erro ao atualizar status da missão via API: $e');
      throw Exception('Falha ao atualizar status da missão: ${e.toString()}');
    }
  }

  // Atribuir missão a usuários
  // Assumindo um endpoint POST ou PUT /missions/:id/assign
  Future<void> assignMissionToUsers(String missionId, List<String> userIds) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.put( // Ou POST, dependendo da API
        Uri.parse('$_apiUrl/missions/$missionId/assign'), // Exemplo de endpoint
        headers: headers,
        body: jsonEncode({'userIds': userIds}),
      );

      if (response.statusCode != 200) {
        final responseData = jsonDecode(response.body);
        throw Exception(responseData['message'] ?? 'Falha ao atribuir missão: ${response.statusCode}');
      }
      // Atribuição bem-sucedida
    } catch (e) {
      debugPrint('Erro ao atribuir missão via API: $e');
      throw Exception('Falha ao atribuir missão: ${e.toString()}');
    }
  }
}

