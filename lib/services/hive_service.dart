import 'package:hive_flutter/hive_flutter.dart';
import '../models/user_profile.dart';
import '../models/attendance_record.dart';
import '../models/payroll_slip.dart';
import '../models/transaction.dart';

class HiveService {
  static const String userBoxName = 'userBox';
  static const String attendanceBoxName = 'attendanceBox';
  static const String payrollBoxName = 'payrollBox';
  static const String transactionBoxName = 'transactionBox';
  static const String teamMembersBoxName = 'teamMembersBox';

  static Future<void> init() async {
    await Hive.initFlutter();

    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(UserProfileAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(AttendanceStatusAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(AttendanceRecordAdapter());
    }
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(WorkSessionAdapter());
    }
    if (!Hive.isAdapterRegistered(4)) {
      Hive.registerAdapter(PayrollSlipAdapter());
    }
    if (!Hive.isAdapterRegistered(5)) {
      Hive.registerAdapter(TransactionTypeAdapter());
    }
    if (!Hive.isAdapterRegistered(6)) {
      Hive.registerAdapter(TransactionAdapter());
    }

    await Hive.openBox<UserProfile>(userBoxName);
    await Hive.openBox<AttendanceRecord>(attendanceBoxName);
    await Hive.openBox<PayrollSlip>(payrollBoxName);
    await Hive.openBox<Transaction>(transactionBoxName);
    await Hive.openBox<String>(teamMembersBoxName);
  }

  static Box<UserProfile> getUserBox() => Hive.box<UserProfile>(userBoxName);
  static Box<AttendanceRecord> getAttendanceBox() =>
      Hive.box<AttendanceRecord>(attendanceBoxName);
  static Box<PayrollSlip> getPayrollBox() =>
      Hive.box<PayrollSlip>(payrollBoxName);
  static Box<Transaction> getTransactionBox() =>
      Hive.box<Transaction>(transactionBoxName);
  static Box<String> getTeamMembersBox() =>
      Hive.box<String>(teamMembersBoxName);
}
