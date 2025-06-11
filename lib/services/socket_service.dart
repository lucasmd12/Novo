// lib/services/socket_service.dart
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:lucasbeatsfederacao/utils/constants.dart'; // For backendBaseUrl
import 'package:lucasbeatsfederacao/utils/logger.dart'; // For logging

import 'package:lucasbeatsfederacao/services/auth_service.dart'; // Para injeção de dependência
import 'dart:async';
import 'package:flutter/foundation.dart'; // For kDebugMode

class SocketService {
  IO.Socket? _socket;
  final _secureStorage = const FlutterSecureStorage();
  final String _socketUrl = backendBaseUrl; // Use ws:// for local, wss:// for production usually handled by base URL
  final AuthService _authService; // Injeção de dependência

  // Stream controllers to broadcast received data
  final _messageController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;

  final _signalController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get signalStream => _signalController.stream;

  final _connectionStatusController = StreamController<bool>.broadcast();
  Stream<bool> get connectionStatusStream => _connectionStatusController.stream;

  // VoIP specific streams
  final _incomingCallController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get incomingCallStream => _incomingCallController.stream;

  final _callAcceptedController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get callAcceptedStream => _callAcceptedController.stream;

  final _callRejectedController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get callRejectedStream => _callRejectedController.stream;

  final _callEndedController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get callEndedStream => _callEndedController.stream;

  bool get isConnected => _socket?.connected ?? false;

  // Construtor com injeção de dependência
  SocketService(this._authService);

  Future<void> connect() async {
    if (_socket != null && _socket!.connected) {
      Logger.info('Socket already connected.');
      return;
    }

    final token = await _secureStorage.read(key: 'jwt_token');
    if (token == null) {
      Logger.warning('Socket connection attempt failed: No JWT token found.');
      _connectionStatusController.add(false);
      return; // Don't attempt connection without a token
    }

    if (kDebugMode) {
      Logger.info('Attempting to connect to Socket.IO server at $_socketUrl');
    }
    try {
      _socket = IO.io(_socketUrl, <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': false,
        'auth': {
          'token': token // Send JWT token for authentication
        },
         // Optional: Disable reconnection if you handle it manually
        // 'reconnection': false,
      });

      _socket!.onConnect((_) {
        if (kDebugMode) {
          Logger.info('Socket connected: ${_socket!.id}');
        }
        _connectionStatusController.add(true);
        _setupListeners(); // Setup listeners only after successful connection
      });

      _socket!.onDisconnect((reason) {
        if (kDebugMode) {
          Logger.info('Socket disconnected: $reason');
        }
        _connectionStatusController.add(false);
        // Consider implementing reconnection logic here if needed
      });

      _socket!.onConnectError((data) {
        if (kDebugMode) {
          Logger.error('Socket connection error: $data');
        }
        _connectionStatusController.add(false);
        // Handle specific auth errors if possible
        if (data.toString().contains('Authentication error')) {
          // Maybe trigger logout or token refresh via AuthService
        }
      });

      _socket!.onError((data) {
        if (kDebugMode) {
          Logger.error('Socket error: $data');
        }
        // General error handling
      });

      _socket!.connect(); // Manually initiate connection

    } catch (e) {
      if (kDebugMode) {
        Logger.error('Error initializing socket connection: ${e.toString()}');
      }
      _connectionStatusController.add(false);
    }
  }

  void _setupListeners() {
    if (_socket == null) return;

    // Listen for new messages
    _socket!.on('receive_message', (data) {
      if (kDebugMode) {
        Logger.info('Received message: $data');
      }
      if (data is Map<String, dynamic>) {
        _messageController.add(data);
      } else {
        Logger.warning('Received message data is not a Map: $data');
      }
    });

    // Listen for WebRTC signals
    _socket!.on('signal', (data) {
      if (kDebugMode) {
        Logger.info('Received signal: $data');
      }
       if (data is Map<String, dynamic>) {
        _signalController.add(data);
      } else {
        Logger.warning('Received signal data is not a Map: $data');
      }
    });

    // VoIP event listeners
    _socket!.on('incoming_call', (data) {
      if (kDebugMode) {
        Logger.info('Received incoming call: $data');
      }
      if (data is Map<String, dynamic>) {
        _incomingCallController.add(data);
      }
    });

    _socket!.on('call_accepted', (data) {
      if (kDebugMode) {
        Logger.info('Call accepted: $data');
      }
      if (data is Map<String, dynamic>) {
        _callAcceptedController.add(data);
      }
    });

    _socket!.on('call_rejected', (data) {
      if (kDebugMode) {
        Logger.info('Call rejected: $data');
      }
      if (data is Map<String, dynamic>) {
        _callRejectedController.add(data);
      }
    });

    _socket!.on('call_ended', (data) {
      if (kDebugMode) {
        Logger.info('Call ended: $data');
      }
      if (data is Map<String, dynamic>) {
        _callEndedController.add(data);
      }
    });

    // Add listeners for other custom events from server if needed (e.g., user_joined, user_left)
  }

  // --- Emit Events ---

  void emit(String event, dynamic data) {
    if (!isConnected) {
      Logger.warning('Cannot emit event \'$event\': Socket not connected.');
      return;
    }
    if (kDebugMode) {
      Logger.info('Emitting event \'$event\' with data: $data');
    }
    _socket!.emit(event, data);
  }

  void joinChannel(String channelId, Function(Map<String, dynamic>) callback) {
    if (!isConnected) {
      Logger.warning('Cannot join channel: Socket not connected.');
      callback({'status': 'error', 'message': 'Not connected'});
      return;
    }
    if (kDebugMode) {
      Logger.info('Emitting join_channel for $channelId');
    }
    _socket!.emitWithAck('join_channel', {'channelId': channelId}, ack: (response) {
      if (kDebugMode) {
        Logger.info('join_channel ack: $response');
      }
      if (response is Map<String, dynamic>) {
         callback(response);
      } else {
         callback({'status': 'error', 'message': 'Invalid response format'});
      }
    });
  }

  void sendMessage(String channelId, String content, Function(Map<String, dynamic>) callback) {
    if (!isConnected) {
      Logger.warning('Cannot send message: Socket not connected.');
       callback({'status': 'error', 'message': 'Not connected'});
      return;
    }
    if (kDebugMode) {
      Logger.info('Emitting send_message to $channelId');
    }
    _socket!.emitWithAck('send_message', {'channelId': channelId, 'content': content}, ack: (response) {
      if (kDebugMode) {
        Logger.info('send_message ack: $response');
      }
       if (response is Map<String, dynamic>) {
         callback(response);
      } else {
         callback({'status': 'error', 'message': 'Invalid response format'});
      }
    });
  }

  void sendSignal(String channelId, dynamic signalData) {
    if (!isConnected) {
      Logger.warning('Cannot send signal: Socket not connected.');
      return;
    }
    if (kDebugMode) {
      Logger.info('Emitting signal to $channelId');
    }
    _socket!.emit('signal', {'channelId': channelId, 'signalData': signalData});
  }

  void leaveChannel(String channelId) {
    if (!isConnected) {
      Logger.warning('Cannot leave channel: Socket not connected.');
      return;
    }
    if (kDebugMode) {
      Logger.info('Emitting leave_channel for $channelId');
    }
    _socket!.emit('leave_channel', {'channelId': channelId});
  }

  // VoIP specific methods
  void joinVoiceCall(String channelId) {
    if (!isConnected) {
      Logger.warning('Cannot join voice call: Socket not connected.');
      return;
    }
    if (kDebugMode) {
      Logger.info('Emitting join_voice_call for $channelId');
    }
    _socket!.emit('join_voice_call', {'channelId': channelId});
  }

  void leaveVoiceCall(String channelId) {
    if (!isConnected) {
      Logger.warning('Cannot leave voice call: Socket not connected.');
      return;
    }
    if (kDebugMode) {
      Logger.info('Emitting leave_voice_call for $channelId');
    }
    _socket!.emit('leave_voice_call', {'channelId': channelId});
  }

  void disconnect() {
    if (kDebugMode) {
      Logger.info('Disconnecting socket...');
    }
    _socket?.disconnect();
    // _socket = null; // Keep the instance to potentially reconnect, just disconnect
    _connectionStatusController.add(false);
  }

  void dispose() {
    if (kDebugMode) {
      Logger.info('Disposing SocketService...');
    }
    _messageController.close();
    _signalController.close();
    _connectionStatusController.close();
    _incomingCallController.close();
    _callAcceptedController.close();
    _callRejectedController.close();
    _callEndedController.close();
    _socket?.dispose();
    _socket = null; // Explicitly nullify on dispose
  }
}