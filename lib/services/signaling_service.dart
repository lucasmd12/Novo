// frontend/lib/services/signaling_service.dart
import 'dart:async';
import 'package:flutter/foundation.dart'; // For kDebugMode
import 'package:flutter_webrtc/flutter_webrtc.dart'; // For RTCSessionDescription, RTCIceCandidate

import 'package:lucasbeatsfederacao/services/socket_service.dart';
import 'package:lucasbeatsfederacao/utils/logger.dart';

class SignalingService extends ChangeNotifier {
  final SocketService _socketService;
  final Map<String, dynamic> _rtcConfiguration;

  // Public getter for RTC configuration
  Map<String, dynamic> get rtcConfiguration => _rtcConfiguration;

  // RTC constraints for peer connection creation
  final Map<String, dynamic> _rtcConstraints = {
    'mandatory': {},
    'optional': [
      {'DtlsSrtpKeyAgreement': true},
    ],
  };

  // Public getter for RTC constraints
  Map<String, dynamic> get rtcConstraints => _rtcConstraints;


  // Stream for signals received from the SocketService (for CallProvider)
  Stream<Map<String, dynamic>> get signalStream => _socketService.signalStream;

  // Constructor
  SignalingService(this._socketService, {required Map<String, dynamic> rtcConfiguration})
      : _rtcConfiguration = rtcConfiguration {
    _setupSocketListeners();
  }

  void _setupSocketListeners() {
    // This service primarily relays signals.
    // The CallProvider will listen to signalStream and process signals.

    // Listen for call ended events from the SocketService
    _socketService.callEndedStream.listen((data) {
      if (kDebugMode) {
        Logger.info('SignalingService received call ended: $data');
      }
      // No WebRTC cleanup here, CallProvider handles that.
    });

    // Listen to socket connection status changes (for logging or potential state management)
    _socketService.connectionStatusStream.listen((isConnected) {
      if (kDebugMode) {
        Logger.info('SignalingService socket connected status: $isConnected');
      }
      // No WebRTC cleanup here, CallProvider handles that on disconnect.
    });
  }


  // --- Public methods for sending signals to the socket ---

  // Sends an SDP offer to the other peer
  Future<void> sendOffer(String channelId, RTCSessionDescription offer) async {
    try {
      _socketService.emit('signal', {
        'type': 'offer',
        'channelId': channelId,
        'signalData': offer.toMap(),
        // TODO: Add senderId real (maybe obtained from AuthService)
      });
      if (kDebugMode) {
        Logger.info('Offer sent for channel: $channelId');
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        Logger.error('Error sending offer: $e', stackTrace: stackTrace);
      }
      // Rethrow or handle error as needed
    }
  }

  // Sends an SDP answer to the other peer
  Future<void> sendAnswer(String channelId, RTCSessionDescription answer) async {
    try {
      _socketService.emit('signal', {
        'type': 'answer',
        'channelId': channelId,
        'signalData': answer.toMap(),
        // TODO: Add senderId real (maybe obtained from AuthService)
      });
      if (kDebugMode) {
        Logger.info('Answer sent for channel: $channelId');
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        Logger.error('Error sending answer: $e', stackTrace: stackTrace);
      }
       // Rethrow or handle error as needed
    }
  }

  // Sends an ICE candidate to the other peer
  Future<void> sendIceCandidate(String channelId, RTCIceCandidate candidate) async {
    try {
      _socketService.emit('signal', {
        'type': 'candidate',
        'channelId': channelId,
        'signalData': {
          'candidate': candidate.candidate,
          'sdpMid': candidate.sdpMid,
          'sdpMLineIndex': candidate.sdpMLineIndex,
        },
        // TODO: Add senderId real (maybe obtained from AuthService)
      });
      if (kDebugMode) {
        Logger.info('ICE candidate sent for channel: $channelId');
      }
    } catch (e, stackTrace) {
       if (kDebugMode) {
        Logger.error('Error sending ICE candidate: $e', stackTrace: stackTrace);
      }
       // Rethrow or handle error as needed
    }
  }

  // Method to connect the socket (should be called by CallProvider)
  void connect() {
    _socketService.connect();
    if (kDebugMode) {
      Logger.info("SignalingService: Socket connect called.");
    }
  }

  // Method to disconnect the socket (should be called by CallProvider)
  void disconnect() {
    if (kDebugMode) {
      Logger.info("SignalingService: Disconnect called.");
    }
    _socketService.disconnect(); // Disconnect the socket
    // No WebRTC cleanup here, CallProvider handles that.
  }

  @override
  void dispose() {
    if (kDebugMode) {
        Logger.info("Disposing SignalingService");
    }
    // Note: _socketService is likely managed by the main app widget (FEDERACAOMADApp)
    // and should not be disposed here unless SignalingService is solely responsible for it.
    // Assuming SocketService lifecycle is managed externally.
    super.dispose(); // Call dispose on ChangeNotifier
  }

  // Note: createPeerConnection is now part of CallProvider as it manages the RTCPeerConnection instance.
}