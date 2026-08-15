import 'package:hive/hive.dart';

part 'attendance_record.g.dart';

@HiveType(typeId: 1)
enum AttendanceStatus {
  @HiveField(0)
  present,
  @HiveField(1)
  absent,
}

@HiveType(typeId: 3)
class WorkSession extends HiveObject {
  @HiveField(0)
  String startTime;

  @HiveField(1)
  String endTime;

  @HiveField(2)
  double hours;

  WorkSession({
    required this.startTime,
    required this.endTime,
    required this.hours,
  });
}

@HiveType(typeId: 2)
class AttendanceRecord extends HiveObject {
  @HiveField(0)
  DateTime date;

  @HiveField(1)
  AttendanceStatus status;

  @HiveField(2)
  String? checkIn;

  @HiveField(3)
  String? checkOut;

  @HiveField(4)
  double hours;

  @HiveField(5)
  List<WorkSession>? extraSessions;

  @HiveField(6, defaultValue: 0.0)
  double scheduledHours;

  AttendanceRecord({
    required this.date,
    required this.status,
    this.checkIn,
    this.checkOut,
    this.hours = 0.0,
    this.extraSessions,
    this.scheduledHours = 0.0,
  });
}
