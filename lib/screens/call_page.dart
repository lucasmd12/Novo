import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucasbeatsfederacao/providers/call_provider.dart';
import 'package:lucasbeatsfederacao/services/voip_service.dart';

class CallPage extends StatefulWidget {
  final String? contactName;
  final String? contactId;
  final bool isIncomingCall;

  const CallPage({
    super.key,
    this.contactName,
    this.contactId,
    this.isIncomingCall = false,
  });

  @override
  State<CallPage> createState() => _CallPageState();
}

class _CallPageState extends State<CallPage> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Consumer2<CallProvider, VoipService>(
        builder: (context, callProvider, voipService, child) {
          return SafeArea(
            child: Column(
              children: [
                // Header com informações da chamada
                _buildCallHeader(voipService),

                // Avatar e informações do contato
                Expanded(
                  flex: 3,
                  child: _buildContactInfo(voipService),
                ),

                // Status da chamada
                _buildCallStatus(voipService),

                // Controles da chamada
                Expanded(
                  flex: 2,
                  child: _buildCallControls(context, callProvider, voipService),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCallHeader(VoipService voipService) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Assuming back button should just pop. Adjust if more complex logic needed.
          GestureDetector(
            onTap: () {
              // Optionally, handle leaving the call before popping
              // if (voipService.isInCall && voipService.currentCallId != null) {
              //   voipService.endCall(voipService.currentCallId!);
              // }
              if (mounted) { // Added mounted check
                 Navigator.of(context).pop();
              }
            },
            child: const Icon(Icons.arrow_back_ios, color: Colors.white),
          ),
          Text(
            _getCallStateText(voipService.callState),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (voipService.isInCall)
            Text(
              voipService.formatCallDuration(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            )
          else
            const SizedBox(width: 60),
        ],
      ),
    );
  }


  Widget _buildContactInfo(VoipService voipService) {
    final contactName = widget.contactName ??
                       voipService.currentCallee ??
                       voipService.currentCaller ??
                       'Usuário';

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Avatar com animação de pulso durante chamada
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: voipService.callState == VoipCallState.calling ||
                     voipService.callState == VoipCallState.ringing
                  ? _pulseAnimation.value
                  : 1.0,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      Colors.blue.shade400,
                      Colors.purple.shade400,
                    ],
                  ),
                ),
                child: const Icon(
                  Icons.person,
                  size: 80,
                  color: Colors.white,
                ),
              ),
            );
          },
        ),

        const SizedBox(height: 24),

        // Nome do contato
        Text(
          contactName,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 8),

        // Informações adicionais
        if (widget.isIncomingCall)
          const Text(
            'Chamada recebida',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
      ],
    );
  }

  Widget _buildCallStatus(VoipService voipService) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Text(
        _getCallStatusText(voipService.callState),
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 18,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildCallControls(BuildContext context, CallProvider callProvider, VoipService voipService) {
    if (widget.isIncomingCall && voipService.callState == VoipCallState.ringing) {
      return _buildIncomingCallControls(context, voipService);
    } else {
      return _buildActiveCallControls(context, callProvider, voipService);
    }
  }

  Widget _buildIncomingCallControls(BuildContext context, VoipService voipService) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Rejeitar chamada
        _buildControlButton(
          icon: Icons.call_end,
          color: Colors.red,
          onPressed: () async {
            if (voipService.currentCallId != null) {
              await voipService.rejectCall(voipService.currentCallId!);
            }
            if (mounted) { // Add mounted check
              Navigator.of(context).pop();
            }
          },
        ),

        // Aceitar chamada
        _buildControlButton(
          icon: Icons.call,
          color: Colors.green,
          onPressed: () async {
            if (voipService.currentCallId != null && widget.contactId != null) {
              final success = await voipService.acceptCall(
                voipService.currentCallId!,
              );
              if (success) {
                // Navigation to CallPage should happen here or via state change listener if not already on CallPage
                // If this button is only shown when on a CallPage equivalent, direct state handling might be sufficient
                 if (mounted) { // Add mounted check
                   // Example: Navigate to the connected call screen if not already there
                   // Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => ConnectedCallScreen()));
                 }
              } else {
                 // Handle acceptance failure
              }
            }
          },
        ),
      ],
    );
  }

  Widget _buildActiveCallControls(BuildContext context, CallProvider callProvider, VoipService voipService) {
    return Column(
      children: [
        // Primeira linha de controles
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Mute/Unmute
            _buildControlButton(
              icon: callProvider.isMicMuted ? Icons.mic_off : Icons.mic,
              color: callProvider.isMicMuted ? Colors.red : Colors.white,
              backgroundColor: callProvider.isMicMuted ? Colors.white : Colors.grey.shade800,
              onPressed: () {
                callProvider.toggleMicMute();
              },
            ),

            // Speaker
            _buildControlButton(
              icon: callProvider.isSpeakerOn ? Icons.volume_up : Icons.volume_down,
              color: callProvider.isSpeakerOn ? Colors.blue : Colors.white,
              backgroundColor: callProvider.isSpeakerOn ? Colors.white : Colors.grey.shade800,
              onPressed: () {
                callProvider.toggleSpeaker();
              },
            ),
          ],
        ),

        const SizedBox(height: 32),

        // Botão de encerrar chamada
        _buildControlButton(
          icon: Icons.call_end,
          color: Colors.white,
          backgroundColor: Colors.red,
          size: 70,
          iconSize: 35,
          onPressed: () async {
            if (voipService.currentCallId != null) {
               await voipService.endCall(voipService.currentCallId!);
            }
            if (mounted) { // Add mounted check
              Navigator.of(context).pop();
            }
          },
        ),
      ],
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required Color color,
    Color? backgroundColor,
    required VoidCallback onPressed,
    double size = 60,
    double iconSize = 30,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: backgroundColor ?? Colors.grey.shade800,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3), // Corrected line
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: color,
          size: iconSize,
        ),
      ),
    );
  }

  String _getCallStateText(VoipCallState state) {
    switch (state) {
      case VoipCallState.idle:
        return 'Inativo';
      case VoipCallState.calling:
        return 'Chamando...';
      case VoipCallState.ringing:
        return 'Tocando';
      case VoipCallState.connected:
        return 'Conectado';
      case VoipCallState.ended:
        return 'Chamada encerrada';
      case VoipCallState.failed:
        return 'Falha na chamada';
    }
  }

  String _getCallStatusText(VoipCallState state) {
    switch (state) {
      case VoipCallState.calling:
        return 'Conectando...';
      case VoipCallState.ringing:
        return 'Chamada recebida';
      case VoipCallState.connected:
        return 'Chamada em andamento';
      case VoipCallState.ended:
        return 'Chamada finalizada';
      case VoipCallState.failed:
        return 'Não foi possível conectar';
      default:
        return '';
    }
  }
}