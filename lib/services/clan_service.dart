// lib/services/clan_service.dart
import 'package:lucasbeatsfederacao/models/chat_channel_model.dart';
import 'package:lucasbeatsfederacao/models/user_model.dart';
import 'package:lucasbeatsfederacao/models/clan_model.dart';
import 'package:lucasbeatsfederacao/models/member_model.dart';
import 'package:lucasbeatsfederacao/models/role_model.dart';
import 'package:lucasbeatsfederacao/services/api_service.dart';
import 'package:lucasbeatsfederacao/services/auth_service.dart';
import 'package:lucasbeatsfederacao/utils/logger.dart';

class ClanService {
  final ApiService _apiService;
  final AuthService _authService;

  ClanService(this._apiService, this._authService);

  Future<Clan?> getClanDetails(String clanId) async {
    try {
      final response = await _apiService.get('clans/$clanId');
      if (response != null) {
        return Clan.fromJson(response);
      }
    } catch (e) {
      Logger.error('Error fetching clan details for $clanId: $e');
    }
    return null;
  }

  Future<List<Member>> getClanMembers(String clanId) async {
    try {
      final response = await _apiService.get('clans/$clanId/members');
      if (response != null && response is List) {
        return response.map((data) => Member.fromJson(data)).toList();
      }
    } catch (e) {
      Logger.error('Error fetching clan members for $clanId: $e');
    }
    return [];
  }

  Future<List<ChatChannelModel>> getClanChannels(String clanId, {String type = 'text'}) async {
    final UserModel? currentUser = _authService.currentUser;
    if (currentUser == null || currentUser.clanId != clanId) {
        Logger.warning('Permission Denied [Get Channels]: User not part of the clan or not logged in.');
        return [];
    }

    try {
      final endpoint = 'clans/$clanId/channels?type=$type';
      final response = await _apiService.get(endpoint);
      if (response != null && response is List) {
        final channels = response.map((data) => ChatChannelModel.fromJson(data)).toList();
        Logger.info('Fetched ${channels.length} $type channels for clan $clanId.');
        return channels;
      } else {
        Logger.warning('Unexpected response format when fetching $type channels for clan $clanId: $response');
      }
    } catch (e) {
      Logger.error('Error fetching $type channels for clan $clanId: $e');
    }
    return [];
  }

  Future<bool> addMember(String clanId, String userIdToAdd) async {
    final UserModel? currentUser = _authService.currentUser;
    final Clan? clan = await getClanDetails(clanId);
    if (currentUser == null || clan == null || !(currentUser.id == clan.leaderId || clan.subLeaderIds.contains(currentUser.id))) {
      Logger.warning('Permission Denied [Add Member]: Only Leader/SubLeader can add members.');
      return false;
    }

    try {
      final response = await _apiService.post('clans/$clanId/members', {'userId': userIdToAdd});
      return response != null;
    } catch (e) {
      Logger.error('Error adding member $userIdToAdd to clan $clanId: $e');
      return false;
    }
  }

  Future<bool> removeMember(String clanId, String userIdToRemove) async {
    final UserModel? currentUser = _authService.currentUser;
    final Clan? clan = await getClanDetails(clanId);

    if (currentUser == null || clan == null) {
      Logger.warning("Permission Denied [Remove Member]: Cannot verify user or clan.");
      return false;
    }

    bool isSelfRemoval = userIdToRemove == currentUser.id;
    bool isLeaderOrSub = currentUser.id == clan.leaderId || clan.subLeaderIds.contains(currentUser.id);
    bool isRemovingLeader = userIdToRemove == clan.leaderId;
    bool canRemove = isSelfRemoval || (isLeaderOrSub && !isRemovingLeader);

    if (!canRemove) {
       Logger.warning("Permission Denied [Remove Member]: Action not allowed.");
       return false;
    }

    try {
      await _apiService.delete('clans/$clanId/members/$userIdToRemove');
      return true;
    } catch (e) {
      Logger.error('Error removing member $userIdToRemove from clan $clanId: $e');
      return false;
    }
  }

  Future<bool> updateMemberRole(String clanId, String userId, Role newRole) async {
    if (newRole == Role.federationAdmin || newRole == Role.guest) {
        Logger.warning("Invalid role assignment.");
        return false;
    }

    final UserModel? currentUser = _authService.currentUser;
    final Clan? clan = await getClanDetails(clanId);
    if (currentUser == null || clan == null || currentUser.id != clan.leaderId) {
      Logger.warning("Permission Denied [Update Role]: Only Leader can change roles.");
      return false;
    }
    if (userId == clan.leaderId) {
       Logger.warning("Cannot change the leader's role directly via this method.");
       return false;
    }
    try {
      final response = await _apiService.put(
        'clans/$clanId/members/$userId/role',
        {'role': roleToString(newRole)}
      );
      return response != null;
    } catch (e) {
      Logger.error('Error updating role for member $userId in clan $clanId: $e');
      return false;
    }
  }

  Future<Clan?> updateClanDetails(String clanId, {String? name, String? bannerImageUrl, String? tag}) async {
    final UserModel? currentUser = _authService.currentUser;
    final Clan? clan = await getClanDetails(clanId);
    if (currentUser == null || clan == null || !(currentUser.id == clan.leaderId || clan.subLeaderIds.contains(currentUser.id))) {
      Logger.warning('Permission Denied [Update Clan Details]: Only Leader/SubLeader can update details.');
      return null;
    }

    Map<String, dynamic> dataToUpdate = {};
    if (name != null) dataToUpdate['name'] = name;
    if (bannerImageUrl != null) dataToUpdate['bannerImageUrl'] = bannerImageUrl;
    if (tag != null) dataToUpdate['tag'] = tag;

    if (dataToUpdate.isEmpty) {
      Logger.info('No details provided to update for clan $clanId.');
      return clan;
    }

    try {
      final response = await _apiService.put('clans/$clanId', dataToUpdate);
      if (response != null) {
        return Clan.fromJson(response);
      }
    } catch (e) {
      Logger.error('Error updating details for clan $clanId: $e');
    }
    return null;
  }
}