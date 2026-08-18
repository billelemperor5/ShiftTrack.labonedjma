import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/app_provider.dart';
import '../../services/attendance_calculator.dart';
import '../../services/zkbiotime_service.dart';
import '../../services/biotime_pdf_service.dart';
import '../../utils/image_helper.dart';
import '../home/main_menu_screen.dart';

class MonthlyAttendanceScreen extends StatefulWidget {
  const MonthlyAttendanceScreen({super.key});

  @override
  State<MonthlyAttendanceScreen> createState() => _MonthlyAttendanceScreenState();
}

class _MonthlyAttendanceScreenState extends State<MonthlyAttendanceScreen> {
  DateTime _selectedDate = DateTime.now();
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<AttendanceProvider>();
      final now = DateTime.now();
      if (provider.selectedMonth.year != now.year || provider.selectedMonth.month != now.month) {
        provider.setSelectedMonth(now);
      } else if (provider.currentReport == null) {
        provider.fetchAttendance(provider.currentEmpCode);
      }
    });
  }

  Future<void> _refreshData(AttendanceProvider provider, String empCode) async {
    setState(() => _isRefreshing = true);
    HapticFeedback.mediumImpact();
    await provider.fetchAttendance(empCode, forceSync: true);
    if (mounted) {
      setState(() => _isRefreshing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 22),
              SizedBox(width: 12),
              Text(
                'Pointages ZKBioTime synchronisés avec succès !',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF059669),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _showPdfExportOptions(BuildContext context, MonthAttendanceReport? report, AttendanceProvider provider) {
    if (report == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez patienter pendant le chargement des données.')),
      );
      return;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final currentMonthStr = DateFormat('MMMM yyyy', 'fr_FR').format(provider.selectedMonth).toUpperCase();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.fromLTRB(22, 16, 22, 28),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            border: Border.all(
              color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: onSurface.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFE11D48), Color(0xFFF43F5E)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.picture_as_pdf_rounded, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'EXPORTER LE RELEVÉ PDF',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: onSurface,
                            letterSpacing: -0.2,
                          ),
                        ),
                        Text(
                          'Document officiel certifié ZKBioTime',
                          style: TextStyle(
                            fontSize: 12,
                            color: onSurface.withValues(alpha: 0.55),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Option 1: Full Month
              _buildExportOptionTile(
                icon: Icons.calendar_month_rounded,
                iconColor: const Color(0xFF2563EB),
                title: 'Mois complet ($currentMonthStr)',
                subtitle: 'Tous les jours du mois (31 jours)',
                badge: '${report.daysWorked} jours pointés',
                onTap: () {
                  Navigator.of(ctx).pop();
                  BioTimePdfService.exportAttendancePdf(
                    report: report,
                    days: report.days,
                    periodTitle: currentMonthStr,
                  );
                },
                isDark: isDark,
                onSurface: onSurface,
              ),
              const SizedBox(height: 10),

              // Option 2: Punched Days Only
              _buildExportOptionTile(
                icon: Icons.fingerprint_rounded,
                iconColor: const Color(0xFF10B981),
                title: 'Pointages réels uniquement',
                subtitle: 'Exclut les week-ends et jours non travaillés',
                badge: '${report.daysWorked} jours',
                onTap: () {
                  Navigator.of(ctx).pop();
                  final workedDaysList = report.days.where((d) => d.punches.isNotEmpty || d.workTimeMinutes > 0).toList();
                  BioTimePdfService.exportAttendancePdf(
                    report: report,
                    days: workedDaysList,
                    periodTitle: '$currentMonthStr (Pointages effectifs)',
                  );
                },
                isDark: isDark,
                onSurface: onSurface,
              ),
              const SizedBox(height: 10),

              // Option 3: Custom Date Range
              _buildExportOptionTile(
                icon: Icons.date_range_rounded,
                iconColor: const Color(0xFF8B5CF6),
                title: 'Sélectionner une plage de dates',
                subtitle: 'Choisir une période personnalisée (ex: du 1 au 15)',
                badge: 'Personnalisé',
                onTap: () async {
                  Navigator.of(ctx).pop();
                  final firstDay = DateTime(provider.selectedMonth.year, provider.selectedMonth.month, 1);
                  final lastDay = DateTime(provider.selectedMonth.year, provider.selectedMonth.month + 1, 0);

                  final picked = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                    initialDateRange: DateTimeRange(
                      start: firstDay,
                      end: lastDay,
                    ),
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: const ColorScheme.light(
                            primary: Color(0xFF1E3A8A),
                            onPrimary: Colors.white,
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );

                  if (picked != null) {
                    final startStr = DateFormat('dd/MM/yyyy').format(picked.start);
                    final endStr = DateFormat('dd/MM/yyyy').format(picked.end);

                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            ),
                            const SizedBox(width: 12),
                            Text('Génération du relevé PDF ($startStr au $endStr)...'),
                          ],
                        ),
                        backgroundColor: const Color(0xFF1E3A8A),
                        duration: const Duration(seconds: 2),
                      ),
                    );

                    final customReport = await provider.fetchCustomRangeReport(
                      startDate: picked.start,
                      endDate: picked.end,
                    );

                    await BioTimePdfService.exportAttendancePdf(
                      report: customReport,
                      days: customReport.days,
                      periodTitle: '$startStr au $endStr',
                    );
                  }
                },
                isDark: isDark,
                onSurface: onSurface,
              ),
              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Annuler', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildExportOptionTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String badge,
    required VoidCallback onTap,
    required bool isDark,
    required Color onSurface,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                badge,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: iconColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDayDetailModal(BuildContext context, DateTime cellDate, DailyAttendanceSummary? summary) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final dateFmt = DateFormat('EEEE dd MMMM yyyy', 'fr_FR').format(cellDate);
    final hasPunches = summary != null && (summary.punches.isNotEmpty || summary.workTimeMinutes > 0);
    final punchesList = summary?.punches ?? <ZKBioTimePunch>[];
    final workRatio = summary != null ? (summary.workTimeMinutes / 480.0).clamp(0.0, 1.0) : 0.0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          padding: const EdgeInsets.fromLTRB(22, 16, 22, 28),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            border: Border.all(
              color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 24,
                offset: const Offset(0, -6),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: onSurface.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Header Row
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: hasPunches
                            ? [const Color(0xFF059669), const Color(0xFF10B981)]
                            : [const Color(0xFF64748B), const Color(0xFF94A3B8)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: (hasPunches ? const Color(0xFF10B981) : Colors.grey).withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.fingerprint_rounded, color: Colors.white, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dateFmt.toUpperCase(),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: onSurface,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: hasPunches ? const Color(0xFF10B981) : Colors.grey,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              hasPunches ? summary.status : 'Jour non pointé (Repos / Absent)',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: hasPunches ? const Color(0xFF10B981) : onSurface.withValues(alpha: 0.5),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // If has punches: Show Full Details
              if (hasPunches) ...[
                // 4 Metric Chips
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildModalMetricItem(
                          label: 'Entrée (1er)',
                          value: summary.entryTime ?? '--:--',
                          color: const Color(0xFF2563EB),
                          icon: Icons.login_rounded,
                          isDark: isDark,
                          onSurface: onSurface,
                        ),
                      ),
                      Container(width: 1, height: 38, color: onSurface.withValues(alpha: 0.1)),
                      Expanded(
                        child: _buildModalMetricItem(
                          label: 'Sortie (Dernier)',
                          value: summary.exitTime ?? '--:--',
                          color: const Color(0xFF10B981),
                          icon: Icons.logout_rounded,
                          isDark: isDark,
                          onSurface: onSurface,
                        ),
                      ),
                      Container(width: 1, height: 38, color: onSurface.withValues(alpha: 0.1)),
                      Expanded(
                        child: _buildModalMetricItem(
                          label: 'Temps Travaillé',
                          value: summary.workTimeStr,
                          color: const Color(0xFF0F766E),
                          icon: Icons.schedule_rounded,
                          isDark: isDark,
                          onSurface: onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Standard 8h Work Progression Bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Objectif journalier (8h00 standard)',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                          Text(
                            '${(workRatio * 100).toInt()}% accompli',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w900,
                              color: workRatio >= 1.0 ? const Color(0xFF10B981) : const Color(0xFF2563EB),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: LinearProgressIndicator(
                          value: workRatio,
                          minHeight: 7,
                          backgroundColor: onSurface.withValues(alpha: 0.1),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            workRatio >= 1.0 ? const Color(0xFF10B981) : const Color(0xFF2563EB),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Punches chronological log title
                Row(
                  children: [
                    const Icon(Icons.history_rounded, size: 18, color: Color(0xFF2563EB)),
                    const SizedBox(width: 8),
                    Text(
                      'Historique des pointages du jour (${punchesList.length})',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Punches list
                if (punchesList.isNotEmpty)
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: punchesList.length,
                      separatorBuilder: (_, index) => const SizedBox(height: 8),
                      itemBuilder: (context, idx) {
                        final p = punchesList[idx];
                        final isFirst = idx == 0;
                        final isLast = idx == punchesList.length - 1;
                        final punchType = isFirst
                            ? 'Pointage Entrée (Check-In)'
                            : (isLast ? 'Pointage Sortie (Check-Out)' : 'Pointage Intermédiaire');

                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white.withValues(alpha: 0.03) : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: (isFirst ? const Color(0xFF2563EB) : const Color(0xFF10B981)).withValues(alpha: 0.15),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      isFirst ? Icons.login_rounded : Icons.logout_rounded,
                                      size: 15,
                                      color: isFirst ? const Color(0xFF2563EB) : const Color(0xFF10B981),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        punchType,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                          color: onSurface,
                                        ),
                                      ),
                                      Text(
                                        p.terminalAlias.isNotEmpty ? p.terminalAlias : 'Terminal ZKTeco',
                                        style: TextStyle(
                                          fontSize: 10.5,
                                          color: onSurface.withValues(alpha: 0.5),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              Text(
                                p.punchTime.length >= 19 ? p.punchTime.substring(11, 19) : p.punchTime,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  color: isFirst ? const Color(0xFF2563EB) : const Color(0xFF10B981),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  )
                else
                  Text(
                    'Aucun détail brut disponible pour cette journée.',
                    style: TextStyle(fontSize: 12, color: onSurface.withValues(alpha: 0.5)),
                  ),
              ] else ...[
                // Empty state for non-working days
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.02) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.event_busy_rounded, size: 40, color: onSurface.withValues(alpha: 0.3)),
                      const SizedBox(height: 10),
                      Text(
                        'Aucun pointage biométrique enregistré pour ce jour',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Jour de repos, week-end ou absence non planifiée',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: onSurface.withValues(alpha: 0.4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 18),

              // Close button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3A8A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Fermer', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildModalMetricItem({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
    required bool isDark,
    required Color onSurface,
  }) {
    return Column(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.w600,
            color: onSurface.withValues(alpha: 0.5),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Consumer2<AttendanceProvider, AppProvider>(
      builder: (context, attendanceProvider, appProvider, child) {
        final report = attendanceProvider.currentReport;
        final profile = appProvider.userProfile;
        final isDesktop = MediaQuery.of(context).size.width > 900;
        final empCode = report?.empCode ?? attendanceProvider.currentEmpCode;
        final currentEmp = attendanceProvider.currentEmployee;
        final empName = (currentEmp?.fullName.isNotEmpty == true)
            ? currentEmp!.fullName
            : (report?.empName ?? profile?.firstName ?? (empCode.isNotEmpty ? 'Employé $empCode' : 'Employé'));
        final dept = (currentEmp?.department.isNotEmpty == true)
            ? currentEmp!.department
            : (report?.department ?? profile?.companyName ?? 'IT');

        return PopScope(
          canPop: true,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) {
              attendanceProvider.resetToCurrentMonth();
            }
          },
          child: Scaffold(
            backgroundColor: isDark ? const Color(0xFF0B1120) : const Color(0xFFF1F5F9),
            body: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // 1. Premium Colorful Luxury Topbar with Prominent Working Buttons
                SliverAppBar(
                  expandedHeight: 140,
                  pinned: true,
                  stretch: true,
                  elevation: 6,
                  backgroundColor: const Color(0xFF0F172A),
                  leading: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Material(
                      color: Colors.white.withValues(alpha: 0.22),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(color: Colors.white.withValues(alpha: 0.35)),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          attendanceProvider.resetToCurrentMonth();
                          if (Navigator.of(context).canPop()) {
                            Navigator.of(context).pop();
                          } else {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(builder: (_) => const MainMenuScreen()),
                            );
                          }
                        },
                        child: const Center(
                          child: Icon(Icons.arrow_back_rounded, color: Colors.white, size: 22),
                        ),
                      ),
                    ),
                  ),
                centerTitle: false,
                titleSpacing: 4,
                title: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6.5),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0D9488), Color(0xFF2563EB)],
                        ),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF2563EB).withValues(alpha: 0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.fingerprint_rounded, color: Colors.white, size: 16),
                    ),
                    const SizedBox(width: 8),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Suivi Présence',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.2,
                          ),
                        ),
                        Text(
                          'LA BONEDJIMA • BioTime',
                          style: TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                actions: [
                  // PDF Export Button
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0, bottom: 8.0, right: 8.0),
                    child: Material(
                      color: const Color(0xFFE11D48).withValues(alpha: 0.85),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(color: Colors.white.withValues(alpha: 0.35)),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () => _showPdfExportOptions(context, report, attendanceProvider),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.picture_as_pdf_rounded, color: Colors.white, size: 18),
                              SizedBox(width: 5),
                              Text(
                                'PDF',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 12.5,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Refresh Button
                  Padding(
                    padding: const EdgeInsets.only(right: 14.0, top: 8.0, bottom: 8.0),
                    child: Material(
                      color: Colors.white.withValues(alpha: 0.22),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(color: Colors.white.withValues(alpha: 0.35)),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: _isRefreshing
                            ? null
                            : () => _refreshData(attendanceProvider, empCode),
                        child: Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: _isRefreshing
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.2,
                                  ),
                                )
                              : const Icon(Icons.refresh_rounded, color: Colors.white, size: 22),
                        ),
                      ),
                    ),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF090E1A),
                          Color(0xFF1E1B4B),
                          Color(0xFF1E3A8A),
                          Color(0xFF0284C7),
                        ],
                      ),
                    ),
                    child: SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            // Glowing Avatar with ZKTeco Biometric Badge
                            Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: const LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [Color(0xFF06B6D4), Color(0xFF2563EB), Color(0xFF1E1B4B)],
                                    ),
                                    border: Border.all(color: Colors.white, width: 2.2),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF06B6D4).withValues(alpha: 0.5),
                                        blurRadius: 14,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: ClipOval(
                                     child: (currentEmp?.photoUrl != null && currentEmp!.photoUrl!.isNotEmpty)
                                          ? Image.network(
                                              currentEmp.photoUrl!,
                                              fit: BoxFit.cover,
                                              width: 56,
                                              height: 56,
                                              errorBuilder: (context, error, stackTrace) {
                                                return AppImageHelper.getImageWidget('', width: 56, height: 56);
                                              },
                                            )
                                          : AppImageHelper.getImageWidget('', width: 56, height: 56),
                                   ),
                                ),
                                Positioned(
                                  bottom: -2,
                                  right: -2,
                                  child: Container(
                                    padding: const EdgeInsets.all(3.5),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF10B981),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 2),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF10B981).withValues(alpha: 0.5),
                                          blurRadius: 6,
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.fingerprint_rounded,
                                      color: Colors.white,
                                      size: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 14),

                            // Employee Name, Matricule, & Department
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        empName,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 20,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: -0.2,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF10B981).withValues(alpha: 0.25),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(
                                            color: const Color(0xFF10B981).withValues(alpha: 0.5),
                                          ),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.circle, color: Color(0xFF34D399), size: 6),
                                            SizedBox(width: 4),
                                            Text(
                                              'ZKTeco Live',
                                              style: TextStyle(
                                                color: Color(0xFF6EE7B7),
                                                fontSize: 9.5,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          'Matricule: $empCode',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF38BDF8).withValues(alpha: 0.22),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          'Département: $dept',
                                          style: const TextStyle(
                                            color: Color(0xFFBAE6FD),
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // 2. Body: Month Navigator, Interactive Calendar Chart & Day Details
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1200),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Month Selector Bar & Summary Pills
                          _buildMonthNavigator(attendanceProvider, isDark, onSurface),
                          const SizedBox(height: 16),

                          // Main Content (Responsive Layout)
                          if (isDesktop)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 7,
                                  child: _buildCalendarCard(attendanceProvider, isDark, onSurface),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  flex: 5,
                                  child: Column(
                                    children: [
                                      _buildSelectedDayDetailCard(attendanceProvider, isDark, onSurface),
                                      const SizedBox(height: 14),
                                      _buildMonthInsightCard(report, isDark, onSurface),
                                    ],
                                  ),
                                ),
                              ],
                            )
                          else ...[
                            _buildCalendarCard(attendanceProvider, isDark, onSurface),
                            const SizedBox(height: 14),
                            _buildSelectedDayDetailCard(attendanceProvider, isDark, onSurface),
                            const SizedBox(height: 14),
                            _buildMonthInsightCard(report, isDark, onSurface),
                          ],
                        ],
                      ),
                      ),
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

  // Month Navigator with Rich Gradient and Status Badges
  Widget _buildMonthNavigator(AttendanceProvider provider, bool isDark, Color onSurface) {
    final monthStr = DateFormat('MMMM yyyy', 'fr_FR').format(provider.selectedMonth);
    final report = provider.currentReport;
    final workedDays = report?.daysWorked ?? 0;

    return Row(
      children: [
        // Month Pill with < Month >
        Expanded(
          flex: 6,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4338CA), Color(0xFF6366F1), Color(0xFF8B5CF6)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left_rounded, color: Colors.white, size: 24),
                  onPressed: provider.previousMonth,
                  tooltip: 'Mois précédent',
                ),
                Row(
                  children: [
                    const Icon(Icons.calendar_month_rounded, color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      monthStr.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 14.5,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right_rounded, color: Colors.white, size: 24),
                  onPressed: provider.nextMonth,
                  tooltip: 'Mois suivant',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),

        // Status Badge: Worked Days
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withValues(alpha: isDark ? 0.2 : 0.14),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF10B981).withValues(alpha: 0.15),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 9,
                height: 9,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF10B981),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$workedDays Présent',
                style: const TextStyle(
                  color: Color(0xFF059669),
                  fontWeight: FontWeight.w900,
                  fontSize: 13.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // The Interactive Monthly Calendar Grid
  Widget _buildCalendarCard(AttendanceProvider provider, bool isDark, Color onSurface) {
    final currentMonth = provider.selectedMonth;
    final firstDayOfMonth = DateTime(currentMonth.year, currentMonth.month, 1);
    final daysInMonth = DateTime(currentMonth.year, currentMonth.month + 1, 0).day;
    final prefixSlots = (firstDayOfMonth.weekday - 1);
    final totalCells = prefixSlots + daysInMonth;
    final rowCount = (totalCells / 7).ceil();
    final weekdays = ['lun.', 'mar.', 'mer.', 'jeu.', 'ven.', 'sam.', 'dim.'];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111827) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0F766E), Color(0xFF10B981)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.calendar_today_rounded, color: Colors.white, size: 16),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Calendrier Mensuel des Pointages',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: onSurface,
                    ),
                  ),
                ],
              ),
              Text(
                DateFormat('MMMM yyyy', 'fr_FR').format(currentMonth),
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: onSurface.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Weekdays header row
          Row(
            children: weekdays.map((w) {
              final isWeekend = w == 'ven.' || w == 'sam.';
              return Expanded(
                child: Center(
                  child: Text(
                    w,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: isWeekend ? const Color(0xFFF43F5E) : onSurface.withValues(alpha: 0.45),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),

          // Calendar Grid Cells
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: rowCount * 7,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.0,
            ),
            itemBuilder: (context, index) {
              final dayNumber = index - prefixSlots + 1;
              if (dayNumber < 1 || dayNumber > daysInMonth) {
                return const SizedBox();
              }

              final cellDate = DateTime(currentMonth.year, currentMonth.month, dayNumber);
              final summary = provider.getDaySummaryForDate(cellDate);
              final hasPunches = summary != null && (summary.punches.isNotEmpty || summary.workTimeMinutes > 0);
              final isSelected = cellDate.year == _selectedDate.year &&
                  cellDate.month == _selectedDate.month &&
                  cellDate.day == _selectedDate.day;

              return InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _selectedDate = cellDate;
                  });
                  // Open professional detail modal
                  _showDayDetailModal(context, cellDate, summary);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  decoration: BoxDecoration(
                    color: hasPunches
                        ? (isSelected ? const Color(0xFF047857) : const Color(0xFF10B981))
                        : (isSelected
                            ? const Color(0xFF2563EB)
                            : (isDark ? Colors.white.withValues(alpha: 0.03) : const Color(0xFFF8FAFC))),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected
                          ? Colors.white
                          : (hasPunches
                              ? const Color(0xFF10B981).withValues(alpha: 0.7)
                              : (isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFE2E8F0))),
                      width: isSelected ? 2.2 : 1,
                    ),
                    boxShadow: hasPunches
                        ? [
                            BoxShadow(
                              color: const Color(0xFF10B981).withValues(alpha: 0.32),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : (isSelected
                            ? [
                                BoxShadow(
                                  color: const Color(0xFF2563EB).withValues(alpha: 0.35),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : null),
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Text(
                          '$dayNumber',
                          style: TextStyle(
                            color: hasPunches || isSelected ? Colors.white : onSurface.withValues(alpha: 0.72),
                            fontWeight: hasPunches || isSelected ? FontWeight.w900 : FontWeight.w600,
                            fontSize: 14.5,
                          ),
                        ),
                      ),
                      if (hasPunches)
                        Positioned(
                          top: 4,
                          right: 4,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                            ),
                            child: const Icon(Icons.check, size: 9, color: Color(0xFF059669)),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // Selected Day Details Card (Inline Preview)
  Widget _buildSelectedDayDetailCard(AttendanceProvider provider, bool isDark, Color onSurface) {
    final summary = provider.getDaySummaryForDate(_selectedDate);
    final dateFmt = DateFormat('EEEE dd MMMM yyyy', 'fr_FR').format(_selectedDate);
    final hasPunches = summary != null && (summary.punches.isNotEmpty || summary.workTimeMinutes > 0);

    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: () => _showDayDetailModal(context, _selectedDate, summary),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF111827) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: hasPunches
                ? const Color(0xFF10B981).withValues(alpha: 0.4)
                : (isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0)),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: hasPunches
                            ? const Color(0xFF10B981).withValues(alpha: 0.18)
                            : onSurface.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.fingerprint_rounded,
                        color: hasPunches ? const Color(0xFF10B981) : onSurface.withValues(alpha: 0.5),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dateFmt,
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w900,
                            color: onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          hasPunches ? summary.status : 'Jour non pointé (Repos / Non travaillé)',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: hasPunches ? const Color(0xFF10B981) : onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                if (hasPunches)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.35)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          summary.workTimeStr,
                          style: const TextStyle(
                            color: Color(0xFF047857),
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Color(0xFF047857)),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            if (hasPunches) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.03) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildMetricMini(
                        label: 'Entrée',
                        value: summary.entryTime ?? '--:--',
                        color: const Color(0xFF2563EB),
                        isDark: isDark,
                        onSurface: onSurface,
                      ),
                    ),
                    Container(width: 1, height: 34, color: onSurface.withValues(alpha: 0.1)),
                    Expanded(
                      child: _buildMetricMini(
                        label: 'Sortie',
                        value: summary.exitTime ?? '--:--',
                        color: const Color(0xFF10B981),
                        isDark: isDark,
                        onSurface: onSurface,
                      ),
                    ),
                    Container(width: 1, height: 34, color: onSurface.withValues(alpha: 0.1)),
                    Expanded(
                      child: _buildMetricMini(
                        label: 'Temps Total',
                        value: summary.workTimeStr,
                        color: const Color(0xFF0F766E),
                        isDark: isDark,
                        onSurface: onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.02) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    'Aucun pointage enregistré pour cette date',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: onSurface.withValues(alpha: 0.45),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMetricMini({
    required String label,
    required String value,
    required Color color,
    required bool isDark,
    required Color onSurface,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: onSurface.withValues(alpha: 0.5),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
      ],
    );
  }

  // Monthly Overview Card (Résumé du mois)
  Widget _buildMonthInsightCard(MonthAttendanceReport? report, bool isDark, Color onSurface) {
    final workedDays = report?.daysWorked ?? 0;
    final totalHoursStr = report?.totalWorkHoursStr ?? '00h00';
    final presenceRate = '${report?.presenceRate ?? 100}%';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111827) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 10),
              Text(
                'Résumé du mois',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _buildInsightPill(
                  title: 'Présence',
                  value: presenceRate,
                  subtitle: '$workedDays jours travaillés',
                  icon: Icons.trending_up_rounded,
                  color: const Color(0xFF10B981),
                  isDark: isDark,
                  onSurface: onSurface,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInsightPill(
                  title: 'Heures totales',
                  value: totalHoursStr,
                  subtitle: 'Cumul du mois',
                  icon: Icons.schedule_rounded,
                  color: const Color(0xFF3B82F6),
                  isDark: isDark,
                  onSurface: onSurface,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInsightPill({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isDark,
    required Color onSurface,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.12 : 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: onSurface.withValues(alpha: 0.6),
                ),
              ),
              Icon(icon, size: 17, color: color),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: onSurface.withValues(alpha: 0.48),
            ),
          ),
        ],
      ),
    );
  }
}
