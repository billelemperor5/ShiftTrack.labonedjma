import 'dart:ui' as ui;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_design.dart';
import '../../core/utils/time_utils.dart';
import '../../models/attendance_record.dart';
import '../../providers/attendance_provider.dart';

class PayrollDetailsScreen extends StatelessWidget {
  final DateTime monthDate;

  const PayrollDetailsScreen({super.key, required this.monthDate});

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
          child: Consumer<AttendanceProvider>(
            builder: (context, attendance, _) {
              final summary = _PayrollMonthSummary.fromRecords(
                attendance.records.where(
                  (record) =>
                      record.date.year == monthDate.year &&
                      record.date.month == monthDate.month,
                ),
              );

              return CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  _ReportHeader(monthDate: monthDate, summary: summary),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _QuickStats(summary: summary),
                          const SizedBox(height: 22),
                          if (summary.records.isNotEmpty) ...[
                            _ActivityChart(records: summary.records),
                            const SizedBox(height: 24),
                          ],
                          const _SectionTitle(
                            title: 'Journal de pointage',
                            icon: Icons.history_rounded,
                          ),
                          const SizedBox(height: 14),
                        ],
                      ),
                    ),
                  ),
                  if (summary.records.isEmpty)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: _EmptyJournal(),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 38),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => _DayRecordCard(
                            record: summary.records[index],
                            onTap: () => _showDayDetails(
                              context,
                              summary.records[index],
                            ),
                          ),
                          childCount: summary.records.length,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  void _showDayDetails(BuildContext context, AttendanceRecord record) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DayDetailsSheet(record: record),
    );
  }
}

class _PayrollMonthSummary {
  final List<AttendanceRecord> records;
  final double totalHours;
  final double overtime;
  final int presentCount;
  final int absentCount;

  const _PayrollMonthSummary({
    required this.records,
    required this.totalHours,
    required this.overtime,
    required this.presentCount,
    required this.absentCount,
  });

  factory _PayrollMonthSummary.fromRecords(Iterable<AttendanceRecord> values) {
    final records = values.toList()..sort((a, b) => a.date.compareTo(b.date));

    var totalHours = 0.0;
    var totalScheduled = 0.0;
    var presentCount = 0;
    var absentCount = 0;

    for (final record in records) {
      totalHours += record.hours;
      if (record.status == AttendanceStatus.present) {
        presentCount++;
        if (record.checkOut != null) {
          totalScheduled += record.scheduledHours;
        }
      } else {
        absentCount++;
      }
    }

    final overtime = totalHours - totalScheduled;

    return _PayrollMonthSummary(
      records: records,
      totalHours: totalHours,
      overtime: overtime < 0 ? 0 : overtime,
      presentCount: presentCount,
      absentCount: absentCount,
    );
  }
}

class _ReportHeader extends StatelessWidget {
  final DateTime monthDate;
  final _PayrollMonthSummary summary;

  const _ReportHeader({required this.monthDate, required this.summary});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final topPad = MediaQuery.of(context).padding.top;
    final month = _monthLabel(monthDate);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subColor = isDark ? Colors.white70 : const Color(0xFF475569);

    return SliverToBoxAdapter(
      child: Container(
        padding: EdgeInsets.fromLTRB(20, topPad + 12, 20, 30),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: AppDesign.heroGradient(isDark),
          ),
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(36),
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
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: Stack(
          children: [
            if (isDark)
              Positioned(
                right: -55,
                top: -58,
                child: _SoftCircle(
                  size: 185,
                  color: Colors.white.withValues(alpha: 0.065),
                ),
              ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _GlassIconButton(
                      icon: Icons.arrow_back_rounded,
                      onTap: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Rapport mensuel',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: textColor,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Synthèse paie & présence',
                            style: TextStyle(
                              color: subColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: BackdropFilter(
                    filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.13)
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.17)
                              : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.calendar_month_rounded,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                                size: 18,
                              ),
                              const SizedBox(width: 9),
                              Text(
                                month,
                                style: TextStyle(
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          Row(
                            children: [
                              _HeaderStat(
                                icon: Icons.work_rounded,
                                label: 'Travaillé',
                                value: formatDuration(summary.totalHours),
                                color: const Color(0xFF0F766E),
                                isDark: isDark,
                              ),
                              Container(
                                width: 1,
                                height: 48,
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                ),
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.13)
                                    : const Color(0xFFE2E8F0),
                              ),
                              _HeaderStat(
                                icon: Icons.event_available_rounded,
                                label: 'Présences',
                                value: '${summary.presentCount} jrs',
                                color: const Color(0xFF10B981),
                                isDark: isDark,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool isDark;

  const _HeaderStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icon, color: color, size: 19),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.60)
                        : const Color(0xFF64748B),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickStats extends StatelessWidget {
  final _PayrollMonthSummary summary;

  const _QuickStats({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MiniStatCard(
            label: 'Absences',
            value: '${summary.absentCount}',
            icon: Icons.do_not_disturb_on_rounded,
            color: const Color(0xFFF59E0B),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _MiniStatCard(
            label: 'Heures sup.',
            value: formatDuration(summary.overtime),
            icon: Icons.add_chart_rounded,
            color: const Color(0xFF2563EB),
          ),
        ),
      ],
    );
  }
}

class _MiniStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MiniStatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final surface = isDark ? const Color(0xFF17232D) : Colors.white;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface.withValues(alpha: isDark ? 0.88 : 0.96),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: color.withValues(alpha: 0.10)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: isDark ? 0.05 : 0.07),
            blurRadius: 18,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.11),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    color: onSurface.withValues(alpha: 0.42),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityChart extends StatelessWidget {
  final List<AttendanceRecord> records;

  const _ActivityChart({required this.records});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final surface = isDark ? const Color(0xFF17232D) : Colors.white;
    final presentRecords = records
        .where((record) => record.status == AttendanceStatus.present)
        .toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surface.withValues(alpha: isDark ? 0.88 : 0.96),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: onSurface.withValues(alpha: 0.055)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.16 : 0.06),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            title: 'Intensité de travail',
            icon: Icons.bar_chart_rounded,
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 160,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 12,
                minY: 0,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => const Color(0xFF111827),
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        '${rod.toY.toStringAsFixed(1)} h',
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) => Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          '${value.toInt()}',
                          style: TextStyle(
                            color: onSurface.withValues(alpha: 0.24),
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: presentRecords
                    .map(
                      (record) => BarChartGroupData(
                        x: record.date.day,
                        barRods: [
                          BarChartRodData(
                            toY: record.hours,
                            gradient: const LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [Color(0xFF0F766E), Color(0xFF14B8A6)],
                            ),
                            width: 8,
                            borderRadius: BorderRadius.circular(99),
                            backDrawRodData: BackgroundBarChartRodData(
                              show: true,
                              toY: 10,
                              color: onSurface.withValues(alpha: 0.045),
                            ),
                          ),
                        ],
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionTitle({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: const Color(0xFF0F766E).withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: const Color(0xFF0F766E), size: 18),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            color: onSurface,
            fontSize: 17,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }
}

class _DayRecordCard extends StatelessWidget {
  final AttendanceRecord record;
  final VoidCallback onTap;

  const _DayRecordCard({required this.record, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final isPresent = record.status == AttendanceStatus.present;
    final color = isPresent ? const Color(0xFF10B981) : const Color(0xFFF43F5E);
    final surface = isDark ? const Color(0xFF17232D) : Colors.white;
    final dayName = DateFormat(
      'EEE',
      'fr',
    ).format(record.date).replaceAll('.', '').toUpperCase();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _Pressable(
        radius: 24,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: surface.withValues(alpha: isDark ? 0.88 : 0.96),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: color.withValues(alpha: 0.10)),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: isDark ? 0.05 : 0.07),
                blurRadius: 18,
                offset: const Offset(0, 9),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      DateFormat('dd').format(record.date),
                      style: TextStyle(
                        color: color,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      dayName,
                      style: TextStyle(
                        color: color.withValues(alpha: 0.62),
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: isPresent
                    ? Row(
                        children: [
                          _CompactTime(
                            label: 'ENTRÉE',
                            value: record.checkIn ?? '--:--',
                          ),
                          const SizedBox(width: 16),
                          _CompactTime(
                            label: 'SORTIE',
                            value: record.checkOut ?? '--:--',
                          ),
                        ],
                      )
                    : Text(
                        'ABSENCE ENREGISTRÉE',
                        style: TextStyle(
                          color: color,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.2,
                        ),
                      ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatDuration(record.hours),
                    style: TextStyle(
                      color: color,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    'TOTAL',
                    style: TextStyle(
                      color: onSurface.withValues(alpha: 0.32),
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompactTime extends StatelessWidget {
  final String label;
  final String value;

  const _CompactTime({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: onSurface.withValues(alpha: 0.30),
            fontSize: 8,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: onSurface,
            fontSize: 13,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _DayDetailsSheet extends StatelessWidget {
  final AttendanceRecord record;

  const _DayDetailsSheet({required this.record});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final isPresent = record.status == AttendanceStatus.present;
    final color = isPresent ? const Color(0xFF10B981) : const Color(0xFFF43F5E);

    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.all(8),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 22),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF17232D) : Colors.white,
          borderRadius: BorderRadius.circular(34),
          border: Border.all(color: color.withValues(alpha: 0.13)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.34 : 0.16),
              blurRadius: 34,
              offset: const Offset(0, -10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 5,
              decoration: BoxDecoration(
                color: onSurface.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              DateFormat('EEEE, dd MMMM yyyy', 'fr').format(record.date),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: onSurface,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: color.withValues(alpha: 0.12)),
              ),
              child: Column(
                children: [
                  _DetailRow(
                    icon: Icons.verified_rounded,
                    label: 'Statut',
                    value: isPresent ? 'Présent' : 'Absent',
                  ),
                  const SizedBox(height: 12),
                  _DetailRow(
                    icon: Icons.login_rounded,
                    label: 'Entrée',
                    value: record.checkIn ?? '--:--',
                  ),
                  const SizedBox(height: 12),
                  _DetailRow(
                    icon: Icons.logout_rounded,
                    label: 'Sortie',
                    value: record.checkOut ?? '--:--',
                  ),
                  const SizedBox(height: 12),
                  _DetailRow(
                    icon: Icons.timer_rounded,
                    label: 'Total',
                    value: formatDuration(record.hours),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Row(
      children: [
        Icon(icon, color: onSurface.withValues(alpha: 0.42), size: 18),
        const SizedBox(width: 9),
        Text(
          '$label :',
          style: TextStyle(
            color: onSurface.withValues(alpha: 0.45),
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              color: onSurface,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyJournal extends StatelessWidget {
  const _EmptyJournal();

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Center(
      child: Text(
        'Aucun pointage pour ce mois',
        style: TextStyle(
          color: onSurface.withValues(alpha: 0.38),
          fontSize: 15,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _GlassIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return _Pressable(
      radius: 18,
      onTap: onTap,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.14)
              : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.14)
                : const Color(0xFFE2E8F0),
          ),
        ),
        child: Icon(
          icon,
          color: isDark ? Colors.white : const Color(0xFF0F172A),
          size: 22,
        ),
      ),
    );
  }
}

class _Pressable extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final double radius;

  const _Pressable({
    required this.child,
    required this.onTap,
    required this.radius,
  });

  @override
  State<_Pressable> createState() => _PressableState();
}

class _PressableState extends State<_Pressable> {
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
          onTap: widget.onTap,
          onTapDown: (_) {
            HapticFeedback.lightImpact();
            setState(() => _pressed = true);
          },
          onTapCancel: () => setState(() => _pressed = false),
          onTapUp: (_) => setState(() => _pressed = false),
          splashColor: Colors.white.withValues(alpha: 0.11),
          highlightColor: Colors.white.withValues(alpha: 0.06),
          child: widget.child,
        ),
      ),
    );
  }
}

class _SoftCircle extends StatelessWidget {
  final double size;
  final Color color;

  const _SoftCircle({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

String _monthLabel(DateTime date) {
  final value = DateFormat('MMMM yyyy', 'fr').format(date);
  return value[0].toUpperCase() + value.substring(1);
}
