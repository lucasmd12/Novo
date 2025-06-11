import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/auth_service.dart';
import '../utils/logger.dart';
import '../widgets/custom_snackbar.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _requestPermissionsAfterRegister() async {
    Logger.info("Requesting permissions after registration...");
    var statusNotification = await Permission.notification.request();
    Logger.info("Notification permission status: $statusNotification");
    var statusMicrophone = await Permission.microphone.request();
    Logger.info("Microphone permission status: $statusMicrophone");
    Logger.info("Initial permission requests completed.");
  }

  Future<void> _handleRegisterAndLogin() async { // Renamed function
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final authService = Provider.of<AuthService>(context, listen: false);
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    try {
      Logger.info('Attempting registration for username: $username');
      bool registerSuccess = await authService.register(username, password);

      if (registerSuccess) {
        Logger.info('Registration API call successful for user: $username. Attempting login...');
        // Show temporary success message before attempting login
        if (mounted) {
            CustomSnackbar.showInfo(context, 'Registro bem-sucedido! Entrando...');
        }

        // *** Attempt to login immediately after successful registration ***
        bool loginSuccess = await authService.login(username, password);

        if (loginSuccess) {
          Logger.info('Auto-login successful after registration for user: $username');
          await _requestPermissionsAfterRegister();
          // Navigation to HomeScreen is handled by the Consumer<AuthProvider> in main.dart
          // No explicit navigation needed here if login sets the state correctly.
          // Optionally, pop the registration screen if it's on top of login
          if (mounted && Navigator.canPop(context)) {
             // Pop back to remove the registration screen from the stack
             // The main navigator watcher will push HomeScreen
             Navigator.pop(context);
          }
        } else {
          // Login failed after successful registration (should be rare)
          Logger.error('Auto-login failed after registration for user: $username');
          if (mounted) {
            CustomSnackbar.showError(context, 'Registro bem-sucedido, mas falha ao entrar automaticamente. Por favor, tente fazer login manualmente.');
            // Navigate back to login screen
             if (Navigator.canPop(context)) {
               Navigator.pop(context);
             }
          }
        }
      } else {
        // Registration itself failed
        if (mounted) {
          // Use the error message from AuthService if available
          final errorMsg = authService.errorMessage ?? 'Falha no registro. Verifique os dados ou tente novamente.';
          CustomSnackbar.showError(context, errorMsg);
        }
      }
    } catch (e) {
      // Catch errors from either register or login calls
      Logger.error('Register/Login Screen Error', error: e);
      if (mounted) {
        CustomSnackbar.showError(context, 'Erro: ${e.toString().replaceFirst("Exception: ", "")}');
      }
    } finally {
       if (mounted) {
         setState(() {
           _isLoading = false;
         });
       }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final inputDecorationTheme = Theme.of(context).inputDecorationTheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Criar Conta'),
        backgroundColor: Colors.transparent, // Match login style if needed
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Registre-se',
                    textAlign: TextAlign.center,
                    style: textTheme.displayMedium, // Adjust style as needed
                  ),
                  const SizedBox(height: 32),

                  // Username Field
                  TextFormField(
                    controller: _usernameController,
                    keyboardType: TextInputType.text,
                    style: const TextStyle(color: Colors.white, fontFamily: 'Gothic'), // Match login style
                    decoration: InputDecoration(
                      labelText: 'Usuário',
                      prefixIcon: const Icon(Icons.person_outline),
                      labelStyle: inputDecorationTheme.labelStyle,
                      prefixIconColor: inputDecorationTheme.prefixIconColor,
                      enabledBorder: inputDecorationTheme.enabledBorder,
                      focusedBorder: inputDecorationTheme.focusedBorder,
                      errorBorder: inputDecorationTheme.errorBorder,
                      focusedErrorBorder: inputDecorationTheme.focusedErrorBorder,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, insira um nome de usuário';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Password Field
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    style: const TextStyle(color: Colors.white, fontFamily: 'Gothic'), // Match login style
                    decoration: InputDecoration(
                      labelText: 'Senha',
                      prefixIcon: const Icon(Icons.lock_outline),
                      labelStyle: inputDecorationTheme.labelStyle,
                      prefixIconColor: inputDecorationTheme.prefixIconColor,
                      enabledBorder: inputDecorationTheme.enabledBorder,
                      focusedBorder: inputDecorationTheme.focusedBorder,
                      errorBorder: inputDecorationTheme.errorBorder,
                      focusedErrorBorder: inputDecorationTheme.focusedErrorBorder,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, insira uma senha';
                      }
                      if (value.length < 6) { // Example: Minimum length
                        return 'A senha deve ter pelo menos 6 caracteres';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Confirm Password Field
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: true,
                    style: const TextStyle(color: Colors.white, fontFamily: 'Gothic'), // Match login style
                    decoration: InputDecoration(
                      labelText: 'Confirmar Senha',
                      prefixIcon: const Icon(Icons.lock_outline),
                      labelStyle: inputDecorationTheme.labelStyle,
                      prefixIconColor: inputDecorationTheme.prefixIconColor,
                      enabledBorder: inputDecorationTheme.enabledBorder,
                      focusedBorder: inputDecorationTheme.focusedBorder,
                      errorBorder: inputDecorationTheme.errorBorder,
                      focusedErrorBorder: inputDecorationTheme.focusedErrorBorder,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, confirme sua senha';
                      }
                      if (value != _passwordController.text) {
                        return 'As senhas não coincidem';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Register Button
                  ElevatedButton(
                    // *** Call the combined register and login function ***
                    onPressed: _isLoading ? null : _handleRegisterAndLogin,
                    style: ElevatedButton.styleFrom( // Match login button style
                       backgroundColor: Theme.of(context).colorScheme.primary,
                       foregroundColor: Theme.of(context).colorScheme.onPrimary,
                       padding: const EdgeInsets.symmetric(vertical: 16),
                       textStyle: textTheme.labelLarge?.copyWith(fontFamily: 'Gothic'),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('REGISTRAR E ENTRAR'), // Updated button text
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

