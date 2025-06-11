// /home/ubuntu/lucasbeats_v4/project_android/lib/models/message_model.dart

// Placeholder Message model
class MessageModel {
  final String id;
  final String channelId;
  final String senderId;
  final String? senderName; // Optional: Name might be fetched separately
  final String content;
  final DateTime timestamp;

  MessageModel({
    required this.id,
    required this.channelId,
    required this.senderId,
    this.senderName,
    required this.content,
    required this.timestamp,
  });

  // Minimal factory constructor if needed
  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json["_id"] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      channelId: json["channelId"] ?? "unknown_channel",
      senderId: json["senderId"] ?? "unknown_sender",
      senderName: json["senderName"],
      content: json["content"] ?? "",
      timestamp: json["timestamp"] != null
          ? DateTime.tryParse(json["timestamp"])
          ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

