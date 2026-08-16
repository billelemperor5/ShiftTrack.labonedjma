import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../models/team_member.dart';
import '../services/attendance_calculator.dart';
import '../services/hive_service.dart';
import '../services/zkbiotime_service.dart';

class MemberDailyStats {
  final bool hasPunchedToday;
  final bool isCurrentlyWorking;
  final String checkIn;
  final String checkOut;
  final double hours;

  const MemberDailyStats({
    required this.hasPunchedToday,
    required this.isCurrentlyWorking,
    required this.checkIn,
    required this.checkOut,
    required this.hours,
  });
}

class MemberPeriodStats {
  final double totalHours;
  final int daysWorked;
  final double avgHours;

  const MemberPeriodStats({
    required this.totalHours,
    required this.daysWorked,
    required this.avgHours,
  });
}

class TeamProvider extends ChangeNotifier {
  final ZKBioTimeService _service = ZKBioTimeService();
  final List<TeamMember> _members = [];
  final Map<String, MonthAttendanceReport> _reports = {};
  bool _isLoading = false;
  String? _errorMessage;
  String _currentOwner = '';

  List<TeamMember> get members => List.unmodifiable(_members);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get currentOwner => _currentOwner;

  TeamProvider() {
    _loadMembers();
  }

  void setOwner(String ownerEmpCode) {
    final clean = ownerEmpCode.trim();
    if (_currentOwner == clean) return;
    _currentOwner = clean;
    _loadMembers();
  }

  void _loadMembers() {
    try {
      final box = HiveService.getTeamMembersBox();
      _members.clear();
      _reports.clear();

      for (final key in box.keys) {
        final val = box.get(key);
        if (val != null && val.isNotEmpty) {
          try {
            final member = TeamMember.fromJsonString(val);
            // If current owner is set, show only members added by this owner
            if (_currentOwner.isEmpty || member.ownerEmpCode == null || member.ownerEmpCode == _currentOwner) {
              _members.add(member);
            }
          } catch (e) {
            debugPrint('[TeamProvider] Error parsing member $key: $e');
          }
        }
      }
      notifyListeners();
      if (_members.isNotEmpty) {
        _fetchAllStats();
      }
    } catch (e) {
      debugPrint('[TeamProvider] Error loading members: $e');
    }
  }

  Future<MonthAttendanceReport?> _fetchEmployeeReport(String empCode) async {
    try {
      final now = DateTime.now();
      final firstDay = DateTime(now.year, now.month, 1);
      final lastDay = DateTime(now.year, now.month + 1, 0);
      final startDateStr = DateFormat('yyyy-MM-dd').format(firstDay);
      final endDateStr = DateFormat('yyyy-MM-dd').format(lastDay);

      final punches = await _service.getTransactions(
        empCode: empCode,
        startDate: startDateStr,
        endDate: endDateStr,
      );

      final emp = await _service.getEmployee(empCode);
      final empName = emp?.fullName.isNotEmpty == true
          ? emp!.fullName
          : (emp?.firstName.isNotEmpty == true ? '${emp!.firstName} ${emp.lastName}'.trim() : 'Employé $empCode');
      final department = emp?.department.isNotEmpty == true ? emp!.department : 'LA BONEDJIMA';

      final report = AttendanceCalculator.processRange(
        empCode: empCode,
        empName: empName,
        department: department,
        photoUrl: emp?.photoUrl,
        startDate: firstDay,
        endDate: lastDay,
        punches: punches,
      );

      return report;
    } catch (e) {
      debugPrint('[TeamProvider] Error fetching report for $empCode: $e');
      return null;
    }
  }

  Future<void> _fetchAllStats() async {
    for (final member in _members) {
      if (!_reports.containsKey(member.empCode)) {
        final rep = await _fetchEmployeeReport(member.empCode);
        if (rep != null) {
          _reports[member.empCode] = rep;
          notifyListeners();
        }
      }
    }
  }

  Future<bool> addMemberByMatricule(String rawEmpCode, {String? ownerEmpCode}) async {
    final empCode = rawEmpCode.trim();
    final owner = (ownerEmpCode ?? _currentOwner).trim();

    if (empCode.isEmpty) {
      _errorMessage = 'Veuillez saisir un numéro de matricule valide';
      notifyListeners();
      return false;
    }

    if (_members.any((m) => m.empCode == empCode)) {
      _errorMessage = 'Ce collaborateur (Matricule $empCode) est déjà dans votre liste';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final emp = await _service.getEmployee(empCode);
      final report = await _fetchEmployeeReport(empCode);

      final fName = emp?.firstName.isNotEmpty == true ? emp!.firstName : 'Employé';
      final lName = emp?.lastName.isNotEmpty == true ? emp!.lastName : empCode;
      final dept = emp?.department.isNotEmpty == true ? emp!.department : 'LA BONEDJIMA';
      final pos = emp?.position.isNotEmpty == true ? emp!.position : 'Collaborateur';

      final member = TeamMember(
        empCode: empCode,
        firstName: fName,
        lastName: lName,
        department: dept,
        position: pos,
        photo: emp?.photo,
        addedAt: DateTime.now(),
        ownerEmpCode: owner.isNotEmpty ? owner : null,
      );

      final box = HiveService.getTeamMembersBox();
      final storageKey = owner.isNotEmpty ? '${owner}_$empCode' : empCode;
      await box.put(storageKey, member.toJsonString());

      _members.insert(0, member);
      if (report != null) {
        _reports[empCode] = report;
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Impossible de vérifier le matricule $empCode. Vérifiez la connexion ou le numéro.';
      notifyListeners();
      return false;
    }
  }

  Future<void> removeMember(String empCode, {String? ownerEmpCode}) async {
    final owner = (ownerEmpCode ?? _currentOwner).trim();
    final box = HiveService.getTeamMembersBox();
    final storageKey = owner.isNotEmpty ? '${owner}_$empCode' : empCode;
    await box.delete(storageKey);
    await box.delete(empCode);
    _members.removeWhere((m) => m.empCode == empCode);
    _reports.remove(empCode);
    notifyListeners();
  }

  Future<void> refreshMember(String empCode) async {
    final rep = await _fetchEmployeeReport(empCode);
    if (rep != null) {
      _reports[empCode] = rep;
      notifyListeners();
    }
  }

  MonthAttendanceReport? getMemberReport(String empCode) => _reports[empCode];

  MemberDailyStats getTodayStats(String empCode) {
    final report = _reports[empCode];
    if (report == null || report.days.isEmpty) {
      return const MemberDailyStats(
        hasPunchedToday: false,
        isCurrentlyWorking: false,
        checkIn: '--:--',
        checkOut: '--:--',
        hours: 0.0,
      );
    }

    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    DailyAttendanceSummary? todaySummary;
    try {
      todaySummary = report.days.firstWhere(
        (d) => DateFormat('yyyy-MM-dd').format(d.date) == todayStr,
      );
    } catch (_) {
      todaySummary = null;
    }

    if (todaySummary == null || todaySummary.punches.isEmpty) {
      return const MemberDailyStats(
        hasPunchedToday: false,
        isCurrentlyWorking: false,
        checkIn: '--:--',
        checkOut: '--:--',
        hours: 0.0,
      );
    }

    final inTime = todaySummary.entryTime ?? '--:--';
    final outTime = todaySummary.exitTime ?? '--:--';
    final isWorking = inTime != '--:--' && (outTime == '--:--' || outTime == inTime);
    final hours = todaySummary.workTimeMinutes / 60.0;

    return MemberDailyStats(
      hasPunchedToday: true,
      isCurrentlyWorking: isWorking,
      checkIn: inTime,
      checkOut: outTime,
      hours: hours,
    );
  }

  MemberPeriodStats getWeekStats(String empCode) {
    final report = _reports[empCode];
    if (report == null || report.days.isEmpty) {
      return const MemberPeriodStats(totalHours: 0, daysWorked: 0, avgHours: 0);
    }

    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final startOfWeek = DateTime(monday.year, monday.month, monday.day);
    final endOfWeek = startOfWeek.add(const Duration(days: 7));

    final weekDays = report.days.where((d) {
      return (d.date.isAfter(startOfWeek) || d.date.isAtSameMomentAs(startOfWeek)) &&
          d.date.isBefore(endOfWeek) &&
          (d.punches.isNotEmpty || d.workTimeMinutes > 0);
    }).toList();

    final totalMinutes = weekDays.fold<int>(0, (sum, d) => sum + d.workTimeMinutes);
    final hours = totalMinutes / 60.0;
    final daysCount = weekDays.length;

    return MemberPeriodStats(
      totalHours: hours,
      daysWorked: daysCount,
      avgHours: daysCount > 0 ? hours / daysCount : 0.0,
    );
  }

  MemberPeriodStats getMonthStats(String empCode) {
    final report = _reports[empCode];
    if (report == null || report.days.isEmpty) {
      return const MemberPeriodStats(totalHours: 0, daysWorked: 0, avgHours: 0);
    }

    final monthDays = report.days.where((d) => d.punches.isNotEmpty || d.workTimeMinutes > 0).toList();
    final totalMinutes = monthDays.fold<int>(0, (sum, d) => sum + d.workTimeMinutes);
    final hours = totalMinutes / 60.0;
    final daysCount = monthDays.length;

    return MemberPeriodStats(
      totalHours: hours,
      daysWorked: daysCount,
      avgHours: daysCount > 0 ? hours / daysCount : 0.0,
    );
  }
}
