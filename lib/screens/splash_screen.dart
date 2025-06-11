import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lucasbeatsfederacao/utils/logger.dart'; // Assuming logger path
import 'package:audioplayers/audioplayers.dart'; // Import audioplayers

class SplashScreen extends StatefulWidget {
  final bool showIndicator; // Control indicator visibility
  const SplashScreen({super.key, this.showIndicator = false});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final AudioPlayer _gunshotPlayer = AudioPlayer();
  final AudioPlayer _ambientPlayer = AudioPlayer();
  StreamSubscription? _gunshotSubscription;

  @override
  void initState() {
    super.initState();
    Logger.info("SplashScreen initialized. Indicator: ${widget.showIndicator}");
    _playSplashSoundsSequence(); // Play the sound sequence on init
  }

  Future<void> _playSplashSoundsSequence() async {
    try {
      // Configure players
      await _gunshotPlayer.setReleaseMode(ReleaseMode.stop); // Stop after playing
      await _ambientPlayer.setReleaseMode(ReleaseMode.loop); // Loop ambient sound

      // Listen for gunshot completion
      _gunshotSubscription = _gunshotPlayer.onPlayerComplete.listen((event) {
        Logger.info("Gunshot sound completed.");
        _playAmbientSound(); // Play ambient sound after gunshot
      });

      // Play gunshot sound
      Logger.info("Playing gunshot sound...");
      await _gunshotPlayer.play(AssetSource('audio/gun_sound_effect.mp3'));
      Logger.info("Gunshot sound playback started.");

    } catch (e, stackTrace) {
      Logger.error("Failed to play gunshot sound", error: e, stackTrace: stackTrace);
      // Attempt to play ambient sound even if gunshot fails
      _playAmbientSound();
    }
  }

  Future<void> _playAmbientSound() async {
    try {
      Logger.info("Playing ambient sound...");
      // Assuming 'splash_sound.mp3' is the dark ambient sound
      await _ambientPlayer.play(AssetSource('audio/splash_sound.mp3'));
      Logger.info("Ambient sound playback started (looping).");
    } catch (e, stackTrace) {
      Logger.error("Failed to play ambient sound", error: e, stackTrace: stackTrace);
    }
  }

  @override
  void dispose() {
    Logger.info("Disposing SplashScreen audio players.");
    _gunshotSubscription?.cancel(); // Cancel the subscription
    _gunshotPlayer.dispose();
    _ambientPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      // Use the new background image
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            // Use the bg_joker_smoke image
            image: AssetImage("assets/images_png/backgrounds/bg_joker_smoke.png"),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Use actual logo asset (assuming app_logo.png is the correct one)
              Image.asset(
                'assets/images_png/app_logo.png',
                height: 120,
                errorBuilder: (context, error, stackTrace) {
                  Logger.error("Failed to load splash logo", error: error, stackTrace: stackTrace);
                  return Icon(
                    Icons.shield_moon, // Fallback icon
                    size: 100,
                    color: Theme.of(context).primaryColor,
                  );
                },
              ),
              const SizedBox(height: 24),
              // App Name
              Text(
                'FEDERACAO MADOUT', // Keep existing App Name or update if needed
                style: textTheme.displayLarge?.copyWith(
                  fontSize: 36,
                  color: Colors.white, // Ensure visibility against dark background
                  shadows: [
                     Shadow( // Add shadow for better readability
                      offset: Offset(2.0, 2.0),
                      blurRadius: 3.0,
                      color: Color.fromARGB(150, 0, 0, 0),
                    ),
                  ]
                ),
              ),
              const SizedBox(height: 16),
              // Subtitle or slogan
              Text(
                'Comunicação e organização para o clã',
                style: textTheme.displayMedium?.copyWith(
                  color: Colors.white.withOpacity(0.8), // Ensure visibility
                   shadows: [
                     Shadow(
                      offset: Offset(1.0, 1.0),
                      blurRadius: 2.0,
                      color: Color.fromARGB(150, 0, 0, 0),
                    ),
                  ]
                ),
              ),
              const SizedBox(height: 48),
              // Loading Indicator (conditionally shown)
              if (widget.showIndicator)
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
                )
              else
                const SizedBox(height: 48), // Maintain spacing
            ],
          ),
        ),
      ),
    );
  }
}

