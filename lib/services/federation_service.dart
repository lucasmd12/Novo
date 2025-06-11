// lib/services/federation_service.dart
import 'package:flutter/foundation.dart'; // For debugPrint
import 'package:lucasbeatsfederacao/models/user_model.dart';
// CORREÇÃO: Usar caminhos de pacote para todos os imports
import 'package:lucasbeatsfederacao/models/federation_model.dart';
import 'package:lucasbeatsfederacao/models/clan_model.dart';
// RoleModel não é usado neste arquivo, então não precisa importar
import 'package:lucasbeatsfederacao/services/api_service.dart'; // Corrigido para package path
import 'package:lucasbeatsfederacao/services/auth_service.dart'; // Corrigido para package path
// Logger não é usado neste arquivo, então não precisa importar

class FederationService {
  final ApiService _apiService;
  final AuthService _authService;

  FederationService(this._apiService, this._authService);

  Future<Federation?> getFederationDetails(String federationId) async {
    try {
      final response = await _apiService.get('federations/$federationId');
      if (response != null) {
        return Federation.fromJson(response);
      }
    } catch (e) {
      debugPrint('Error fetching federation details: $e');
    }
    return null;
  }

  Future<Clan?> createClan(String federationId, Map<String, dynamic> clanData) async {
    // CORREÇÃO: Garantir que UserModel é reconhecido
    final UserModel? currentUser = _authService.currentUser;
    final Federation? federation = await getFederationDetails(federationId);

    // Assumindo que o adminUserId da federação é necessário para criar clãs
    if (currentUser == null || federation == null || currentUser.id != federation.adminUserId) {
       debugPrint('Permission Denied: Only Federation Admin (${federation?.adminUserId}) can create clans. Current user ID: ${currentUser?.id}');
       return null;
    }

    // A lógica canAddClan() não existe no modelo, removida.
    // if (!federation.canAddClan()) {
    //   debugPrint('Cannot create clan: Federation max clan limit reached.');
    //   return null;
    // }

    try {
      final response = await _apiService.post('federations/$federationId/clans', clanData);
      if (response != null) {
        return Clan.fromJson(response);
      }
    } catch (e) {
      debugPrint('Error creating clan: $e');
    }
    return null;
  }

  Future<bool> deleteClan(String federationId, String clanId) async {
    final UserModel? currentUser = _authService.currentUser;
     // Usando o placeholder 'idcloned' como referência para o admin
    if (currentUser == null || currentUser.id != 'idcloned') {
       debugPrint('Permission Denied: Only Federation Admin can delete clans.');
       return false;
    }

    try {
      // Assumindo que _apiService.delete retorna true em sucesso (status 2xx sem corpo, por exemplo)
      final success = await _apiService.delete('federations/$federationId/clans/$clanId');
      return success != null; // Verificar se a resposta não é nula para sucesso
    } catch (e) {
      debugPrint('Error deleting clan: $e');
      return false;
    }
  }

  Future<bool> assignClanLeader(String federationId, String clanId, String userId) async {
    final UserModel? currentUser = _authService.currentUser;
     // Usando o placeholder 'idcloned' como referência para o admin
     if (currentUser == null || currentUser.id != 'idcloned') {
       debugPrint('Permission Denied: Only Federation Admin can assign clan leaders.');
       return false;
    }

    try {
      final response = await _apiService.put(
        'federations/$federationId/clans/$clanId/assign-leader',
        {'userId': userId}
      );
       return response != null; // Verificar se a resposta não é nula para sucesso
    } catch (e) {
      debugPrint('Error assigning clan leader: $e');
      return false;
    }
  }
}