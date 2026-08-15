import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../providers/app_provider.dart';
import '../../../providers/attendance_provider.dart';
import '../../../services/export_service.dart';
import '../../analytics/analytics_screen.dart';
import '../../../core/theme/app_design.dart';

import '../../../models/attendance_record.dart';

class DashboardHeader extends StatelessWidget {
  const DashboardHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        final profile = provider.userProfile;
        if (profile == null) return const SizedBox.shrink();

        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: AppDesign.heroGradient(isDark),
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : const Color(0xFFE2E8F0),
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.5)
                    : Colors.black.withValues(alpha: 0.06),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bonjour, ${profile.firstName}',
                      style: TextStyle(
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      profile.companyName?.isNotEmpty == true
                          ? profile.companyName!
                          : 'Bonne journée de travail',
                      style: TextStyle(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.7)
                            : const Color(0xFF475569),
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Row(
                children: [
                  _buildActionButton(context, Icons.bar_chart, isDark, () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AnalyticsScreen(),
                      ),
                    );
                  }),
                  const SizedBox(width: 8),
                  _buildActionButton(context, Icons.share, isDark, () {
                    _showExportDialog(context, profile);
                  }),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    IconData icon,
    bool isDark,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.15)
              : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.25)
                : const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
        child: Icon(
          icon,
          color: isDark ? Colors.white.withValues(alpha: 0.9) : const Color(0xFF0F172A),
          size: 22,
        ),
      ),
    );
  }

  void _showExportDialog(BuildContext context, dynamic profile) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Exporter le rapport',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(
                  'Choisissez le format pour exporter vos données',
                  style: TextStyle(color: Colors.grey.shade400),
                ),
                const SizedBox(height: 32),
                InkWell(
                  onTap: () async {
                    Navigator.pop(ctx);
                    final attendance = context.read<AttendanceProvider>();
                    final selectedMonth = attendance.viewedMonth;
                    final records = attendance.records
                        .where(
                          (r) =>
                              r.date.month == selectedMonth.month &&
                              r.date.year == selectedMonth.year,
                        )
                        .toList();

                    final startOfMonth = DateTime(
                      selectedMonth.year,
                      selectedMonth.month,
                      1,
                    );
                    final endOfMonth = DateTime(
                      selectedMonth.year,
                      selectedMonth.month + 1,
                      0,
                    );

                    await ExportService.exportToPdf(
                      profile,
                      records,
                      startOfMonth,
                      endOfMonth,
                    );
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.red.withValues(alpha: 0.3),
                      ),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.red.withValues(alpha: 0.05),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.picture_as_pdf,
                          color: Colors.red,
                          size: 32,
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Text(
                            'Mois actuel (PDF)',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.red,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.red,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () async {
                    Navigator.pop(ctx);
                    final attendance = context.read<AttendanceProvider>();
                    final selectedMonth = attendance.viewedMonth;
                    final startOfMonth = DateTime(
                      selectedMonth.year,
                      selectedMonth.month,
                      1,
                    );
                    final endOfMonth = DateTime(
                      selectedMonth.year,
                      selectedMonth.month + 1,
                      0,
                    );

                    final records = attendance.records
                        .where(
                          (r) =>
                              r.date.month == selectedMonth.month &&
                              r.date.year == selectedMonth.year,
                        )
                        .toList();

                    await ExportService.exportToExcel(
                      profile,
                      records,
                      startOfMonth,
                      endOfMonth,
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Enregistré dans les documents'),
                        ),
                      );
                    }
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.green.withValues(alpha: 0.3),
                      ),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.green.withValues(alpha: 0.05),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.table_chart,
                          color: Colors.green,
                          size: 32,
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Text(
                            'Mois actuel (Excel)',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.green,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.green,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () {
                    Navigator.pop(ctx);
                    _showDateRangeBottomSheet(context, profile);
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.orange.withValues(alpha: 0.3),
                      ),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.orange.withValues(alpha: 0.05),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.date_range,
                          color: Colors.orange,
                          size: 32,
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Text(
                            'Période personnalisée',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.orange,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.orange,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showDateRangeBottomSheet(BuildContext context, dynamic profile) {
    DateTime start = DateTime.now().subtract(const Duration(days: 30));
    DateTime end = DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                24,
                24,
                24,
                MediaQuery.of(context).viewInsets.bottom + 32,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Choisir la période',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: _buildDateTile(context, 'Du', start, () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: start,
                            firstDate: DateTime(2023),
                            lastDate: DateTime(2030),
                            locale: const Locale('fr'),
                          );
                          if (picked != null) setState(() => start = picked);
                        }),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildDateTile(context, 'Au', end, () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: end,
                            firstDate: DateTime(2023),
                            lastDate: DateTime(2030),
                            locale: const Locale('fr'),
                          );
                          if (picked != null) setState(() => end = picked);
                        }),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        final attendance = context.read<AttendanceProvider>();
                        final records = attendance.records
                            .where(
                              (r) =>
                                  (r.date.isAfter(start) ||
                                      r.date.isAtSameMomentAs(start)) &&
                                  (r.date.isBefore(end) ||
                                      r.date.isAtSameMomentAs(end)),
                            )
                            .toList();
                        _showFormatPickerForRange(
                          context,
                          profile,
                          records,
                          start,
                          end,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Confirmer la période',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDateTile(
    BuildContext context,
    String label,
    DateTime date,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Theme.of(context).colorScheme.outline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('dd/MM/yyyy').format(date),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  void _showFormatPickerForRange(
    BuildContext context,
    dynamic profile,
    List<AttendanceRecord> records,
    DateTime start,
    DateTime end,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                title: const Text('Exporter PDF'),
                onTap: () async {
                  Navigator.pop(ctx);
                  await ExportService.exportToPdf(profile, records, start, end);
                },
              ),
              ListTile(
                leading: const Icon(Icons.table_chart, color: Colors.green),
                title: const Text('Exporter Excel'),
                onTap: () async {
                  Navigator.pop(ctx);
                  await ExportService.exportToExcel(
                    profile,
                    records,
                    start,
                    end,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
