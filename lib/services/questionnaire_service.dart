import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import '../models/questionnaire_model.dart';
import '../utils/constants.dart'; // Importar constantes (URL base da API)
import 'auth_service.dart'; // Importar AuthService para obter o token

class QuestionnaireService {
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

  // Criar novo questionário
  Future<QuestionnaireModel> createQuestionnaire(QuestionnaireModel questionnaire) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse('$_apiUrl/questionnaires'), // Endpoint POST /questionnaires
        headers: headers,
        body: jsonEncode(questionnaire.toMap()),
      );

      if (response.statusCode == 201) {
        return QuestionnaireModel.fromMap(jsonDecode(response.body));
      } else {
        final responseData = jsonDecode(response.body);
        throw Exception(responseData['message'] ?? 'Falha ao criar questionário: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Erro ao criar questionário via API: $e');
      throw Exception('Falha ao criar questionário: ${e.toString()}');
    }
  }

  // Obter todos os questionários (Alterado de Stream para Future)
  Future<List<QuestionnaireModel>> getQuestionnaires() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$_apiUrl/questionnaires'), // Endpoint GET /questionnaires
        headers: headers,
      );

      if (response.statusCode == 200) {
        List<dynamic> questionnairesJson = jsonDecode(response.body);
        return questionnairesJson.map((json) => QuestionnaireModel.fromMap(json)).toList();
      } else {
        final responseData = jsonDecode(response.body);
        throw Exception(responseData['message'] ?? 'Falha ao obter questionários: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Erro ao obter questionários via API: $e');
      throw Exception('Falha ao obter questionários: ${e.toString()}');
    }
  }

  // Obter questionários ativos (Alterado de Stream para Future)
  // Assumindo um filtro na API: GET /questionnaires?isActive=true
  Future<List<QuestionnaireModel>> getActiveQuestionnaires() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$_apiUrl/questionnaires?isActive=true'), // Endpoint GET /questionnaires com filtro
        headers: headers,
      );

      if (response.statusCode == 200) {
        List<dynamic> questionnairesJson = jsonDecode(response.body);
        return questionnairesJson.map((json) => QuestionnaireModel.fromMap(json)).toList();
      } else {
        final responseData = jsonDecode(response.body);
        throw Exception(responseData['message'] ?? 'Falha ao obter questionários ativos: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Erro ao obter questionários ativos via API: $e');
      throw Exception('Falha ao obter questionários ativos: ${e.toString()}');
    }
  }

  // Atualizar questionário
  Future<QuestionnaireModel> updateQuestionnaire(QuestionnaireModel questionnaire) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.put(
        Uri.parse('$_apiUrl/questionnaires/${questionnaire.id}'), // Endpoint PUT /questionnaires/:id
        headers: headers,
        body: jsonEncode(questionnaire.toMap()),
      );

       if (response.statusCode == 200) {
        return QuestionnaireModel.fromMap(jsonDecode(response.body));
      } else {
        final responseData = jsonDecode(response.body);
        throw Exception(responseData['message'] ?? 'Falha ao atualizar questionário: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Erro ao atualizar questionário via API: $e');
      throw Exception('Falha ao atualizar questionário: ${e.toString()}');
    }
  }

  // Excluir questionário
  Future<void> deleteQuestionnaire(String questionnaireId) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.delete(
        Uri.parse('$_apiUrl/questionnaires/$questionnaireId'), // Endpoint DELETE /questionnaires/:id
        headers: headers,
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        final responseData = jsonDecode(response.body);
        throw Exception(responseData['message'] ?? 'Falha ao excluir questionário: ${response.statusCode}');
      }
      // Exclusão bem-sucedida
    } catch (e) {
      debugPrint('Erro ao excluir questionário via API: $e');
      throw Exception('Falha ao excluir questionário: ${e.toString()}');
    }
  }

  // Ativar/desativar questionário
  // Assumindo um endpoint PATCH /questionnaires/:id/status ou similar
  Future<void> toggleQuestionnaireStatus(String questionnaireId, bool isActive) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.patch(
        Uri.parse('$_apiUrl/questionnaires/$questionnaireId/status'), // Exemplo de endpoint PATCH
        headers: headers,
        body: jsonEncode({'isActive': isActive}),
      );

      if (response.statusCode != 200) {
        final responseData = jsonDecode(response.body);
        throw Exception(responseData['message'] ?? 'Falha ao alterar status do questionário: ${response.statusCode}');
      }
      // Atualização bem-sucedida
    } catch (e) {
      debugPrint('Erro ao alterar status do questionário via API: $e');
      throw Exception('Falha ao alterar status do questionário: ${e.toString()}');
    }
  }

  // Enviar resposta de questionário
  // Assumindo um endpoint POST /questionnaires/:id/responses
  Future<void> submitQuestionnaireResponse(String questionnaireId, Map<String, dynamic> responses) async {
    try {
      final headers = await _getAuthHeaders();
      // O userId provavelmente será extraído do token JWT no backend
      final response = await http.post(
        Uri.parse('$_apiUrl/questionnaires/$questionnaireId/responses'), // Exemplo de endpoint
        headers: headers,
        body: jsonEncode({'responses': responses}),
      );

      if (response.statusCode != 201) {
         final responseData = jsonDecode(response.body);
        throw Exception(responseData['message'] ?? 'Falha ao enviar resposta: ${response.statusCode}');
      }
      // Resposta enviada com sucesso
    } catch (e) {
      debugPrint('Erro ao enviar resposta de questionário via API: $e');
      throw Exception('Falha ao enviar resposta de questionário: ${e.toString()}');
    }
  }
}

