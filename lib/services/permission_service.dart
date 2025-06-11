import 'package:permission_handler/permission_handler.dart' as permission_handler;

import 'package:lucasbeatsfederacao/utils/logger.dart'; // Corrected import path

/// Serviço para gerenciar e solicitar permissões essenciais do aplicativo.
class PermissionService {

  /// Solicita permissão para notificações.
  /// Retorna `true` se concedida, `false` caso contrário.
  static Future<bool> requestNotificationPermission() async {
    Logger.info('Requesting notification permission...');
    try {
      // Use the aliased import
      final status = await permission_handler.Permission.notification.request();
      Logger.info('Notification permission status: $status');
      if (status.isGranted) {
        return true;
      } else {
        if (status.isPermanentlyDenied) {
          Logger.error('Notification permission permanently denied.');
          // Consider opening app settings here if needed, but keep the method focused
          // await openAppSettings();
        }
        return false;
      }
    } catch (e, stackTrace) {
      Logger.error('Error requesting notification permission', error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Solicita as permissões críticas necessárias para as funcionalidades de VoIP.
  ///
  /// Retorna `true` se todas as permissões essenciais foram concedidas, `false` caso contrário.
  static Future<bool> requestVoipPermissions() async {
    Logger.info('Requesting VoIP permissions...');

    // Define as permissões necessárias
    // Permissão comum para Android e iOS
    final essentialPermissions = [
      permission_handler.Permission.microphone,
      // Notification permission is often handled separately or upon first notification send
      // Permission.notification, // Removido daqui, solicitado separadamente se necessário
    ];

    // Adiciona permissão de Bluetooth específica para Android (se não for web)
    // Removed Bluetooth permission as it wasn\'t explicitly needed for VoIP core functionality
    // and was causing confusion.


    Map<permission_handler.Permission, permission_handler.PermissionStatus> statuses = {};

    try {
      // Solicita todas as permissões essenciais de uma vez
      statuses = await essentialPermissions.request();
      Logger.info('Permission statuses: $statuses');

      // Verifica se todas as permissões essenciais foram concedidas
      bool allGranted = statuses.values.every((status) => status.isGranted);

      if (allGranted) {
        Logger.info('All essential VoIP permissions granted.');
        return true;
      } else {
        Logger.warning('Not all essential VoIP permissions were granted.');
        // Log detalhado das permissões não concedidas
        statuses.forEach((permission, status) {
          if (!status.isGranted) {
            Logger.warning('Permission denied: $permission - Status: $status');
          }
        });
        // Opcional: Mostrar um diálogo ao usuário explicando a necessidade das permissões
        // e talvez direcionando para as configurações do app.
        return false;
      }
    } catch (e, stackTrace) {
      Logger.error('Error requesting permissions', error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Verifica o status atual de uma permissão específica.
  static Future<permission_handler.PermissionStatus> checkPermissionStatus(permission_handler.Permission permission) async {
    final status = await permission.status;
    Logger.info('Status for $permission: $status');
    return status;
  }

  /// Abre as configurações do aplicativo para que o usuário possa gerenciar as permissões manualmente.\n
  static Future<void> openAppSettings() async {
    Logger.info('Opening app settings...');
    // Corrected: Call the function directly from the aliased import
    await permission_handler.openAppSettings();
  }
}