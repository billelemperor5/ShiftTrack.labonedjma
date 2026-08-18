import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/attendance_record.dart';
import '../services/zkbiotime_service.dart';
import '../services/attendance_calculator.dart';

class AttendanceProvider extends ChangeNotifier {
  final ZKBioTimeService _service = ZKBioTimeService();

  MonthAttendanceReport? _currentReport;
  MonthAttendanceReport? _currentMonthReport;
  ZKBioTimeEmployee? _currentEmployee;
  bool _isLoading = false;
  String? _errorMessage;
  DateTime _selectedMonth = DateTime.now();
  String _viewFilter = 'bioOnly'; // 'bioOnly' or 'all'
  String _currentEmpCode = '';

  MonthAttendanceReport? get currentReport => _currentReport;
  MonthAttendanceReport? get currentMonthReport => _currentMonthReport ?? _currentReport;
  ZKBioTimeEmployee? get currentEmployee => _currentEmployee;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  DateTime get selectedMonth => _selectedMonth;
  DateTime get viewedMonth => _selectedMonth;
  String get viewFilter => _viewFilter;
  String get currentEmpCode => _currentEmpCode;

  /// Returns only days with actual punches/work, so unpunched days remain empty and neutral
  List<AttendanceRecord> get records {
    if (_currentReport == null) return [];
    return _currentReport!.days
        .where((d) => d.punches.isNotEmpty || d.workTimeMinutes > 0)
        .map((d) {
      return AttendanceRecord(
        date: d.date,
        status: AttendanceStatus.present,
        checkIn: d.entryTime != '--:--' ? d.entryTime : null,
        checkOut: d.exitTime != '--:--' ? d.exitTime : null,
        hours: d.workTimeMinutes / 60.0,
        scheduledHours: 8.0,
      );
    }).toList();
  }

  /// Returns records specifically for the real current month (for Home Banner)
  List<AttendanceRecord> get currentMonthRecords {
    final rep = _currentMonthReport ?? _currentReport;
    if (rep == null) return [];
    return rep.days
        .where((d) => d.punches.isNotEmpty || d.workTimeMinutes > 0)
        .map((d) {
      return AttendanceRecord(
        date: d.date,
        status: AttendanceStatus.present,
        checkIn: d.entryTime != '--:--' ? d.entryTime : null,
        checkOut: d.exitTime != '--:--' ? d.exitTime : null,
        hours: d.workTimeMinutes / 60.0,
        scheduledHours: 8.0,
      );
    }).toList();
  }

  List<DailyAttendanceSummary> get filteredDays {
    if (_currentReport == null) return [];
    if (_viewFilter == 'bioOnly') {
      return _currentReport!.days.where((d) => d.punches.isNotEmpty).toList();
    }
    return _currentReport!.days;
  }

  void setViewFilter(String filter) {
    if (_viewFilter != filter) {
      _viewFilter = filter;
      notifyListeners();
    }
  }

  void setViewedMonth(DateTime date) {
    setSelectedMonth(date);
  }

  void setSelectedMonth(DateTime month) {
    _selectedMonth = month;
    fetchAttendance(_currentEmpCode);
  }

  void nextMonth() {
    _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 1);
    fetchAttendance(_currentEmpCode);
  }

  void previousMonth() {
    _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1, 1);
    fetchAttendance(_currentEmpCode);
  }

  void resetToCurrentMonth({bool forceFetch = false}) {
    final now = DateTime.now();
    final isDifferentMonth = _selectedMonth.year != now.year || _selectedMonth.month != now.month;
    if (isDifferentMonth || forceFetch) {
      _selectedMonth = now;
      if (_currentEmpCode.isNotEmpty) {
        fetchAttendance(_currentEmpCode);
      } else {
        notifyListeners();
      }
    }
  }

  void refresh() {
    fetchAttendance(_currentEmpCode, forceSync: true);
  }

  DailyAttendanceSummary? getDaySummaryForDate(DateTime date) {
    if (_currentReport == null) return null;
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    try {
      return _currentReport!.days.firstWhere(
        (d) => DateFormat('yyyy-MM-dd').format(d.date) == dateStr,
      );
    } catch (_) {
      return null;
    }
  }

  AttendanceRecord? getRecordForDate(DateTime date) {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    final recList = records;
    try {
      return recList.firstWhere(
        (r) => DateFormat('yyyy-MM-dd').format(r.date) == dateStr,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> addOrUpdateRecord(AttendanceRecord record) async {
    notifyListeners();
  }

  Future<void> deleteRecord(DateTime date) async {
    notifyListeners();
  }

  Future<ZKBioTimeEmployee?> fetchAttendance(String empCode, {bool forceSync = false}) async {
    _currentEmpCode = empCode;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Determine date range for selected month
      final firstDay = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
      final lastDay = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0);

      final startDateStr = DateFormat('yyyy-MM-dd').format(firstDay);
      final endDateStr = DateFormat('yyyy-MM-dd').format(lastDay);

      debugPrint('🔍 [fetchAttendance] empCode=$empCode, range=$startDateStr → $endDateStr');

      // 2. Fetch transactions and employee metadata from ZKBioTime
      final punches = await _service.getTransactions(
        empCode: empCode,
        startDate: startDateStr,
        endDate: endDateStr,
      );
      debugPrint('🔍 [fetchAttendance] punches=${punches.length}');

      ZKBioTimeEmployee? emp = _service.currentUser;
      debugPrint('🔍 [fetchAttendance] _service.currentUser empCode=${emp?.empCode}, fullName=${emp?.fullName}, dept=${emp?.department}');
      
      if (emp == null || emp.empCode != empCode) {
        debugPrint('🔍 [fetchAttendance] currentUser mismatch or null, calling getEmployee($empCode)...');
        emp = await _service.getEmployee(empCode);
        debugPrint('🔍 [fetchAttendance] getEmployee result: empCode=${emp?.empCode}, fullName=${emp?.fullName}, dept=${emp?.department}');
      }
      _currentEmployee = emp;

      final empName = emp?.fullName.isNotEmpty == true
          ? emp!.fullName
          : (emp?.firstName.isNotEmpty == true ? '${emp!.firstName} ${emp.lastName}'.trim() : 'Employé $empCode');
      final department = emp?.department.isNotEmpty == true ? emp!.department : 'Direction';

      debugPrint('✅ [fetchAttendance] FINAL empName=$empName, department=$department');

      // 3. Calculate attendance
      final processedReport = AttendanceCalculator.processRange(
        empCode: empCode,
        empName: empName,
        department: department,
        photoUrl: emp?.photoUrl,
        startDate: firstDay,
        endDate: lastDay,
        punches: punches,
      );

      _currentReport = processedReport;
      final now = DateTime.now();
      if (_selectedMonth.year == now.year && _selectedMonth.month == now.month) {
        _currentMonthReport = processedReport;
      }

      _errorMessage = null;
      return emp;
    } catch (e) {
      _errorMessage = 'Erreur de chargement des pointages: $e';
      debugPrint('❌ [fetchAttendance] ERROR: $e');
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<MonthAttendanceReport> fetchCustomRangeReport({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final empCode = _currentEmpCode;
    ZKBioTimeEmployee? emp = await _service.getEmployee(empCode);
    final empName = emp?.fullName.isNotEmpty == true
        ? emp!.fullName
        : (emp?.firstName.isNotEmpty == true ? emp!.firstName : 'Employé $empCode');
    final department = emp?.department ?? 'IT';

    final startDateStr = DateFormat('yyyy-MM-dd').format(startDate);
    final endDateStr = DateFormat('yyyy-MM-dd').format(endDate);

    final punches = await _service.getTransactions(
      empCode: empCode,
      startDate: startDateStr,
      endDate: endDateStr,
    );

    return AttendanceCalculator.processRange(
      empCode: empCode,
      empName: empName,
      department: department,
      photoUrl: emp?.photoUrl,
      startDate: startDate,
      endDate: endDate,
      punches: punches,
    );
  }
}
