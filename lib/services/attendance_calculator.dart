import 'package:intl/intl.dart';
import 'zkbiotime_service.dart';

class DailyAttendanceSummary {
  final DateTime date;
  final String dateStr;      // YYYY-MM-DD
  final String dateFR;       // DD/MM/YYYY
  final String dayName;      // Lundi, Mardi, ...
  final bool isWeekend;
  final bool isFuture;
  final bool isToday;
  final bool isPast;
  final String? entryTime;   // HH:MM
  final String? exitTime;    // HH:MM
  final int workTimeMinutes;
  final String workTimeStr;  // 08h24
  final int delayMinutes;
  final String delayStr;     // 00h10
  final String status;       // Présent, Retard, Absence, Repos, À venir
  final String statusBadge;   // badge-success, badge-warning, badge-danger, badge-muted
  final List<String> anomalies;
  final List<ZKBioTimePunch> punches;

  DailyAttendanceSummary({
    required this.date,
    required this.dateStr,
    required this.dateFR,
    required this.dayName,
    required this.isWeekend,
    required this.isFuture,
    required this.isToday,
    required this.isPast,
    this.entryTime,
    this.exitTime,
    required this.workTimeMinutes,
    required this.workTimeStr,
    required this.delayMinutes,
    required this.delayStr,
    required this.status,
    required this.statusBadge,
    required this.anomalies,
    required this.punches,
  });
}

class MonthAttendanceReport {
  final String empCode;
  final String empName;
  final String department;
  final String? photoUrl;
  final String startDate;
  final String endDate;
  final List<DailyAttendanceSummary> days;
  final int daysWorked;
  final int totalWorkMinutes;
  final String totalWorkHoursStr;
  final int totalDelaysCount;
  final int totalDelayMinutes;
  final String totalDelayDurationStr;
  final int totalAbsencesCount;
  final int totalAnomaliesCount;
  final int presenceRate;
  final int elapsedWorkingDaysCount;
  final String avgDailyWorkStr;

  MonthAttendanceReport({
    required this.empCode,
    required this.empName,
    required this.department,
    this.photoUrl,
    required this.startDate,
    required this.endDate,
    required this.days,
    required this.daysWorked,
    required this.totalWorkMinutes,
    required this.totalWorkHoursStr,
    required this.totalDelaysCount,
    required this.totalDelayMinutes,
    required this.totalDelayDurationStr,
    required this.totalAbsencesCount,
    required this.totalAnomaliesCount,
    required this.presenceRate,
    required this.elapsedWorkingDaysCount,
    required this.avgDailyWorkStr,
  });
}

class AttendanceCalculator {
  static const String standardStartTime = '08:00';
  static const int graceMinutes = 15;
  static const int standardWorkMinutesPerDay = 480; // 8 hours

  static final List<String> frenchDays = [
    'Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'
  ];

  static String formatMinutes(int minutes) {
    if (minutes <= 0) return '00h00';
    final h = (minutes ~/ 60).toString().padLeft(2, '0');
    final m = (minutes % 60).toString().padLeft(2, '0');
    return '${h}h$m';
  }

  /// Process date range and punches into a comprehensive attendance report
  static MonthAttendanceReport processRange({
    required String empCode,
    required String empName,
    required String department,
    String? photoUrl,
    required DateTime startDate,
    required DateTime endDate,
    required List<ZKBioTimePunch> punches,
    DateTime? todayOverride,
  }) {
    final now = todayOverride ?? DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(now);

    // Group punches by day
    final Map<String, List<ZKBioTimePunch>> punchesByDay = {};
    for (final p in punches) {
      if (p.punchTime.length >= 10) {
        final dayKey = p.punchTime.substring(0, 10);
        punchesByDay.putIfAbsent(dayKey, () => []).add(p);
      }
    }

    final List<DailyAttendanceSummary> daySummaries = [];
    int daysWorked = 0;
    int totalWorkMinutes = 0;
    int totalDelaysCount = 0;
    int totalDelayMinutes = 0;
    int totalAbsencesCount = 0;
    int totalAnomaliesCount = 0;
    int elapsedWorkingDaysCount = 0;

    DateTime current = DateTime(startDate.year, startDate.month, startDate.day);
    final last = DateTime(endDate.year, endDate.month, endDate.day);

    while (!current.isAfter(last)) {
      final dateStr = DateFormat('yyyy-MM-dd').format(current);
      final dateFR = DateFormat('dd/MM/yyyy').format(current);
      final dayName = frenchDays[current.weekday - 1];
      final isWeekend = current.weekday == 5 || current.weekday == 6; // Vendredi & Samedi
      
      final isFuture = dateStr.compareTo(todayStr) > 0;
      final isToday = dateStr == todayStr;
      final isPast = dateStr.compareTo(todayStr) < 0;

      final dayPunches = punchesByDay[dateStr] ?? [];
      
      // Calculate day details
      String? entryTime;
      String? exitTime;
      int workTimeMinutes = 0;
      int delayMinutes = 0;
      String status = 'Absence';
      String statusBadge = 'badge-danger';
      final List<String> anomalies = [];

      if (dayPunches.isNotEmpty) {
        entryTime = dayPunches.first.punchTime.length >= 16 ? dayPunches.first.punchTime.substring(11, 16) : null;
        exitTime = dayPunches.last.punchTime.length >= 16 ? dayPunches.last.punchTime.substring(11, 16) : null;

        if (dayPunches.length >= 2 && entryTime != null && exitTime != null && entryTime != exitTime) {
          final entryParts = entryTime.split(':').map(int.parse).toList();
          final exitParts = exitTime.split(':').map(int.parse).toList();
          final entryM = entryParts[0] * 60 + entryParts[1];
          final exitM = exitParts[0] * 60 + exitParts[1];
          workTimeMinutes = exitM > entryM ? (exitM - entryM) : 0;
        }

        // Delay calculation
        if (entryTime != null) {
          final parts = entryTime.split(':').map(int.parse).toList();
          final entryM = parts[0] * 60 + parts[1];
          final stdParts = standardStartTime.split(':').map(int.parse).toList();
          final stdM = stdParts[0] * 60 + stdParts[1];

          if (entryM > (stdM + graceMinutes)) {
            delayMinutes = entryM - stdM;
          }
        }

        // Status assignment
        if (delayMinutes > 0) {
          status = 'Présent (Retard)';
          statusBadge = 'badge-warning';
          totalDelaysCount++;
          totalDelayMinutes += delayMinutes;
        } else if (dayPunches.length == 1 && isToday) {
          status = 'Présent (En cours)';
          statusBadge = 'badge-info';
        } else {
          status = 'Présent';
          statusBadge = 'badge-success';
        }

        daysWorked++;
        totalWorkMinutes += workTimeMinutes;
      } else {
        // No punches on this day
        if (isFuture) {
          status = 'À venir';
          statusBadge = 'badge-muted';
        } else if (isWeekend) {
          status = 'Repos';
          statusBadge = 'badge-muted';
        } else if (isToday) {
          status = 'En attente';
          statusBadge = 'badge-warning';
        } else {
          status = 'Absence';
          statusBadge = 'badge-danger';
          totalAbsencesCount++;
          anomalies.add('Absence constatée');
        }
      }

      if (!isFuture && !isWeekend) {
        elapsedWorkingDaysCount++;
      }

      daySummaries.add(DailyAttendanceSummary(
        date: current,
        dateStr: dateStr,
        dateFR: dateFR,
        dayName: dayName,
        isWeekend: isWeekend,
        isFuture: isFuture,
        isToday: isToday,
        isPast: isPast,
        entryTime: entryTime ?? '--:--',
        exitTime: exitTime ?? '--:--',
        workTimeMinutes: workTimeMinutes,
        workTimeStr: formatMinutes(workTimeMinutes),
        delayMinutes: delayMinutes,
        delayStr: formatMinutes(delayMinutes),
        status: status,
        statusBadge: statusBadge,
        anomalies: anomalies,
        punches: dayPunches,
      ));

      current = current.add(const Duration(days: 1));
    }

    final presenceRate = elapsedWorkingDaysCount > 0
        ? ((daysWorked / elapsedWorkingDaysCount) * 100).clamp(0, 100).round()
        : 100;

    final avgDailyMinutes = daysWorked > 0 ? (totalWorkMinutes ~/ daysWorked) : 0;

    return MonthAttendanceReport(
      empCode: empCode,
      empName: empName,
      department: department,
      photoUrl: photoUrl,
      startDate: DateFormat('yyyy-MM-dd').format(startDate),
      endDate: DateFormat('yyyy-MM-dd').format(endDate),
      days: daySummaries,
      daysWorked: daysWorked,
      totalWorkMinutes: totalWorkMinutes,
      totalWorkHoursStr: formatMinutes(totalWorkMinutes),
      totalDelaysCount: totalDelaysCount,
      totalDelayMinutes: totalDelayMinutes,
      totalDelayDurationStr: formatMinutes(totalDelayMinutes),
      totalAbsencesCount: totalAbsencesCount,
      totalAnomaliesCount: totalAnomaliesCount,
      presenceRate: presenceRate,
      elapsedWorkingDaysCount: elapsedWorkingDaysCount,
      avgDailyWorkStr: formatMinutes(avgDailyMinutes),
    );
  }
}
