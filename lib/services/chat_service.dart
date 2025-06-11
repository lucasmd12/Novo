// lib/services/chat_service.dart
import 'package:flutter/foundation.dart'; // Import foundation for ChangeNotifier
import 'package:lucasbeatsfederacao/models/message_model.dart'; // Ensure this path is correct
import 'package:lucasbeatsfederacao/utils/logger.dart'; // Ensure this path is correct

/// Service to handle chat operations (simulated).
class ChatService extends ChangeNotifier {
  // Stores messages per channel. Key: channelId, Value: List of messages
  final Map<String, List<MessageModel>> _messages = {};

  // Simulate sending a message
  Future<void> sendMessage(String channelId, String content) async {
    Logger.info("[ChatService] Sending message to $channelId: $content");

    // Create a new message model. Replace placeholders with actual logic.
    final newMessage = MessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(), // Unique ID for simulation
      channelId: channelId,
      senderId: "current_user_id_placeholder", // TODO: Replace with actual user ID
      senderName: "You (Placeholder)", // TODO: Replace with actual user name
      content: content,
      timestamp: DateTime.now(),
    );

    // Add message to the map
    if (_messages[channelId] == null) {
      _messages[channelId] = [];
    }
    _messages[channelId]!.add(newMessage);

    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 100));

    // Notify widgets listening to this service that data has changed
    notifyListeners();
  }

  // Get messages for a specific channel
  List<MessageModel> getMessagesForChannel(String channelId) {
    Logger.info("[ChatService] Getting messages for $channelId");

    // If no messages exist for the channel, add some initial simulated messages
    if (_messages[channelId] == null || _messages[channelId]!.isEmpty) {
       _messages[channelId] = [
         MessageModel(id: "1", channelId: channelId, senderId: "other_user_1", senderName: "Friend A", content: "Hey there!", timestamp: DateTime.now().subtract(const Duration(minutes: 10))),
         MessageModel(id: "2", channelId: channelId, senderId: "current_user_id_placeholder", senderName: "You (Placeholder)", content: "Hi! How are you?", timestamp: DateTime.now().subtract(const Duration(minutes: 8))),
         MessageModel(id: "3", channelId: channelId, senderId: "other_user_2", senderName: "Friend B", content: "What's up?", timestamp: DateTime.now().subtract(const Duration(minutes: 5))),
       ];
       Logger.info("Added simulated messages for channel $channelId.");
    }

    // Return the list of messages for the channel. Use ?? [] for null safety.
    return _messages[channelId] ?? [];
  }

  // Placeholder method to simulate updating user presence status
  Future<void> atualizarStatusPresenca(String userId, bool isOnline) async {
    Logger.info("[ChatService Placeholder] Updating presence status for user $userId to ${isOnline ? 'online' : 'offline'}.");
    // In a real application, this would interact with a backend or WebSocket service
    await Future.delayed(const Duration(milliseconds: 50)); // Simulate async operation
  }

  // dispose method to clean up resources if needed (e.g., close streams)
  // Inherited from ChangeNotifier, override if specific cleanup is required.
  @override
  void dispose() {
    Logger.info("Disposing ChatService.");
    // Close any streams or cancel subscriptions here if they were created in this service.
    super.dispose(); // Always call super.dispose() last
  }
}