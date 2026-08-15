import 'backup_service_stub.dart'
  if (dart.library.html) 'backup_service_web.dart'
  if (dart.library.io) 'backup_service_mobile.dart';

class BackupService {
  static Future<void> exportBackup({
    required Function(double) onProgress,
  }) async {
    await exportBackupHelper(onProgress: onProgress);
  }

  static Future<bool> importBackup({
    required Function(double) onProgress,
  }) async {
    return importBackupHelper(onProgress: onProgress);
  }
}
