import 'dart:convert';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import '../models/user_profile.dart';
import '../models/attendance_record.dart';
import '../models/payroll_slip.dart';
import '../models/transaction.dart';
import 'hive_service.dart';
import '../utils/file_saver.dart';

Future<void> exportBackupHelper({required Function(double) onProgress}) async {
  try {
    onProgress(0.2);
    final userBox = HiveService.getUserBox();
    final attendanceBox = HiveService.getAttendanceBox();
    final payrollBox = HiveService.getPayrollBox();
    final transactionBox = HiveService.getTransactionBox();

    // 1. Serialize UserProfile
    List<Map<String, dynamic>> users = [];
    for (var profile in userBox.values) {
      users.add({
        'firstName': profile.firstName,
        'lastName': profile.lastName,
        'companyName': profile.companyName,
        'logoPath': profile.logoPath,
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
    onProgress(0.4);

    // 2. Serialize AttendanceRecord
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
    onProgress(0.6);

    // 3. Serialize PayrollSlip
    List<Map<String, dynamic>> payrolls = [];
    for (var slip in payrollBox.values) {
      payrolls.add({
        'date': slip.date.toIso8601String(),
        'imagePath': slip.imagePath,
        'note': slip.note,
      });
    }

    // 4. Serialize Transaction
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
    onProgress(0.8);

    final backupData = {
      'version': 2,
      'users': users,
      'attendances': attendances,
      'payrolls': payrolls,
      'transactions': transactions,
    };

    final jsonString = jsonEncode(backupData);
    final jsonBytes = utf8.encode(jsonString);

    final archive = Archive();
    archive.addFile(ArchiveFile('backup_data.json', jsonBytes.length, jsonBytes));

    final zipBytes = ZipEncoder().encode(archive);
    if (zipBytes != null) {
      final date = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      await FileSaver.saveAndShareFile(
        Uint8List.fromList(zipBytes),
        'ShiftTrack_Backup_$date.stback',
      );
    }
    onProgress(1.0);
  } catch (e) {
    rethrow;
  }
}

Future<bool> importBackupHelper({required Function(double) onProgress}) async {
  try {
    final result = await FilePicker.platform.pickFiles();
    if (result == null || result.files.single.bytes == null) return false;

    final bytes = result.files.single.bytes!;
    onProgress(0.2);

    final archive = ZipDecoder().decodeBytes(bytes);
    final jsonFile = archive.findFile('backup_data.json');
    if (jsonFile == null) {
      final hasHiveFiles = archive.any((f) => f.name.endsWith('.hive'));
      if (hasHiveFiles) {
        throw Exception("Ce fichier de sauvegarde provient d'une ancienne version mobile. Veuillez d'abord l'importer dans l'application mobile, puis exporter une nouvelle sauvegarde.");
      }
      throw Exception("Fichier de sauvegarde invalide (fichier 'backup_data.json' introuvable).");
    }

    final jsonString = utf8.decode(jsonFile.content as List<int>);
    final Map<String, dynamic> data = jsonDecode(jsonString);
    onProgress(0.4);

    final userBox = HiveService.getUserBox();
    final attendanceBox = HiveService.getAttendanceBox();
    final payrollBox = HiveService.getPayrollBox();
    final transactionBox = HiveService.getTransactionBox();

    await userBox.clear();
    await attendanceBox.clear();
    await payrollBox.clear();
    await transactionBox.clear();

    onProgress(0.6);

    if (data['users'] != null) {
      final List users = data['users'];
      for (var u in users) {
        String? logoPath = u['logoPath'];
        if (logoPath != null && logoPath.isNotEmpty && !logoPath.startsWith('data:')) {
          final filename = p.basename(logoPath);
          final imgFile = _findFileInArchive(archive, filename);
          if (imgFile != null) {
            final fileBytes = imgFile.content as List<int>;
            final base64String = base64Encode(fileBytes);
            final mimeType = _getMimeType(filename);
            logoPath = 'data:$mimeType;base64,$base64String';
          }
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
        if (imagePath.isNotEmpty && !imagePath.startsWith('data:')) {
          final filename = p.basename(imagePath);
          final imgFile = _findFileInArchive(archive, filename);
          if (imgFile != null) {
            final fileBytes = imgFile.content as List<int>;
            final base64String = base64Encode(fileBytes);
            final mimeType = _getMimeType(filename);
            imagePath = 'data:$mimeType;base64,$base64String';
          }
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
  } catch (e) {
    rethrow;
  }
}

ArchiveFile? _findFileInArchive(Archive archive, String filename) {
  final baseName = p.basename(filename);
  for (final file in archive) {
    final normalizedName = file.name.replaceAll('\\', '/');
    if (file.isFile && (normalizedName == baseName || normalizedName.endsWith('/$baseName'))) {
      return file;
    }
  }
  return null;
}

String _getMimeType(String filename) {
  final ext = p.extension(filename).toLowerCase();
  switch (ext) {
    case '.jpg':
    case '.jpeg':
      return 'image/jpeg';
    case '.png':
      return 'image/png';
    case '.gif':
      return 'image/gif';
    case '.webp':
      return 'image/webp';
    case '.svg':
      return 'image/svg+xml';
    default:
      return 'application/octet-stream';
  }
}
