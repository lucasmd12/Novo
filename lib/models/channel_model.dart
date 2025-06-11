
// lib/models/channel_model.dart

// Base class for channels (optional, but can be useful)
abstract class Channel {
  final String id;
  final String clanId; // ID of the clan this channel belongs to
  final String name;

  Channel({required this.id, required this.clanId, required this.name});

  Map<String, dynamic> toJson(); // Force subclasses to implement toJson
}

// Model for Text Channels specific to a clan
class TextChannel extends Channel {
  final String? topic; // Optional topic for the text channel

  TextChannel({
    required super.id,
    required super.clanId,
    required super.name,
    this.topic,
  });

  // Factory constructor from JSON
  factory TextChannel.fromJson(Map<String, dynamic> json) {
    return TextChannel(
      id: json["_id"] ?? json["id"] ?? "",
      clanId: json["clanId"] ?? "",
      name: json["name"] ?? "Unnamed Text Channel",
      topic: json["topic"],
    );
  }

  // Method to convert to JSON
  @override
  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "clanId": clanId,
      "name": name,
      "topic": topic,
      "type": "text", // Add type identifier
    };
  }
}

// Model for Voice Channels specific to a clan
class VoiceChannel extends Channel {
  // Add specific properties for voice channels if needed, e.g., bitrate, user limit
  final int? userLimit;

  VoiceChannel({
    required super.id,
    required super.clanId,
    required super.name,
    this.userLimit,
  });

  // Factory constructor from JSON
  factory VoiceChannel.fromJson(Map<String, dynamic> json) {
    return VoiceChannel(
      id: json["_id"] ?? json["id"] ?? "",
      clanId: json["clanId"] ?? "",
      name: json["name"] ?? "Unnamed Voice Channel",
      userLimit: json["userLimit"],
    );
  }

  // Method to convert to JSON
  @override
  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "clanId": clanId,
      "name": name,
      "userLimit": userLimit,
      "type": "voice", // Add type identifier
    };
  }
}


