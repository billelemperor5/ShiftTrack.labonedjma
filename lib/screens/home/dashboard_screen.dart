import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_design.dart';
import '../../core/utils/time_utils.dart';
import '../../models/attendance_record.dart';
import '../../models/user_profile.dart';
import '../../providers/app_provider.dart';
import '../../providers/attendance_provider.dart';
import '../../services/export_service.dart';
import '../analytics/analytics_screen.dart';
import 'widgets/attendance_bottom_sheet.dart';
import 'widgets/calendar_widget.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Container(
          decoration: AppDesign.pageBackground(isDark),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                _AttendanceHeader(onExport: _showExportDialog),
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1200),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 112),
                      child: Builder(
                        builder: (context) {
                          final width = MediaQuery.of(context).size.width;
                          final isDesktop = width > 850;
                          if (isDesktop) {
                            return const Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 7,
                                  child: CalendarWidget(),
                                ),
                                SizedBox(width: 16),
                                Expanded(
                                  flex: 5,
                                  child: _MonthlyInsightCard(),
                                ),
                              ],
                            );
                          }
                          return const Column(
                            children: [
                              CalendarWidget(),
                              SizedBox(height: 16),
                              _MonthlyInsightCard(),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        floatingActionButton: _PremiumFab(
          onTap: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              builder: (ctx) =>
                  AttendanceBottomSheet(selectedDate: DateTime.now()),
            );
          },
        ),
      ),
    );
  }

  void _showExportDialog(BuildContext context, UserProfile? profile) {
    if (profile == null) return;
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
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(
                  'Choisissez le format',
                  style: TextStyle(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.48),
                  ),
                ),
                const SizedBox(height: 24),
                _exportTile(
                  context,
                  ctx,
                  Icons.picture_as_pdf_rounded,
                  'PDF',
                  'Mois actuel',
                  const Color(0xFFEF4444),
                  () async {
                    Navigator.pop(ctx);
                    final attendance = context.read<AttendanceProvider>();
                    final month = attendance.viewedMonth;
                    final records = attendance.records
                        .where(
                          (record) =>
                              record.date.month == month.month &&
                              record.date.year == month.year,
                        )
                        .toList();
                    await ExportService.exportToPdf(
                      profile,
                      records,
                      DateTime(month.year, month.month, 1),
                      DateTime(month.year, month.month + 1, 0),
                    );
                  },
                ),
                const SizedBox(height: 10),
                _exportTile(
                  context,
                  ctx,
                  Icons.date_range_rounded,
                  'Personnalisé',
                  'Période libre',
                  const Color(0xFFF97316),
                  () {
                    Navigator.pop(ctx);
                    _showDateRangeSheet(context, profile);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _exportTile(
    BuildContext context,
    BuildContext sheetContext,
    IconData icon,
    String title,
    String subtitle,
    Color color,
    VoidCallback onTap,
  ) {
    return _PressableScale(
      radius: 16,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: color.withValues(alpha: 0.25)),
          borderRadius: BorderRadius.circular(16),
          color: color.withValues(alpha: 0.06),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: color.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, color: color, size: 14),
          ],
        ),
      ),
    );
  }

  void _showDateRangeSheet(BuildContext context, UserProfile profile) {
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
                children: [
                  const Text(
                    'Choisir la période',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: _dateTile(context, 'Du', start, () async {
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
                        child: _dateTile(context, 'Au', end, () async {
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
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        final attendance = context.read<AttendanceProvider>();
                        final records = attendance.records
                            .where(
                              (record) =>
                                  (record.date.isAfter(start) ||
                                      record.date.isAtSameMomentAs(start)) &&
                                  (record.date.isBefore(end) ||
                                      record.date.isAtSameMomentAs(end)),
                            )
                            .toList();
                        _showFormatPicker(
                          context,
                          profile,
                          records,
                          start,
                          end,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Confirmer',
                        style: TextStyle(
                          fontSize: 15,
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

  Widget _dateTile(
    BuildContext context,
    String label,
    DateTime date,
    VoidCallback onTap,
  ) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return _PressableScale(
      radius: 14,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
        decoration: BoxDecoration(
          color: onSurface.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: onSurface.withValues(alpha: 0.10)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: onSurface.withValues(alpha: 0.5),
                fontWeight: FontWeight.w700,
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

  void _showFormatPicker(
    BuildContext context,
    UserProfile profile,
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
                leading: const Icon(
                  Icons.picture_as_pdf_rounded,
                  color: Color(0xFFEF4444),
                ),
                title: const Text('Exporter PDF'),
                onTap: () async {
                  Navigator.pop(ctx);
                  await ExportService.exportToPdf(profile, records, start, end);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AttendanceHeader extends StatelessWidget {
  final void Function(BuildContext context, UserProfile? profile) onExport;

  const _AttendanceHeader({required this.onExport});

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final profile = context.read<AppProvider>().userProfile;
    final company = profile?.companyName;

    return Consumer<AttendanceProvider>(
      builder: (context, attendance, _) {
        final month = attendance.viewedMonth;
        final records = attendance.records
            .where(
              (record) =>
                  record.date.year == month.year &&
                  record.date.month == month.month,
            )
            .toList();
        final present = records
            .where((record) => record.status == AttendanceStatus.present)
            .length;
        final absent = records
            .where((record) => record.status == AttendanceStatus.absent)
            .length;
        final open = records
            .where(
              (record) =>
                  record.status == AttendanceStatus.present &&
                  record.checkOut == null,
            )
            .length;

        final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
        final subColor = isDark ? Colors.white.withValues(alpha: 0.66) : const Color(0xFF475569);
        final width = MediaQuery.of(context).size.width;
        final isDesktop = width > 850;

        if (isDesktop) {
          final gradientColors = isDark 
              ? const [Color(0xFF0D1E1B), Color(0xFF091412)]
              : const [Color(0xFF0D9488), Color(0xFF0F766E)];
          final borderSideColor = isDark ? Colors.white10 : const Color(0xFF0F766E).withValues(alpha: 0.15);
          return Container(
            height: 80,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: gradientColors),
              border: Border(bottom: BorderSide(color: borderSideColor)),
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Suivi de Présence',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        if (company != null && company.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            company,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.70),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                    Row(
                      children: [
                        _buildDesktopKpiBadge('Enregistré', records.length, const Color(0xFF2563EB), isDark),
                        const SizedBox(width: 8),
                        _buildDesktopKpiBadge('Présent', present, const Color(0xFF10B981), isDark),
                        const SizedBox(width: 8),
                        _buildDesktopKpiBadge('Absent', absent, const Color(0xFFF43F5E), isDark),
                        const SizedBox(width: 8),
                        _buildDesktopKpiBadge('Ouvert', open, const Color(0xFFF59E0B), isDark),
                      ],
                    ),
                    Row(
                      children: [
                        _HeaderButton(
                          icon: Icons.ios_share_rounded,
                          onTap: () => onExport(context, profile),
                          isWhite: true,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return _Reveal(
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: AppDesign.heroGradient(isDark),
              ),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(32),
              ),
              border: isDark
                  ? null
                  : const Border(
                      bottom: BorderSide(color: Color(0xFFE2E8F0)),
                    ),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.3)
                      : Colors.black.withValues(alpha: 0.05),
                  blurRadius: 30,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: Stack(
              children: [
                if (isDark) ...[
                  Positioned(
                    top: -34,
                    right: -20,
                    child: _GlowShape(
                      size: 150,
                      color: Colors.white.withValues(alpha: 0.06),
                    ),
                  ),
                  Positioned(
                    bottom: 16,
                    left: -44,
                    child: _GlowShape(
                      size: 122,
                      color: Colors.white.withValues(alpha: 0.045),
                    ),
                  ),
                  Positioned(
                    right: 42,
                    bottom: 76,
                    child: Transform.rotate(
                      angle: -0.18,
                      child: Container(
                        width: 84,
                        height: 54,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.055),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1200),
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(20, topPad + 12, 20, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              if (Navigator.canPop(context)) ...[
                                _HeaderButton(
                                  icon: Icons.arrow_back_rounded,
                                  onTap: () => Navigator.pop(context),
                                ),
                                const SizedBox(width: 14),
                              ],
                              Expanded(
                                child: Text(
                                  'Suivi de Présence',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: textColor,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                              _HeaderButton(
                                icon: Icons.insights_rounded,
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const AnalyticsScreen(),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              _HeaderButton(
                                icon: Icons.ios_share_rounded,
                                onTap: () => onExport(context, profile),
                              ),
                            ],
                          ),
                          if (company != null && company.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              company,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: subColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 14,
                              horizontal: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.13)
                                  : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.18)
                                    : const Color(0xFFE2E8F0),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: isDark
                                      ? Colors.black.withValues(alpha: 0.10)
                                      : Colors.black.withValues(alpha: 0.02),
                                  blurRadius: 22,
                                  offset: const Offset(0, 12),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                _HeaderKpi(
                                  icon: Icons.event_note_rounded,
                                  value: records.length,
                                  label: 'Enregistré',
                                  color: const Color(0xFF2563EB),
                                  isDark: isDark,
                                ),
                                _KpiDivider(isDark: isDark),
                                _HeaderKpi(
                                  icon: Icons.check_circle_rounded,
                                  value: present,
                                  label: 'Présent',
                                  color: const Color(0xFF10B981),
                                  isDark: isDark,
                                ),
                                _KpiDivider(isDark: isDark),
                                _HeaderKpi(
                                  icon: Icons.cancel_rounded,
                                  value: absent,
                                  label: 'Absent',
                                  color: const Color(0xFFF43F5E),
                                  isDark: isDark,
                                ),
                                _KpiDivider(isDark: isDark),
                                _HeaderKpi(
                                  icon: Icons.radio_button_checked_rounded,
                                  value: open,
                                  label: 'Ouvert',
                                  color: const Color(0xFFF59E0B),
                                  isDark: isDark,
                                ),
                              ],
                            ),
                          ),
                        ],
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

  Widget _buildDesktopKpiBadge(String label, int value, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '$value $label',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthlyInsightCard extends StatelessWidget {
  const _MonthlyInsightCard();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Consumer<AttendanceProvider>(
      builder: (context, attendance, _) {
        final month = attendance.viewedMonth;
        final records =
            attendance.records
                .where(
                  (record) =>
                      record.date.year == month.year &&
                      record.date.month == month.month,
                )
                .toList()
              ..sort((a, b) => b.date.compareTo(a.date));

        final present = records
            .where((record) => record.status == AttendanceStatus.present)
            .length;
        final absent = records
            .where((record) => record.status == AttendanceStatus.absent)
            .length;
        final openDays = records
            .where(
              (record) =>
                  record.status == AttendanceStatus.present &&
                  record.checkOut == null,
            )
            .length;
        final totalHours = records.fold<double>(
          0,
          (sum, record) => sum + record.hours,
        );
        final rate = records.isEmpty ? 0 : ((present / records.length) * 100);
        final lastRecord = records.isNotEmpty ? records.first : null;

        final message = records.isEmpty
            ? 'Aucune journée enregistrée pour ce mois.'
            : openDays > 0
            ? '$openDays journée ouverte à compléter.'
            : absent > present
            ? 'Mois à surveiller: absences élevées.'
            : 'Rythme du mois stable et bien suivi.';

        return _Reveal(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: AppDesign.premiumCard(
              isDark: isDark,
              tint: const Color(0xFF7C3AED),
              radius: 24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: AppDesign.accentIcon(const [
                        Color(0xFF2563EB),
                        Color(0xFF7C3AED),
                      ]),
                      child: const Icon(
                        Icons.auto_graph_rounded,
                        color: Colors.white,
                        size: 23,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Résumé du mois',
                            style: TextStyle(
                              color: onSurface,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            message,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: onSurface.withValues(alpha: 0.48),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _InsightMetric(
                      icon: Icons.trending_up_rounded,
                      label: 'Présence',
                      value: '${rate.round()}%',
                      color: const Color(0xFF10B981),
                    ),
                    const SizedBox(width: 10),
                    _InsightMetric(
                      icon: Icons.schedule_rounded,
                      label: 'Heures',
                      value: formatDuration(totalHours),
                      color: const Color(0xFF2563EB),
                    ),
                    const SizedBox(width: 10),
                    _InsightMetric(
                      icon: Icons.workspace_premium_rounded,
                      label: 'Dernier',
                      value: lastRecord == null
                          ? '--'
                          : lastRecord.status == AttendanceStatus.present
                          ? 'Présent'
                          : 'Absent',
                      color: lastRecord?.status == AttendanceStatus.absent
                          ? const Color(0xFFF43F5E)
                          : const Color(0xFFF97316),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _HeaderButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isWhite;

  const _HeaderButton({required this.icon, required this.onTap, this.isWhite = false});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return _PressableScale(
      radius: 18,
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: isWhite || isDark
              ? Colors.white.withValues(alpha: 0.15)
              : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isWhite || isDark
                ? Colors.white.withValues(alpha: 0.22)
                : const Color(0xFFE2E8F0),
          ),
        ),
        child: Icon(
          icon,
          color: isWhite || isDark ? Colors.white : const Color(0xFF0F172A),
          size: 22,
        ),
      ),
    );
  }
}

class _HeaderKpi extends StatelessWidget {
  final IconData icon;
  final int value;
  final String label;
  final Color color;
  final bool isDark;

  const _HeaderKpi({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final titleColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subColor = isDark ? Colors.white.withValues(alpha: 0.62) : const Color(0xFF64748B);

    return Expanded(
      child: Column(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 7),
          _AnimatedCounter(
            value: value,
            style: TextStyle(
              color: titleColor,
              fontWeight: FontWeight.w900,
              fontSize: 22,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: subColor,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _KpiDivider extends StatelessWidget {
  final bool isDark;

  const _KpiDivider({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 62,
      margin: const EdgeInsets.symmetric(horizontal: 3),
      color: isDark
          ? Colors.white.withValues(alpha: 0.13)
          : const Color(0xFFE2E8F0),
    );
  }
}

class _InsightMetric extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _InsightMetric({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isDark ? 0.16 : 0.09),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.18)),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: isDark ? 0.04 : 0.08),
              blurRadius: 14,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 9),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: onSurface.withValues(alpha: 0.48),
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PremiumFab extends StatelessWidget {
  final VoidCallback onTap;

  const _PremiumFab({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return _PressableScale(
      radius: 30,
      onTap: onTap,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2563EB).withValues(alpha: 0.36),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 32),
      ),
    );
  }
}

class _AnimatedCounter extends StatelessWidget {
  final int value;
  final TextStyle style;

  const _AnimatedCounter({required this.value, required this.style});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.toDouble()),
      duration: const Duration(milliseconds: 650),
      curve: Curves.easeOutCubic,
      builder: (context, animated, _) {
        return Text(animated.round().toString(), style: style);
      },
    );
  }
}

class _PressableScale extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final double radius;

  const _PressableScale({
    required this.child,
    required this.onTap,
    required this.radius,
  });

  @override
  State<_PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<_PressableScale> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _pressed ? 0.97 : 1,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOutCubic,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(widget.radius),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          borderRadius: BorderRadius.circular(widget.radius),
          splashColor: Colors.white.withValues(alpha: 0.10),
          highlightColor: Colors.white.withValues(alpha: 0.06),
          onTap: widget.onTap,
          onTapDown: (_) {
            HapticFeedback.lightImpact();
            setState(() => _pressed = true);
          },
          onTapCancel: () => setState(() => _pressed = false),
          onTapUp: (_) => setState(() => _pressed = false),
          child: widget.child,
        ),
      ),
    );
  }
}

class _Reveal extends StatelessWidget {
  final Widget child;

  const _Reveal({required this.child});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 520),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 16 * (1 - value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

class _GlowShape extends StatelessWidget {
  final double size;
  final Color color;

  const _GlowShape({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
