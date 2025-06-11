
// lib/models/federation_model.dart
import 'clan_model.dart';

class Federation {
  final String id;
  final String name;
  final String adminUserId; // ID of the federation admin (e.g., 'idcloned')
  final List<Clan> clans; // List of clans within the federation
  final int maxClans; // Maximum number of clans allowed (e.g., 10)

  Federation({
    required this.id,
    required this.name,
    required this.adminUserId,
    required this.clans,
    this.maxClans = 10, // Default max clans
  });

  // Factory constructor for creating a new Federation instance from a map (e.g., JSON from API)
  factory Federation.fromJson(Map<String, dynamic> json) {
    var clanListFromJson = json['clans'] as List? ?? [];
    List<Clan> clanList = clanListFromJson.map((i) => Clan.fromJson(i)).toList();

    return Federation(
      id: json['_id'] ?? json['id'] ?? '', // Handle potential differences in ID field name
      name: json['name'] ?? 'Default Federation Name',
      adminUserId: json['adminUserId'] ?? '',
      clans: clanList,
      maxClans: json['maxClans'] ?? 10,
    );
  }

  // Method for converting a Federation instance to a map (e.g., for sending to API)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'adminUserId': adminUserId,
      'clans': clans.map((clan) => clan.toJson()).toList(),
      'maxClans': maxClans,
    };
  }

  // Helper method to check if a new clan can be added
  bool canAddClan() {
    return clans.length < maxClans;
  }
}


