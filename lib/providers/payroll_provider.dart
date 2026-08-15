import 'package:flutter/material.dart';
import '../models/payroll_slip.dart';
import '../services/hive_service.dart';

class PayrollProvider with ChangeNotifier {
  List<PayrollSlip> _slips = [];
  List<PayrollSlip> get slips => _slips;

  PayrollProvider() {
    _loadSlips();
  }

  void refresh() => _loadSlips();

  void _loadSlips() {
    final box = HiveService.getPayrollBox();
    _slips = box.values.toList();
    // Sort by date descending
    _slips.sort((a, b) => b.date.compareTo(a.date));
    notifyListeners();
  }

  Future<void> addSlip(PayrollSlip slip) async {
    final box = HiveService.getPayrollBox();
    await box.add(slip);
    _loadSlips();
  }

  Future<void> deleteSlip(PayrollSlip slip) async {
    await slip.delete();
    _loadSlips();
  }
}
