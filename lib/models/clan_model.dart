// lib/models/clan_model.dart
import 'member_model.dart'; // Assuming member_model.dart will be created
import 'channel_model.dart'; // Assuming channel_model.dart will be created

class Clan {
  final String id;
  final String federationId; // ID of the federation this clan belongs to
  final String name;
  final String leaderId; // User ID of the clan leader
  final List<String> subLeaderIds; // List of User IDs for sub-leaders
  final List<Member> members; // List of members in the clan
  final String bannerImageUrl; // URL for the clan banner (PNG)
  final String tag; // Clan tag (e.g., [TAG])
  final List<TextChannel> textChannels; // Specific text channels for the clan
  final List<VoiceChannel> voiceChannels; // Specific voice channels for the clan

  Clan({
    required this.id,
    required this.federationId,
    required this.name,
    required this.leaderId,
    this.subLeaderIds = const [],
    this.members = const [],
    this.bannerImageUrl = '', // Default or placeholder banner
    this.tag = '',
    this.textChannels = const [],
    this.voiceChannels = const [],
  });

  // Factory constructor from JSON
  factory Clan.fromJson(Map<String, dynamic> json) {
    var memberListFromJson = json['members'] as List? ?? [];
    List<Member> memberList = memberListFromJson.map((i) => Member.fromJson(i)).toList();

    var textChannelListFromJson = json['textChannels'] as List? ?? [];
    List<TextChannel> textChannelList = textChannelListFromJson.map((i) => TextChannel.fromJson(i)).toList();

    var voiceChannelListFromJson = json['voiceChannels'] as List? ?? [];
    List<VoiceChannel> voiceChannelList = voiceChannelListFromJson.map((i) => VoiceChannel.fromJson(i)).toList();

    return Clan(
      id: json['_id'] ?? json['id'] ?? '',
      federationId: json['federationId'] ?? '',
      name: json['name'] ?? 'Default Clan Name',
      leaderId: json['leaderId'] ?? '',
      subLeaderIds: List<String>.from(json['subLeaderIds'] ?? []),
      members: memberList,
      bannerImageUrl: json['bannerImageUrl'] ?? '',
      tag: json['tag'] ?? '',
      textChannels: textChannelList,
      voiceChannels: voiceChannelList,
    );
  }

  // Method to convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'federationId': federationId,
      'name': name,
      'leaderId': leaderId,
      'subLeaderIds': subLeaderIds,
      'members': members.map((member) => member.toJson()).toList(),
      'bannerImageUrl': bannerImageUrl,
      'tag': tag,
      'textChannels': textChannels.map((channel) => channel.toJson()).toList(),
      'voiceChannels': voiceChannels.map((channel) => channel.toJson()).toList(),
    };
  }

  // Helper to get online members for the panel
  List<Member> get onlineMembers => members.where((m) => m.isOnline).toList();
}


