import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart'; // Import Firebase Core

// Import Screens
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/register_screen.dart';
import 'screens/call_page.dart';
import 'screens/clan_management_screen.dart';
import 'screens/call_history_page.dart';

// Import Services, Providers and Models
import 'services/api_service.dart';
import 'services/auth_service.dart';
import 'services/federation_service.dart';
import 'services/clan_service.dart';
import 'services/socket_service.dart';
import 'services/chat_service.dart';
import 'services/signaling_service.dart';
import 'services/voip_service.dart';
import 'services/notification_service.dart';
import 'providers/auth_provider.dart'; // Import AuthProvider
import 'providers/connectivity_provider.dart';
import 'providers/call_provider.dart';
import 'utils/logger.dart';
import 'utils/theme_constants.dart';
import 'widgets/app_lifecycle_reactor.dart';
import 'widgets/incoming_call_overlay.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Inicializa o Firebase
  Logger.info("App Initialization Started.");

  try {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    Logger.info('Screen orientation set to portrait.');
  } catch (e, stackTrace) {
    Logger.error('Failed to set screen orientation', error: e, stackTrace: stackTrace);
  }

  Logger.info("Running FEDERACAOMAD App.");
  runApp(const FEDERACAOMADApp());
}

class FEDERACAOMADApp extends StatelessWidget {
  const FEDERACAOMADApp({super.key});

  @override
  Widget build(BuildContext context) {
    Logger.info("Building FEDERACAOMADApp Widget.");

    final apiService = ApiService();
    final authService = AuthService();
    final socketService = SocketService(authService);
    final signalingService = SignalingService(socketService, rtcConfiguration: {}); // Temporary fix: pass empty constraints
    final federationService = FederationService(apiService, authService);
    final clanService = ClanService(apiService, authService);
    final chatService = ChatService();
    final notificationService = NotificationService(apiService, authService);

    return MultiProvider(
      providers: [
        // --- Core Services ---
        Provider<ApiService>.value(value: apiService),
        ChangeNotifierProvider<AuthService>.value(value: authService),
        Provider<SocketService>.value(value: socketService),
        ChangeNotifierProvider<SignalingService>.value(value: signalingService),
        Provider<FederationService>.value(value: federationService),
        Provider<ClanService>.value(value: clanService),
        ChangeNotifierProvider<NotificationService>.value(value: notificationService),

        // --- VoIP Service ---
        ChangeNotifierProvider<VoipService>(
          create: (context) => VoipService(),
        ),

        // --- Feature Services & Providers (Dependent on Core Services) ---
        ChangeNotifierProvider<ChatService>.value(value: chatService),
        ChangeNotifierProvider<AuthProvider>(
          create: (context) => AuthProvider(
            context.read<AuthService>(),
            context.read<SocketService>(),
          ),
        ),
        ChangeNotifierProvider<CallProvider>(
          create: (context) => CallProvider(
            authService: context.read<AuthService>(),
            socketService: context.read<SocketService>(),
            signalingService: context.read<SignalingService>(),
          ),
        ),
        ChangeNotifierProvider(create: (context) => ConnectivityProvider()),
      ],
      child: AppLifecycleReactor(
        child: MaterialApp(
          title: 'FEDERACAOMAD',
          debugShowCheckedModeBanner: false,
          theme: ThemeConstants.darkTheme,
          home: IncomingCallManager(
            child: Consumer<AuthProvider>(
              builder: (context, authProvider, _) {
                if (authProvider.authStatus == AuthStatus.unknown) {
                  return const SplashScreen();
                } else if (authProvider.authStatus == AuthStatus.authenticated) {
                  return const HomeScreen();
                } else {
                  return const LoginScreen();
                }
              },
            ),
          ),
          routes: {
            '/splash': (context) => const SplashScreen(),
            '/login': (context) => const LoginScreen(),
            '/register': (context) => const RegisterScreen(),
            '/home': (context) => const HomeScreen(),
            '/call': (context) => const CallPage(),
            '/call-history': (context) => const CallHistoryPage(),
            '/clan-management': (context) {
              final clanId = ModalRoute.of(context)?.settings.arguments as String?;
              if (clanId != null) {
                return ClanManagementScreen(clanId: clanId);
              } else {
                return Scaffold(appBar: AppBar(title: const Text('Erro')), body: const Center(child: Text('ID do Clã não fornecido.')));
              }
            },
          },
        ),
      ),
    );
  }
}

