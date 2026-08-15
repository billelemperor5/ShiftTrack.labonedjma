import 'dart:convert';
import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:file_picker/file_picker.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'hive_service.dart';
import '../models/user_profile.dart';
import '../models/attendance_record.dart';
import '../models/payroll_slip.dart';
import '../models/transaction.dart';

Future<void> exportBackupHelper({
  required Function(double) onProgress,
}) async {
  try {
    onProgress(0.1);
    final appDir = await getApplicationDocumentsDirectory();

    // 1. Localize all external images (this copies them to uploads/)
    await _localizeExternalImages(appDirPath: appDir.path);
    onProgress(0.2);

    final userBox = HiveService.getUserBox();
    final attendanceBox = HiveService.getAttendanceBox();
    final payrollBox = HiveService.getPayrollBox();
    final transactionBox = HiveService.getTransactionBox();

    // 2. Serialize UserProfile
    List<Map<String, dynamic>> users = [];
    for (var profile in userBox.values) {
      users.add({
        'firstName': profile.firstName,
        'lastName': profile.lastName,
        'companyName': profile.companyName,
        'logoPath': profile.logoPath != null ? p.basename(profile.logoPath!) : null,
        'isFirstLaunchDone': profile.isFirstLaunchDone,
        'locale': profile.locale,
        'workDays': profile.workDays,
        'defaultCheckIn': profile.defaultCheckIn,
        'defaultCheckOut': profile.defaultCheckOut,
        'themeMode': profile.themeMode,
        'breakDuration': profile.breakDuration,
        'isBreakPaid': profile.isBreakPaid,
        'faceCheckinEnabled': profile.faceCheckinEnabled,
        'notificationsEnabled': profile.notificationsEnabled,
        'notificationWorkDays': profile.notificationWorkDays,
      });
    }
    onProgress(0.3);

    // 3. Serialize AttendanceRecord
    List<Map<String, dynamic>> attendances = [];
    for (var record in attendanceBox.values) {
      List<Map<String, dynamic>> extra = [];
      if (record.extraSessions != null) {
        for (var s in record.extraSessions!) {
          extra.add({
            'startTime': s.startTime,
            'endTime': s.endTime,
            'hours': s.hours,
          });
        }
      }
      attendances.add({
        'date': record.date.toIso8601String(),
        'status': record.status.index,
        'checkIn': record.checkIn,
        'checkOut': record.checkOut,
        'hours': record.hours,
        'scheduledHours': record.scheduledHours,
        'extraSessions': extra,
      });
    }
    onProgress(0.4);

    // 4. Serialize PayrollSlip
    List<Map<String, dynamic>> payrolls = [];
    for (var slip in payrollBox.values) {
      payrolls.add({
        'date': slip.date.toIso8601String(),
        'imagePath': p.basename(slip.imagePath),
        'note': slip.note,
      });
    }
    onProgress(0.5);

    // 5. Serialize Transaction
    List<Map<String, dynamic>> transactions = [];
    for (var tx in transactionBox.values) {
      transactions.add({
        'type': tx.type.index,
        'amount': tx.amount,
        'category': tx.category,
        'note': tx.note,
        'date': tx.date.toIso8601String(),
      });
    }
    onProgress(0.6);

    final backupData = {
      'version': 2,
      'users': users,
      'attendances': attendances,
      'payrolls': payrolls,
      'transactions': transactions,
    };

    final jsonString = jsonEncode(backupData);
    final jsonBytes = utf8.encode(jsonString);

    final tempDir = await getTemporaryDirectory();
    final date = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final backupPath = p.join(tempDir.path, 'ShiftTrack_Backup_$date.stback');

    final encoder = ZipFileEncoder();
    encoder.create(backupPath);

    // Add JSON data
    final tempJsonFile = File(p.join(tempDir.path, 'backup_data.json'));
    tempJsonFile.writeAsBytesSync(jsonBytes);
    encoder.addFile(tempJsonFile, 'backup_data.json');
    onProgress(0.7);

    // Add files from uploads directory (images)
    final uploadDir = Directory(p.join(appDir.path, 'uploads'));
    if (uploadDir.existsSync()) {
      final uploadFiles = uploadDir.listSync().whereType<File>().toList();
      for (int i = 0; i < uploadFiles.length; i++) {
        final f = uploadFiles[i];
        final relPath = p.join('uploads', p.basename(f.path));
        encoder.addFile(f, relPath);
        onProgress(0.7 + (i / uploadFiles.length) * 0.2);
      }
    }

    encoder.close();
    onProgress(0.9);

    // Clean up temporary JSON file
    try {
      if (tempJsonFile.existsSync()) tempJsonFile.deleteSync();
    } catch (_) {}

    // 6. Share the file
    // ignore: deprecated_member_use
    await Share.shareXFiles([
      XFile(backupPath),
    ], subject: 'ShiftTrack Backup $date');
    onProgress(1.0);
  } catch (e) {
    rethrow;
  }
}

Future<void> _localizeExternalImages({
  required String appDirPath,
}) async {
  final uploadDir = Directory(p.join(appDirPath, 'uploads'));
  if (!uploadDir.existsSync()) uploadDir.createSync(recursive: true);

  // Profile Logo
  final Box<UserProfile> userBox = HiveService.getUserBox();
  if (userBox.isNotEmpty) {
    final UserProfile? profile = userBox.getAt(0);
    if (profile != null && profile.logoPath != null) {
      if (!p.isWithin(appDirPath, profile.logoPath!)) {
        final newPath = p.join(
          uploadDir.path,
          'logo_${p.basename(profile.logoPath!)}',
        );
        try {
          await File(profile.logoPath!).copy(newPath);
          profile.logoPath = newPath;
          await profile.save();
        } catch (_) {}
      }
    }
  }

  // Payroll Slips
  final Box<PayrollSlip> payrollBox = HiveService.getPayrollBox();
  for (int i = 0; i < payrollBox.length; i++) {
    final PayrollSlip? slip = payrollBox.getAt(i);
    if (slip != null && !p.isWithin(appDirPath, slip.imagePath)) {
      final newPath = p.join(
        uploadDir.path,
        'slip_${i}_${p.basename(slip.imagePath)}',
      );
      try {
        await File(slip.imagePath).copy(newPath);
        slip.imagePath = newPath;
        await slip.save();
      } catch (_) {}
    }
  }
}

Future<bool> importBackupHelper({
  required Function(double) onProgress,
}) async {
  try {
    final result = await FilePicker.platform.pickFiles();
    if (result == null || result.files.single.path == null) return false;

    final backupFile = File(result.files.single.path!);
    final appDir = await getApplicationDocumentsDirectory();

    final bytes = await backupFile.readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);
    onProgress(0.2);

    final jsonFile = archive.findFile('backup_data.json');

    if (jsonFile != null) {
      // 1. New JSON Backup Format
      final jsonString = utf8.decode(jsonFile.content as List<int>);
      final Map<String, dynamic> data = jsonDecode(jsonString);
      onProgress(0.4);

      // Extract uploads/ directory if present
      final uploadDir = Directory(p.join(appDir.path, 'uploads'));
      if (!uploadDir.existsSync()) uploadDir.createSync(recursive: true);

      for (final file in archive) {
        if (file.isFile && file.name.startsWith('uploads/')) {
          final fileData = file.content as List<int>;
          final outFile = File(p.join(appDir.path, file.name));
          await outFile.create(recursive: true);
          await outFile.writeAsBytes(fileData);
        }
      }
      onProgress(0.6);

      final userBox = HiveService.getUserBox();
      final attendanceBox = HiveService.getAttendanceBox();
      final payrollBox = HiveService.getPayrollBox();
      final transactionBox = HiveService.getTransactionBox();

      await userBox.clear();
      await attendanceBox.clear();
      await payrollBox.clear();
      await transactionBox.clear();

      if (data['users'] != null) {
        final List users = data['users'];
        for (var u in users) {
          String? logoPath = u['logoPath'];
          if (logoPath != null) {
            logoPath = p.join(appDir.path, 'uploads', p.basename(logoPath));
          }
          final profile = UserProfile(
            firstName: u['firstName'],
            lastName: u['lastName'],
            companyName: u['companyName'],
            logoPath: logoPath,
            isFirstLaunchDone: u['isFirstLaunchDone'] ?? false,
            locale: u['locale'] ?? 'fr',
            workDays: List<int>.from(u['workDays'] ?? []),
            defaultCheckIn: u['defaultCheckIn'] ?? '08:00',
            defaultCheckOut: u['defaultCheckOut'] ?? '16:00',
            themeMode: u['themeMode'] ?? 'light',
            breakDuration: u['breakDuration'] ?? 30,
            isBreakPaid: u['isBreakPaid'] ?? false,
            faceCheckinEnabled: u['faceCheckinEnabled'] ?? false,
            notificationsEnabled: u['notificationsEnabled'] ?? false,
            notificationWorkDays: List<int>.from(u['notificationWorkDays'] ?? []),
          );
          await userBox.add(profile);
        }
      }

      if (data['attendances'] != null) {
        final List attendances = data['attendances'];
        for (var a in attendances) {
          List<WorkSession>? extra;
          if (a['extraSessions'] != null) {
            extra = [];
            for (var s in a['extraSessions']) {
              extra.add(WorkSession(
                startTime: s['startTime'],
                endTime: s['endTime'],
                hours: (s['hours'] as num).toDouble(),
              ));
            }
          }
          final record = AttendanceRecord(
            date: DateTime.parse(a['date']),
            status: AttendanceStatus.values[a['status']],
            checkIn: a['checkIn'],
            checkOut: a['checkOut'],
            hours: (a['hours'] as num).toDouble(),
            scheduledHours: (a['scheduledHours'] as num?)?.toDouble() ?? 0.0,
            extraSessions: extra,
          );
          await attendanceBox.add(record);
        }
      }

      if (data['payrolls'] != null) {
        final List payrolls = data['payrolls'];
        for (var pSlip in payrolls) {
          String imagePath = pSlip['imagePath'] ?? '';
          if (imagePath.isNotEmpty) {
            imagePath = p.join(appDir.path, 'uploads', p.basename(imagePath));
          }
          final slip = PayrollSlip(
            date: DateTime.parse(pSlip['date']),
            imagePath: imagePath,
            note: pSlip['note'],
          );
          await payrollBox.add(slip);
        }
      }

      if (data['transactions'] != null) {
        final List transactions = data['transactions'];
        for (var t in transactions) {
          final tx = Transaction(
            type: TransactionType.values[t['type']],
            amount: (t['amount'] as num).toDouble(),
            category: t['category'],
            note: t['note'],
            date: DateTime.parse(t['date']),
          );
          await transactionBox.add(tx);
        }
      }
      onProgress(1.0);
      return true;
    } else {
      // 2. Old Raw Database Format Fallback
      await Hive.close();

      if (appDir.existsSync()) {
        final List<FileSystemEntity> existing = appDir.listSync();
        for (var entity in existing) {
          try {
            await entity.delete(recursive: true);
          } catch (_) {}
        }
      }

      for (int i = 0; i < archive.length; i++) {
        final file = archive[i];
        if (file.isFile) {
          final data = file.content as List<int>;
          final outFile = File(p.join(appDir.path, file.name));
          await outFile.create(recursive: true);
          await outFile.writeAsBytes(data);
        }
        onProgress((i + 1) / archive.length);
      }

      await HiveService.init();
      await _fixDatabasePaths(appDir.path);
      return true;
    }
  } catch (e) {
    await HiveService.init();
    rethrow;
  }
}

Future<void> _fixDatabasePaths(String newAppDirPath) async {
  final Box<UserProfile> userBox = HiveService.getUserBox();
  if (userBox.isNotEmpty) {
    final UserProfile? profile = userBox.getAt(0);
    if (profile != null && profile.logoPath != null) {
      final filename = p.basename(profile.logoPath!);
      final nestedPath = p.join(newAppDirPath, 'uploads', filename);
      final rootPath = p.join(newAppDirPath, filename);

      if (File(nestedPath).existsSync()) {
        profile.logoPath = nestedPath;
      } else if (File(rootPath).existsSync()) {
        profile.logoPath = rootPath;
      }
      await profile.save();
    }
  }

  final Box<PayrollSlip> payrollBox = HiveService.getPayrollBox();
  for (int i = 0; i < payrollBox.length; i++) {
    final PayrollSlip? slip = payrollBox.getAt(i);
    if (slip != null) {
      final filename = p.basename(slip.imagePath);
      final nestedPath = p.join(newAppDirPath, 'uploads', filename);
      final rootPath = p.join(newAppDirPath, filename);

      if (File(nestedPath).existsSync()) {
        slip.imagePath = nestedPath;
      } else if (File(rootPath).existsSync()) {
        slip.imagePath = rootPath;
      }
      await slip.save();
    }
  }
}
