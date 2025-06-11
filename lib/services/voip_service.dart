// frontend/lib/services/voip_service.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import '../utils/logger.dart'; // Assuming logger is in utils

enum VoipCallState {
  idle,
  calling,
  ringing,
  connected,
  ended,
  failed
}

class VoipService with ChangeNotifier {
  VoipCallState _callState = VoipCallState.idle;
  String? _currentCallId;
  String? _currentCallee; // Callee's username
  String? _currentCaller; // Caller's username
  DateTime? _callStartTime;
  Duration _callDuration = Duration.zero;
  Timer? _durationTimer;
  final String _baseUrl = "https://beckend-ydd1.onrender.com/api/voip"; // Use the actual backend URL

  VoipCallState get callState => _callState;
  String? get currentCallId => _currentCallId;
  String? get currentCallee => _currentCallee;
  String? get currentCaller => _currentCaller;
  Duration get callDuration => _callDuration;
  bool get isInCall => _callState == VoipCallState.connected;
  bool get isRinging => _callState == VoipCallState.ringing;
  bool get isCalling => _callState == VoipCallState.calling;

  VoipService(); // Constructor

  /// Initiates an outgoing call.
  Future<bool> initiateCall(String calleeId, String calleeUsername) async {
    Logger.info('Initiating call to $calleeUsername ($calleeId)...');
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token'); // Use the correct token key

      if (token == null) {
        Logger.warning('Cannot initiate call: JWT token not found.');
        _updateCallState(VoipCallState.failed);
        return false;
      }
      
      _updateCallState(VoipCallState.calling);
      _currentCallee = calleeUsername;


      final response = await http.post(
        Uri.parse('$_baseUrl/call/initiate'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
        body: jsonEncode({
          'calleeId': calleeId
        })
      );
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        _currentCallId = data['callId'];
        // State will transition to connected upon receiving call_accepted signal
        Logger.info('Call initiated successfully with callId: $_currentCallId');
        return true;
      } else {
         Logger.error('Failed to initiate call: ${response.statusCode} - ${response.body}');
        _updateCallState(VoipCallState.failed);
        return false;
      }
    } catch (e, s) {
      Logger.error('Error initiating call', error: e, stackTrace: s);
      _updateCallState(VoipCallState.failed);
      return false;
    }
  }

  /// Accepts an incoming call.
  Future<bool> acceptCall(String callId) async {
    Logger.info('Accepting call $callId...');
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token'); // Use the correct token key

       if (token == null) {
        Logger.warning('Cannot accept call: JWT token not found.');
        _updateCallState(VoipCallState.failed);
        return false;
      }
      
      final response = await http.post(
        Uri.parse('$_baseUrl/call/accept'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
        body: jsonEncode({
          'callId': callId
        })
      );
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        _currentCallId = callId; // Ensure callId is set
        _updateCallState(VoipCallState.connected);
        _startCallTimer();
        Logger.info('Call $callId accepted successfully.');
        return true;
      } else {
         Logger.error('Failed to accept call $callId: ${response.statusCode} - ${response.body}');
        _updateCallState(VoipCallState.failed);
        return false;
      }
    } catch (e, s) {
      Logger.error('Error accepting call $callId', error: e, stackTrace: s);
      _updateCallState(VoipCallState.failed);
      return false;
    }
  }

  /// Rejects an incoming call.
  Future<bool> rejectCall(String callId) async {
    Logger.info('Rejecting call $callId...');
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token'); // Use the correct token key

      if (token == null) {
        Logger.warning('Cannot reject call: JWT token not found.');
         _updateCallState(VoipCallState.ended); // Or failed?
        return false;
      }
      
      final response = await http.post(
        Uri.parse('$_baseUrl/call/reject'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
        body: jsonEncode({
          'callId': callId
        })
      );
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        Logger.info('Call $callId rejected successfully.');
        _updateCallState(VoipCallState.ended);
        _resetCallData();
        return true;
      } else {
         Logger.error('Failed to reject call $callId: ${response.statusCode} - ${response.body}');
        // State might remain ringing or go to failed
        return false;
      }
    } catch (e, s) {
      Logger.error('Error rejecting call $callId', error: e, stackTrace: s);
      // State might remain ringing or go to failed
      return false;
    } finally {
       // Ensure state updates even on API failure to clear UI
       _updateCallState(VoipCallState.ended);
       _resetCallData();
    }
  }

  /// Ends an active call.
  Future<bool> endCall(String callId) async {
     Logger.info('Ending call $callId...');
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token'); // Use the correct token key

      if (token == null) {
        Logger.warning('Cannot end call: JWT token not found.');
         _updateCallState(VoipCallState.ended);
         _resetCallData();
        return false;
      }
      
      final response = await http.post(
        Uri.parse('$_baseUrl/call/end'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
        body: jsonEncode({
          'callId': callId
        })
      );
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        Logger.info('Call $callId ended successfully.');
        _updateCallState(VoipCallState.ended);
        _resetCallData();
        return true;
      } else {
         Logger.error('Failed to end call $callId: ${response.statusCode} - ${response.body}');
        // State might remain connected or go to failed
        return false;
      }
    } catch (e, s) {
       Logger.error('Error ending call $callId', error: e, stackTrace: s);
       // State might remain connected or go to failed
      return false;
    } finally {
       // Ensure state updates even on API failure to clear UI
       _updateCallState(VoipCallState.ended);
       _resetCallData();
    }
  }

  /// Called by the NotificationService or SocketService when an incoming call signal is received.
  void receiveIncomingCall(String callId, String callerId, String callerName) {
    Logger.info('Received incoming call from $callerName ($callerId) with callId: $callId');
    _currentCallId = callId;
    _currentCaller = callerName;
    _updateCallState(VoipCallState.ringing);
    // Note: The UI (IncomingCallOverlay) listens to this state change.
  }


  void _updateCallState(VoipCallState newState) {
     if (_callState != newState) {
        _callState = newState;
        Logger.info('VoipCallState changed to: $_callState');
        notifyListeners();
     }
  }

  void _startCallTimer() {
     Logger.info('Starting call timer.');
    _callStartTime = DateTime.now();
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _callDuration = DateTime.now().difference(_callStartTime!);
      // Only notify listeners if in connected state to avoid unnecessary rebuilds
      if (_callState == VoipCallState.connected) {
         notifyListeners();
      }
    });
  }

  void _resetCallData() {
    Logger.info('Resetting call data.');
    _currentCallId = null;
    _currentCallee = null;
    _currentCaller = null;
    _callStartTime = null;
    _callDuration = Duration.zero;
    _durationTimer?.cancel();
    _durationTimer = null; // Clear timer instance
    // No notifyListeners here, _updateCallState handles it
  }

  /// Formats the call duration into a human-readable string (MM:SS).
  String formatCallDuration() {
    final minutes = _callDuration.inMinutes;
    final seconds = _callDuration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Fetches call history from the backend API.
  Future<List<dynamic>> getCallHistory() async {
     Logger.info('Fetching call history...');
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token'); // Use the correct token key

      if (token == null) {
        Logger.warning('Cannot get call history: JWT token not found.');
        return [];
      }
      
      final response = await http.get(
        Uri.parse('$_baseUrl/call/history'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
      );
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
         // Assuming the API returns a list of calls directly or nested
         if (data is List) {
             Logger.info('Call history fetched successfully: ${data.length} items.');
            return data;
         } else if (data is Map<String, dynamic> && data.containsKey('calls') && data['calls'] is List) {
             Logger.info('Call history fetched successfully (nested): ${data['calls'].length} items.');
             return data['calls'];
         } else {
             Logger.warning('Unexpected format for call history response: $data');
             return [];
         }

      } else {
         Logger.error('Failed to fetch call history: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e, s) {
      Logger.error('Error fetching call history', error: e, stackTrace: s);
      return [];
    }
  }

  @override
  void dispose() {
    Logger.info('Disposing VoipService...');
    _durationTimer?.cancel(); // Cancel timer
    _durationTimer = null; // Clear timer instance
    // Note: Other services like SignalingService and SocketService
    // should be disposed separately if they are managed externally.
    super.dispose(); // Call dispose on ChangeNotifier
  }
}