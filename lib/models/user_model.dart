// /home/ubuntu/lucasbeats_v4/project_android/lib/models/user_model.dart
import 'package:lucasbeatsfederacao/models/role_model.dart'; // Import Role enum

class UserModel {
  final String id;
  final String username;
  final String? email;
  final String? tag;
  final String? photoUrl;
  final String? clanId;
  final DateTime? createdAt;
  final Role role;

  UserModel({
    required this.id,
    required this.username,
    this.email,
    this.tag,
    this.photoUrl,
    this.clanId,
    this.createdAt,
    // CORREÇÃO: Usar Role.clanMember como padrão
    this.role = Role.clanMember,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json["uid"] ?? json["_id"] ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      username: json["username"] ?? "Usuário Desconhecido",
      email: json["email"],
      tag: json["tag"],
      photoUrl: json["photoUrl"],
      clanId: json["clanId"],
      createdAt: json["createdAt"] != null
          ? DateTime.tryParse(json["createdAt"])
          : null,
      // CORREÇÃO: Usar Role.clanMember como fallback
      role: roleFromString(json["role"]) ?? Role.clanMember,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "username": username,
      "email": email,
      "tag": tag,
      "photoUrl": photoUrl,
      "clanId": clanId,
      "createdAt": createdAt?.toIso8601String(),
      "role": roleToString(role), // Use helper function
    };
  }
}

