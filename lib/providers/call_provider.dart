import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:lucasbeatsfederacao/services/auth_service.dart';
import 'package:lucasbeatsfederacao/services/socket_service.dart';
import 'package:lucasbeatsfederacao/services/signaling_service.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:lucasbeatsfederacao/utils/logger.dart';

enum CallState { idle, joining, leaving, connected, error }

class CallProvider with ChangeNotifier {
  // --- Dependencies ---
  final AuthService _authService;
  final SocketService _socketService; // Kept for potential direct use if needed, though signaling is via SignalingService
  final SignalingService _signalingService;

  // --- WebRTC Connection State ---
  final Map<String, RTCPeerConnection> _peerConnections = {};
  final Map<String, MediaStream> _remoteStreams = {};
  MediaStream? _localStream;
  String? _currentChannelId;
  CallState _callState = CallState.idle;
  String? _errorMessage;
  bool _isMicMuted = false;
  bool _isSpeakerOn = true;

  // --- Getters ---
  CallState get callState => _callState;
  MediaStream? get localStream => _localStream;
  Map<String, MediaStream> get remoteStreams => _remoteStreams;
  String? get errorMessage => _errorMessage;
  bool get isMicMuted => _isMicMuted;
  bool get isSpeakerOn => _isSpeakerOn;
  String? get currentChannelId => _currentChannelId;

  StreamSubscription? _signalSubscription;

  // Constructor
  CallProvider({
    required AuthService authService,
    required SocketService socketService,
    required SignalingService signalingService,
  })  : _authService = authService,
        _socketService = socketService,
        _signalingService = signalingService {
    _initialize();
  }

  void _initialize() {
    Logger.info("CallProvider initialized.");
    // Listeners for SignalingService signal stream will be configured in joinChannel
  }

  @override
  void dispose() {
    Logger.info('Disposing CallProvider...');
    _cleanUpCurrentCall(isDisposing: true);
    super.dispose();
  }

  Future<void> _cleanUpCurrentCall({bool isDisposing = false}) async {
    Logger.info('Cleaning up current call resources...');
    if (_callState != CallState.leaving && _callState != CallState.idle) {
      _updateCallState(CallState.leaving);
    }

    _cancelSignalingSubscriptions();

    await _closeLocalMediaStream();

    // Close all active peer connections
    await Future.wait(_peerConnections.entries.map((entry) async {
      await _closePeerConnection(entry.key, notify: false);
    }));
    _peerConnections.clear();
    _remoteStreams.clear();

    if (!isDisposing) {
      // Disconnect the SignalingService (which in turn disconnects the socket)
      _signalingService.disconnect();
    }

    _currentChannelId = null;
    _updateCallState(CallState.idle);
    Logger.info('Call cleanup complete.');
    if (!isDisposing) notifyListeners();
  }

  void _cancelSignalingSubscriptions() {
    _signalSubscription?.cancel();
    _signalSubscription = null;
    Logger.info('Signaling subscriptions cancelled.');
  }

  Future<void> joinChannel(String channelId) async {
    if (_callState != CallState.idle) {
      Logger.warning('Cannot join channel: State is $_callState.');
      return;
    }
    final currentUser = _authService.currentUser;
    if (currentUser == null) {
      Logger.error('Cannot join channel: User not logged in.');
      _updateCallState(CallState.error, 'Usuário não autenticado.');
      return;
    }

    Logger.info('Joining channel: $channelId');
    _updateCallState(CallState.joining);
    _currentChannelId = channelId;

    try {
      // Get local media stream
      await _getLocalMedia();

      // Configure listener for SignalingService signal stream BEFORE connecting
      _listenToSignalingEvents();

      // Connect the SignalingService (which connects the socket and can notify peers)
      _signalingService.connect();

      _updateCallState(CallState.connected);
      Logger.info('Successfully joined channel: $channelId');

      // Note: Initial connection/offer sending to existing peers should happen
      // based on a signal from the backend upon joining, or a direct mechanism
      // to get existing peers. This is handled in _handleSignal for 'peer_joined'.

    } catch (e, stackTrace) {
      Logger.error('Error joining channel $channelId',
          error: e, stackTrace: stackTrace);
      _updateCallState(CallState.error, 'Erro ao entrar no canal.');
      await _cleanUpCurrentCall();
    }
  }

  Future<void> leaveChannel() async {
    if (_callState == CallState.idle || _callState == CallState.leaving) {
      Logger.info('Already idle or leaving channel.');
      return;
    }
    Logger.info('Leaving channel: $_currentChannelId');
    // TODO: Notify the SignalingService/SocketService that this peer is leaving the channel
    // _signalingService.leaveChannel(_currentChannelId!); // Example, if exists
    await _cleanUpCurrentCall();
  }

  // --- Signal Handling (Receiving Signals) ---
  void _listenToSignalingEvents() {
    final currentUser = _authService.currentUser;
    if (currentUser == null) {
      Logger.error("Cannot listen to signaling events: User not logged in.");
      return;
    }

    _cancelSignalingSubscriptions(); // Cancel old listeners before configuring new ones

    // Listen to the signal stream from SignalingService
    _signalSubscription = _signalingService.signalStream.listen(
      _handleSignal, // Process the received signal
      onError: (error) {
        Logger.error('Error in signal stream: $error');
        _updateCallState(CallState.error, 'Erro na comunicação com o servidor.');
        leaveChannel(); // Leave channel in case of a severe stream error
      },
      onDone: () {
        Logger.info('Signal stream closed.');
        if (_callState != CallState.idle) {
             _updateCallState(CallState.error, 'Conexão com servidor encerrada.');
            leaveChannel(); // Leave channel if stream closes unexpectedly
        }
      },
    );
    Logger.info('Listening to signaling events.');
  }

  // Processes the signals received from SignalingService
  Future<void> _handleSignal(Map<String, dynamic> signal) async {
    Logger.info("Received signal: ${signal['type']}");
    final senderId = signal['senderId'] as String?;
    if (senderId == null || senderId == _authService.currentUser?.id) {
      // Ignore signals without senderId or sent by self
      return;
    }

    final channelId = signal['channelId'] as String?;
     if (channelId == null || channelId != _currentChannelId) {
         Logger.warning('Received signal for different or unknown channel. Ignoring.');
         return; // Ignore signals for channels different from the current one
     }


    try {
      // Process the signal based on the type
      switch (signal['type']) {
        case 'offer':
          await _handleOffer(senderId, signal);
          break;
        case 'answer':
          await _handleAnswer(senderId, signal);
          break;
        case 'candidate':
          await _handleCandidate(senderId, signal);
          break;
        case 'peer_joined': // Handle peer_joined signal if backend sends it
            final joinedPeerId = signal['peerId'] as String?;
            if (joinedPeerId != null && joinedPeerId != _authService.currentUser?.id) {
                 Logger.info('Peer $joinedPeerId joined via signal. Initiating connection.');
                _initiateConnection(joinedPeerId);
            }
            break;
        case 'peer_left': // Handle peer_left signal if backend sends it
             final leftPeerId = signal['peerId'] as String?;
             if (leftPeerId != null && leftPeerId != _authService.currentUser?.id) {
                 Logger.info('Peer $leftPeerId left via signal. Closing connection.');
                _closePeerConnection(leftPeerId);
            }
            break;
        default:
          Logger.warning("Received unknown signal type: ${signal['type']}");
          break;
      }
    } catch (e, stackTrace) {
      Logger.error('Error handling signal from $senderId',
          error: e, stackTrace: stackTrace);
      // Depending on the error, it might be necessary to close the peer connection
      // _closePeerConnection(senderId);
    }
  }

  // --- Peer Connection Management ---

  // Creates a new PeerConnection for a specific peer
  Future<RTCPeerConnection> _createPeerConnection(String peerId) async {
    Logger.info("Creating Peer Connection for $peerId.");

     // Use the public getters from SignalingService for RTC configuration and constraints
     final Map<String, dynamic> rtcConfiguration = _signalingService.rtcConfiguration;
     final Map<String, dynamic> rtcConstraints = _signalingService.rtcConstraints;

    RTCPeerConnection pc =
        await createPeerConnection(rtcConfiguration, rtcConstraints);

    // Configure listeners for this specific PeerConnection
    _registerPeerConnectionListeners(pc, peerId);

    // Add local stream tracks to the PeerConnection if already available
    if (_localStream != null) {
      _localStream!.getTracks().forEach((track) {
        pc.addTrack(track, _localStream!);
        Logger.info('Local track ${track.kind} added to PC for $peerId');
      });
    } else {
       Logger.warning('Local stream is null when creating PC for $peerId. Will add when available.');
       // TODO: Handle the case where the local stream is not ready yet.
       // It might be necessary to add tracks after the local stream is obtained.
    }


    return pc;
  }

  // Registers listeners for a specific PeerConnection
  void _registerPeerConnectionListeners(
      RTCPeerConnection pc, String peerId) {
    Logger.info("Registering listeners for Peer Connection $peerId.");

    // Listener for locally generated ICE candidates
    pc.onIceCandidate = (RTCIceCandidate candidate) {
      Logger.info('onIceCandidate for $peerId: ${candidate.candidate}');
      if (_currentChannelId != null) {
        // Send the generated ICE candidate via SignalingService
        _signalingService.sendIceCandidate(_currentChannelId!, candidate);
      }
    };

    // Listener for received remote streams/tracks
    pc.onTrack = (RTCTrackEvent event) {
      Logger.info('onTrack received from $peerId - Kind: ${event.track.kind}');
      if (event.streams.isNotEmpty && event.track.kind == 'audio') {
        // Add the remote stream to the list of remote streams
        _remoteStreams[peerId] = event.streams[0];
        Logger.info('Remote stream received from $peerId');
        notifyListeners(); // Notify UI about the new remote stream
      }
    };

    // Listener for PeerConnection connection state changes
    pc.onConnectionState = (state) {
        Logger.info('Peer connection state changed for $peerId: $state');
        if (state == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected ||
            state == RTCPeerConnectionState.RTCPeerConnectionStateFailed ||
            state == RTCPeerConnectionState.RTCPeerConnectionStateClosed) {
            Logger.warning('Peer connection for $peerId disconnected/failed/closed.');
            _closePeerConnection(peerId); // Close the connection with the peer
        }
    };

     // Listener for ICE connection state changes
     pc.onIceConnectionState = (state) {
        Logger.info('ICE connection state changed for $peerId: $state');
    };

  }

  // Sets the remote description (offer or answer) on the PeerConnection
  Future<void> _setRemoteDescription(
      String peerId, RTCSessionDescription description) async {
    Logger.info("Setting remote description for $peerId.");
    final pc = await _getOrCreatePeerConnection(peerId);
    await pc.setRemoteDescription(description);
  }

  // Adds a received ICE candidate on the PeerConnection
  Future<void> _addCandidate(String peerId, RTCIceCandidate candidate) async {
    Logger.info("Adding ICE candidate for $peerId.");
    final pc = _peerConnections[peerId];
    if (pc != null) {
      await pc.addCandidate(candidate);
    } else {
        Logger.warning('Peer connection not found for $peerId when adding candidate. Candidate ignored.');
    }
  }

  // Gets an existing PeerConnection for a peer or creates a new one
  Future<RTCPeerConnection> _getOrCreatePeerConnection(String peerId) async {
    RTCPeerConnection? pc = _peerConnections[peerId];
    if (pc != null) {
      return pc;
    }

    Logger.info('Creating new Peer Connection for peer: $peerId');
    // Create a new PeerConnection and store it
    pc = await _createPeerConnection(peerId);
    _peerConnections[peerId] = pc;

    return pc;
  }

  // Initiates the connection process with a new peer (usually by sending an offer)
  Future<void> _initiateConnection(String peerId) async {
    if (_peerConnections.containsKey(peerId)) {
      Logger.info('Connection already exists or being initiated for peer $peerId');
      return;
    }
    try {
      // Create and send the offer to the new peer
      await _createOffer(peerId);
    } catch (e, stackTrace) {
      Logger.error('Error initiating connection with $peerId',
          error: e, stackTrace: stackTrace);
      _closePeerConnection(peerId); // Close the connection in case of initialization error
    }
  }


  // Closes the PeerConnection with a specific peer and cleans up associated resources
  Future<void> _closePeerConnection(String peerId, {bool notify = true}) async {
    Logger.info("Closing peer connection for $peerId.");
    final pc = _peerConnections.remove(peerId); // Remove from the list of peer connections
    if (pc != null) {
      await pc.close(); // Close the PeerConnection
      Logger.info('Peer connection closed and removed for $peerId');
    }
    final stream = _remoteStreams.remove(peerId); // Remove the associated remote stream
    if (stream != null) {
      await stream.dispose(); // Dispose the remote stream
      Logger.info('Remote stream disposed for $peerId');
    }
    if (notify) notifyListeners(); // Notify listeners about the change
  }


  // --- Sending Signals (Interacting with SignalingService) ---

  // Creates and sends an SDP offer
  Future<void> _createOffer(String peerId) async {
    Logger.info("Creating offer for $peerId.");
    final pc = await _getOrCreatePeerConnection(peerId);
    final offer = await pc.createOffer({'offerToReceiveAudio': 1}); // Create offer (audio only)
    await pc.setLocalDescription(offer); // Set local description

    if (_currentChannelId != null) {
      // Send the offer via SignalingService
      _signalingService.sendOffer(_currentChannelId!, offer);
    }
  }

  // Creates and sends an SDP answer
  Future<void> _createAnswer(
      String peerId, RTCSessionDescription offer) async {
    Logger.info("Creating answer for $peerId.");
    final pc = await _getOrCreatePeerConnection(peerId);
    await pc.setRemoteDescription(offer); // Set received offer as remote description

    final answer = await pc.createAnswer({'offerToReceiveAudio': 1}); // Create answer
    await pc.setLocalDescription(answer); // Set answer as local description

    if (_currentChannelId != null) {
      // Send the answer via SignalingService
       _signalingService.sendAnswer(_currentChannelId!, answer);
    }
  }


  // --- Handling Received Signals ---

  // Handles a received SDP offer
  Future<void> _handleOffer(String senderId, Map<String, dynamic> signalData) async {
    final sdpData = signalData['signalData'] as Map?;
    if (sdpData == null) {
       Logger.warning('Offer signal data is null from $senderId');
       return;
    }

    Logger.info('Received offer from $senderId');
    try {
      final offer = RTCSessionDescription(sdpData['sdp'], sdpData['type']);
      // After receiving the offer, create and send the answer
      await _createAnswer(senderId, offer);
    } catch (e, stackTrace) {
      Logger.error('Error handling offer from $senderId',
          error: e, stackTrace: stackTrace);
       _closePeerConnection(senderId); // Close connection if there's an error handling the offer
    }
  }

  // Handles a received SDP answer
  Future<void> _handleAnswer(String senderId, Map<String, dynamic> signalData) async {
    final sdpData = signalData['signalData'] as Map?;
     if (sdpData == null) {
       Logger.warning('Answer signal data is null from $senderId');
       return;
    }

    Logger.info('Received answer from $senderId');
    try {
      final answer = RTCSessionDescription(sdpData['sdp'], sdpData['type']);
      // Set the received answer as the remote description
      await _setRemoteDescription(senderId, answer);
    } catch (e, stackTrace) {
      Logger.error('Error handling answer from $senderId',
          error: e, stackTrace: stackTrace);
      _closePeerConnection(senderId); // Close connection if there's an error handling the answer
    }
  }

  // Handles a received ICE candidate
  Future<void> _handleCandidate(String senderId, Map<String, dynamic> signalData) async {
    final candidateData = signalData['signalData'] as Map?;
    if (candidateData == null) {
       Logger.warning('Candidate signal data is null from $senderId');
       return;
    }

    Logger.info('Received ICE candidate from $senderId');
    try {
      final candidate = RTCIceCandidate(
        candidateData['candidate'],
        candidateData['sdpMid'],
        candidateData['sdpMLineIndex'],
      );
      // Add the received ICE candidate on the PeerConnection
      await _addCandidate(senderId, candidate);
    } catch (e, stackTrace) {
      Logger.error('Error handling candidate from $senderId',
          error: e, stackTrace: stackTrace);
      // Generally, an error in a single candidate doesn't require closing the entire connection
    }
  }


  // --- Media Control ---

  // Gets the local media stream (microphone)
  Future<void> _getLocalMedia() async {
    if (_localStream != null) return; // Already have the local stream
    Logger.info('Getting local media stream...');
    try {
      final Map<String, dynamic> mediaConstraints = {
        'audio': true, // Request audio
        'video': false // Do not request video for voice call
      };
      _localStream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
      if (_localStream!.getAudioTracks().isNotEmpty) {
        // Configure initial microphone state
        _localStream!.getAudioTracks()[0].enabled = !_isMicMuted;
      }
      Logger.info('Local media stream obtained: ${_localStream!.id}');
      notifyListeners(); // Notify listeners that the local stream is ready
    } catch (e, stackTrace) {
      Logger.error('Error getting local media', error: e, stackTrace: stackTrace);
      _updateCallState(CallState.error, 'Erro ao acessar microfone.');
      _localStream = null; // Ensure local stream is null in case of error
      rethrow; // Re-throw the exception to be handled by joinChannel
    }
  }

  // Closes and disposes the local media stream
  Future<void> _closeLocalMediaStream() async {
    Logger.info("Closing local media stream.");
    if (_localStream != null) {
      await _localStream!.dispose();
      _localStream = null;
      Logger.info('Local stream stopped and disposed.');
      notifyListeners(); // Notify listeners that the local stream has been removed
    }
  }


  // Toggles the muted/unmuted state of the local microphone
  void toggleMicMute() {
    _isMicMuted = !_isMicMuted;
    if (_localStream != null && _localStream!.getAudioTracks().isNotEmpty) {
      _localStream!.getAudioTracks()[0].enabled = !_isMicMuted; // Enable/disable the audio track
      Logger.info('Microphone ${!_isMicMuted ? "unmuted" : "muted"}\'');
    }
    notifyListeners(); // Notify UI about the change in microphone state
  }

  // Toggles the use of the speakerphone (platform and flutter_webrtc dependent)
  void toggleSpeaker() {
    _isSpeakerOn = !_isSpeakerOn;
    // Note: Speakerphone control is platform specific.
    // The flutter_webrtc package provides Helper.setSpeakerphoneOn for this.
    Helper.setSpeakerphoneOn(_isSpeakerOn);
    Logger.info('Speaker ${_isSpeakerOn ? "on" : "off"}\'');
    notifyListeners(); // Notify UI about the change in speakerphone state
  }

  // --- Helpers ---

  // Updates the call state and notifies listeners
  void _updateCallState(CallState newState, [String? message]) {
    if (_callState != newState) {
      _callState = newState;
      _errorMessage = message;
      Logger.info(
          'Call state changed: $newState ${message != null ? "($message)" : ""}\'');
      notifyListeners();
    }
  }
}