
// lib/models/member_model.dart
import 'role_model.dart'; // Import the Role enum

class Member {
  final String userId;
  final String username; // Or display name
  final Role role; // Role within the clan (Leader, SubLeader, Member)
  final bool isOnline; // Status for the online members panel
  final String? avatarUrl; // Optional avatar URL

  Member({
    required this.userId,
    required this.username,
    required this.role,
    this.isOnline = false,
    this.avatarUrl,
  });

  // Factory constructor from JSON
  factory Member.fromJson(Map<String, dynamic> json) {
    return Member(
      userId: json['userId'] ?? '',
      username: json['username'] ?? 'Unknown User',
      // Use the helper function to safely convert string to Role enum
      role: roleFromString(json['role']),
      isOnline: json['isOnline'] ?? false,
      avatarUrl: json['avatarUrl'], // Can be null
    );
  }

  // Method to convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'username': username,
      // Use the helper function to convert Role enum to string
      'role': roleToString(role),
      'isOnline': isOnline,
      'avatarUrl': avatarUrl,
    };
  }
}


