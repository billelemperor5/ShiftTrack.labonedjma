import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_design.dart';
import '../../core/utils/time_utils.dart';
import '../../models/attendance_record.dart';
import '../../providers/app_provider.dart';
import '../../providers/attendance_provider.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Consumer2<AttendanceProvider, AppProvider>(
        builder: (context, attendance, app, _) {
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
          final stats = _StatsModel.fromRecords(
            records,
            _defaultWorkHours(app.userProfile),
          );

          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: Container(
              decoration: AppDesign.pageBackground(isDark),
              child: Column(
                children: [
                  _StatsHeader(
                    month: month,
                    tabController: _tabController,
                    isDark: isDark,
                    onBack: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeOutCubic,
                      child: _tabController.index == 0
                          ? _SummaryTab(
                              key: const ValueKey('summary'),
                              records: records,
                              stats: stats,
                              isDark: isDark,
                              onSurface: onSurface,
                            )
                          : _DetailsTab(
                              key: const ValueKey('details'),
                              records: records,
                              stats: stats,
                              isDark: isDark,
                              onSurface: onSurface,
                            ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  double _defaultWorkHours(dynamic profile) {
    final inParts = (profile?.defaultCheckIn ?? '08:00').split(':');
    final outParts = (profile?.defaultCheckOut ?? '17:00').split(':');
    final inHour = double.parse(inParts[0]) + double.parse(inParts[1]) / 60;
    final outHour = double.parse(outParts[0]) + double.parse(outParts[1]) / 60;
    var shift = outHour - inHour;
    if (shift < 0) shift += 24;
    final breakOff = (profile?.isBreakPaid ?? true)
        ? 0.0
        : (profile?.breakDuration ?? 30) / 60.0;
    return math.max(0, shift - breakOff);
  }
}

class _StatsHeader extends StatelessWidget {
  final DateTime month;
  final TabController tabController;
  final bool isDark;
  final VoidCallback onBack;

  const _StatsHeader({
    required this.month,
    required this.tabController,
    required this.isDark,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subColor = isDark ? Colors.white.withValues(alpha: 0.68) : const Color(0xFF475569);

    final width = MediaQuery.of(context).size.width;
    final isDesktop = width > 850;

    if (isDesktop) {
      final gradientColors = isDark 
          ? const [Color(0xFF0D1E1B), Color(0xFF091412)]
          : const [Color(0xFF0D9488), Color(0xFF0F766E)];
      final borderSideColor = isDark ? Colors.white10 : const Color(0xFF0F766E).withValues(alpha: 0.15);
      return Container(
        height: 76,
        padding: const EdgeInsets.symmetric(horizontal: 24),
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
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.insights_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Statistiques & Analyses',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          'Rapports de présence et productivité',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.75),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                // Center Month Navigator
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left_rounded, color: Colors.white, size: 20),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        tooltip: 'Mois précédent',
                        onPressed: () {
                          final att = context.read<AttendanceProvider>();
                          att.setViewedMonth(DateTime(month.year, month.month - 1));
                        },
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today_rounded, color: Colors.white70, size: 14),
                            const SizedBox(width: 6),
                            Text(
                              DateFormat('MMMM yyyy', 'fr').format(month),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right_rounded, color: Colors.white, size: 20),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        tooltip: 'Mois suivant',
                        onPressed: () {
                          final att = context.read<AttendanceProvider>();
                          att.setViewedMonth(DateTime(month.year, month.month + 1));
                        },
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 240,
                  height: 38,
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: TabBar(
                    controller: tabController,
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    indicator: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    labelColor: const Color(0xFF0F766E),
                    unselectedLabelColor: Colors.white.withValues(alpha: 0.85),
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                    tabs: const [
                      Tab(text: 'Vue d\'ensemble'),
                      Tab(text: 'Détails'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      padding: EdgeInsets.fromLTRB(18, topPad + 12, 18, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: AppDesign.heroGradient(isDark),
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
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
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        children: [
          if (isDark) ...[
            Positioned(
              right: -28,
              top: -24,
              child: _SoftCircle(
                size: 132,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
            Positioned(
              left: -42,
              bottom: -34,
              child: _SoftCircle(
                size: 108,
                color: Colors.white.withValues(alpha: 0.045),
              ),
            ),
          ],
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Column(
                children: [
                  Row(
                    children: [
                      if (Navigator.canPop(context)) ...[
                        _HeaderIconButton(
                          icon: Icons.arrow_back_rounded,
                          onTap: onBack,
                        ),
                        const SizedBox(width: 14),
                      ],
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.16)
                              : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(17),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.14)
                                : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Icon(
                          Icons.insights_rounded,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Statistiques',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: textColor,
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              DateFormat('MMMM yyyy', 'fr').format(month),
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
                  const SizedBox(height: 16),
                  Container(
                    height: 48,
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.15)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.13)
                            : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: TabBar(
                      controller: tabController,
                      indicatorSize: TabBarIndicatorSize.tab,
                      dividerColor: Colors.transparent,
                      indicator: BoxDecoration(
                        color: isDark ? Colors.white : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.10),
                            blurRadius: 12,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      labelColor: const Color(0xFF0F766E),
                      unselectedLabelColor: isDark
                          ? Colors.white.withValues(alpha: 0.78)
                          : const Color(0xFF64748B),
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                      ),
                      unselectedLabelStyle: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                      tabs: const [
                        Tab(text: 'Résumé'),
                        Tab(text: 'Détails'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryTab extends StatelessWidget {
  final List<AttendanceRecord> records;
  final _StatsModel stats;
  final bool isDark;
  final Color onSurface;

  const _SummaryTab({
    super.key,
    required this.records,
    required this.stats,
    required this.isDark,
    required this.onSurface,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width > 800;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 34),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              if (isDesktop)
                Row(
                  children: [
                    _MiniStatCard(
                      icon: Icons.schedule_rounded,
                      label: 'Total',
                      value: formatDuration(stats.totalHours),
                      color: const Color(0xFF7C3AED),
                      isDark: isDark,
                    ),
                    const SizedBox(width: 10),
                    _MiniStatCard(
                      icon: Icons.trending_up_rounded,
                      label: 'Heures sup.',
                      value: formatDuration(stats.overtime),
                      color: const Color(0xFF10B981),
                      isDark: isDark,
                    ),
                    const SizedBox(width: 10),
                    _MiniStatCard(
                      icon: Icons.timer_rounded,
                      label: 'Moyenne/j',
                      value: formatDuration(stats.avgHours),
                      color: const Color(0xFFF59E0B),
                      isDark: isDark,
                    ),
                    const SizedBox(width: 10),
                    _MiniStatCard(
                      icon: Icons.calendar_month_rounded,
                      label: 'Jours',
                      value: '${stats.present} / ${stats.registered}',
                      color: const Color(0xFF2563EB),
                      isDark: isDark,
                    ),
                  ],
                )
              else ...[
                Row(
                  children: [
                    _MiniStatCard(
                      icon: Icons.schedule_rounded,
                      label: 'Total',
                      value: formatDuration(stats.totalHours),
                      color: const Color(0xFF7C3AED),
                      isDark: isDark,
                    ),
                    const SizedBox(width: 10),
                    _MiniStatCard(
                      icon: Icons.trending_up_rounded,
                      label: 'Heures sup.',
                      value: formatDuration(stats.overtime),
                      color: const Color(0xFF10B981),
                      isDark: isDark,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _MiniStatCard(
                      icon: Icons.timer_rounded,
                      label: 'Moyenne/j',
                      value: formatDuration(stats.avgHours),
                      color: const Color(0xFFF59E0B),
                      isDark: isDark,
                    ),
                    const SizedBox(width: 10),
                    _MiniStatCard(
                      icon: Icons.calendar_month_rounded,
                      label: 'Jours',
                      value: '${stats.present} / ${stats.registered}',
                      color: const Color(0xFF2563EB),
                      isDark: isDark,
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              if (isDesktop)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 4,
                      child: _AttendanceRateCard(stats: stats, isDark: isDark),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 6,
                      child: _DailyHoursCard(
                        records: records,
                        stats: stats,
                        isDark: isDark,
                        onSurface: onSurface,
                      ),
                    ),
                  ],
                )
              else ...[
                _AttendanceRateCard(stats: stats, isDark: isDark),
                const SizedBox(height: 16),
                _DailyHoursCard(
                  records: records,
                  stats: stats,
                  isDark: isDark,
                  onSurface: onSurface,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailsTab extends StatelessWidget {
  final List<AttendanceRecord> records;
  final _StatsModel stats;
  final bool isDark;
  final Color onSurface;

  const _DetailsTab({
    super.key,
    required this.records,
    required this.stats,
    required this.isDark,
    required this.onSurface,
  });

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.event_busy_rounded,
              size: 58,
              color: onSurface.withValues(alpha: 0.16),
            ),
            const SizedBox(height: 12),
            Text(
              'Aucune donnée ce mois',
              style: TextStyle(
                color: onSurface.withValues(alpha: 0.42),
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      );
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: ListView.builder(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 34),
          itemCount: records.length,
          itemBuilder: (context, index) => _DetailRecordTile(
            record: records[index],
            targetHours: stats.defaultWorkHours,
            isDark: isDark,
            onSurface: onSurface,
          ),
        ),
      ),
    );
  }
}

class _MiniStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool isDark;

  const _MiniStatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final surface = isDark ? const Color(0xFF17232D) : Colors.white;

    return Expanded(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 520),
        curve: Curves.easeOutCubic,
        builder: (context, valueAnim, child) {
          return Opacity(
            opacity: valueAnim,
            child: Transform.translate(
              offset: Offset(0, 12 * (1 - valueAnim)),
              child: child,
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: surface.withValues(alpha: isDark ? 0.88 : 0.94),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.07)
                  : color.withValues(alpha: 0.10),
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: isDark ? 0.08 : 0.10),
                blurRadius: 18,
                offset: const Offset(0, 9),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: onSurface.withValues(alpha: 0.45),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: onSurface,
                        letterSpacing: -0.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AttendanceRateCard extends StatelessWidget {
  final _StatsModel stats;
  final bool isDark;

  const _AttendanceRateCard({required this.stats, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final surface = isDark ? const Color(0xFF17232D) : Colors.white;
    final percent = stats.rate.round();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _premiumCardDecoration(
        isDark: isDark,
        surface: surface,
        tint: const Color(0xFF0F766E),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(
            icon: Icons.donut_large_rounded,
            title: 'Taux de présence',
            color: const Color(0xFF0F766E),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              SizedBox(
                width: 132,
                height: 132,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    PieChart(
                      PieChartData(
                        sectionsSpace: 4,
                        centerSpaceRadius: 42,
                        sections: [
                          PieChartSectionData(
                            value: stats.present > 0
                                ? stats.present.toDouble()
                                : 0.1,
                            color: const Color(0xFF0F766E),
                            radius: 19,
                            showTitle: false,
                          ),
                          PieChartSectionData(
                            value: stats.absent > 0
                                ? stats.absent.toDouble()
                                : 0.1,
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.10)
                                : const Color(0xFFE5E7EB),
                            radius: 15,
                            showTitle: false,
                          ),
                        ],
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$percent%',
                          style: TextStyle(
                            color: onSurface,
                            fontSize: 27,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1,
                          ),
                        ),
                        Text(
                          'score',
                          style: TextStyle(
                            color: onSurface.withValues(alpha: 0.38),
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 22),
              Expanded(
                child: Column(
                  children: [
                    _LegendMetric(
                      label: 'Présences',
                      value: '${stats.present} jours',
                      color: const Color(0xFF0F766E),
                    ),
                    const SizedBox(height: 14),
                    _LegendMetric(
                      label: 'Absences',
                      value: '${stats.absent} jours',
                      color: const Color(0xFFEF4444),
                    ),
                    const SizedBox(height: 14),
                    _LegendMetric(
                      label: 'Ouverts',
                      value: '${stats.open} jours',
                      color: const Color(0xFFF59E0B),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DailyHoursCard extends StatelessWidget {
  final List<AttendanceRecord> records;
  final _StatsModel stats;
  final bool isDark;
  final Color onSurface;

  const _DailyHoursCard({
    required this.records,
    required this.stats,
    required this.isDark,
    required this.onSurface,
  });

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? const Color(0xFF17232D) : Colors.white;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _premiumCardDecoration(
        isDark: isDark,
        surface: surface,
        tint: const Color(0xFF2563EB),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(
            icon: Icons.bar_chart_rounded,
            title: 'Heures quotidiennes',
            color: const Color(0xFF2563EB),
          ),
          const SizedBox(height: 16),
          _HoursBarChart(
            records: records,
            defaultWorkHours: stats.defaultWorkHours,
            onSurface: onSurface,
            isDark: isDark,
          ),
        ],
      ),
    );
  }
}

class _HoursBarChart extends StatelessWidget {
  final List<AttendanceRecord> records;
  final double defaultWorkHours;
  final Color onSurface;
  final bool isDark;

  const _HoursBarChart({
    required this.records,
    required this.defaultWorkHours,
    required this.onSurface,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) {
      return SizedBox(
        height: 184,
        child: Center(
          child: Text(
            'Pas de données',
            style: TextStyle(
              color: onSurface.withValues(alpha: 0.35),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
    }

    final days = records.reversed.toList();
    const barWidth = 22.0;
    const spacing = 14.0;
    final chartWidth = math.max(320.0, days.length * (barWidth + spacing) + 32);

    return SizedBox(
      height: 220,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        reverse: true,
        child: SizedBox(
          width: chartWidth,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.center,
              maxY: math.max(12, defaultWorkHours + 4),
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) => const Color(0xFF2563EB),
                  tooltipBorderRadius: BorderRadius.circular(12),
                  tooltipPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    return BarTooltipItem(
                      formatDuration(days[group.x].hours),
                      const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                      ),
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index < 0 || index >= days.length) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 7),
                        child: Text(
                          DateFormat('dd').format(days[index].date),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: onSurface.withValues(alpha: 0.36),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                leftTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: 4,
                getDrawingHorizontalLine: (_) => FlLine(
                  color: onSurface.withValues(alpha: 0.055),
                  strokeWidth: 1,
                ),
              ),
              borderData: FlBorderData(show: false),
              barGroups: List.generate(days.length, (index) {
                final record = days[index];
                final isAbsent = record.status == AttendanceStatus.absent;
                final isOpen =
                    record.status == AttendanceStatus.present &&
                    record.checkOut == null;
                final value = record.hours > 0 ? record.hours : 0.35;
                final colors = isAbsent
                    ? const [Color(0xFFEF4444), Color(0xFFFCA5A5)]
                    : isOpen
                    ? const [Color(0xFFF59E0B), Color(0xFFF97316)]
                    : const [Color(0xFF2563EB), Color(0xFF14B8A6)];

                return BarChartGroupData(
                  x: index,
                  barRods: [
                    BarChartRodData(
                      toY: value,
                      width: barWidth,
                      borderRadius: BorderRadius.circular(999),
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: colors,
                      ),
                      backDrawRodData: BackgroundBarChartRodData(
                        show: true,
                        toY: math.max(12, defaultWorkHours + 4),
                        color: onSurface.withValues(
                          alpha: isDark ? 0.06 : 0.04,
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailRecordTile extends StatelessWidget {
  final AttendanceRecord record;
  final double targetHours;
  final bool isDark;
  final Color onSurface;

  const _DetailRecordTile({
    required this.record,
    required this.targetHours,
    required this.isDark,
    required this.onSurface,
  });

  @override
  Widget build(BuildContext context) {
    final isPresent = record.status == AttendanceStatus.present;
    final isOpen = isPresent && record.checkOut == null;
    final statusColor = !isPresent
        ? const Color(0xFFEF4444)
        : isOpen
        ? const Color(0xFFF59E0B)
        : const Color(0xFF0F766E);
    final progress = targetHours <= 0 ? 0.0 : (record.hours / targetHours);
    final surface = isDark ? const Color(0xFF17232D) : Colors.white;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _showRecordDetails(context, statusColor, isPresent, isOpen, progress);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: _premiumCardDecoration(
          isDark: isDark,
          surface: surface,
          tint: statusColor,
          radius: 18,
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(
                !isPresent
                    ? Icons.cancel_rounded
                    : isOpen
                    ? Icons.schedule_rounded
                    : Icons.check_circle_rounded,
                color: statusColor,
                size: 21,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat('EEEE, dd MMM', 'fr').format(record.date),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: onSurface,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    isPresent
                        ? '${record.checkIn ?? '--:--'}  -  ${record.checkOut ?? '--:--'}'
                        : 'Absence enregistrée',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: onSurface.withValues(alpha: 0.45),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (isPresent) ...[
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: progress.clamp(0, 1),
                        minHeight: 5,
                        backgroundColor: onSurface.withValues(alpha: 0.06),
                        color: statusColor,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              isPresent ? formatDuration(record.hours) : 'Absent',
              style: TextStyle(
                color: statusColor,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              Icons.keyboard_arrow_up_rounded,
              color: onSurface.withValues(alpha: 0.28),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  void _showRecordDetails(
    BuildContext context,
    Color statusColor,
    bool isPresent,
    bool isOpen,
    double progress,
  ) {
    final surface = isDark ? const Color(0xFF17232D) : Colors.white;
    final extraSessions = record.extraSessions ?? [];
    final overtime = isPresent
        ? math.max(
            0.0,
            record.hours -
                (record.scheduledHours > 0
                    ? record.scheduledHours
                    : targetHours),
          )
        : 0.0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return SafeArea(
          top: false,
          child: Container(
            margin: const EdgeInsets.all(10),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : statusColor.withValues(alpha: 0.12),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.32 : 0.16),
                  blurRadius: 34,
                  offset: const Offset(0, -8),
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 5,
                      decoration: BoxDecoration(
                        color: onSurface.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(19),
                        ),
                        child: Icon(
                          !isPresent
                              ? Icons.cancel_rounded
                              : isOpen
                              ? Icons.schedule_rounded
                              : Icons.check_circle_rounded,
                          color: statusColor,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              DateFormat(
                                'EEEE, dd MMMM yyyy',
                                'fr',
                              ).format(record.date),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: onSurface,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              !isPresent
                                  ? 'Absence enregistrée'
                                  : isOpen
                                  ? 'Journée ouverte'
                                  : 'Journée complétée',
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (isPresent) ...[
                    Row(
                      children: [
                        Expanded(
                          child: _DetailMetricCard(
                            icon: Icons.login_rounded,
                            label: 'Arrivée',
                            value: record.checkIn ?? '--:--',
                            color: const Color(0xFF10B981),
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _DetailMetricCard(
                            icon: Icons.logout_rounded,
                            label: 'Départ',
                            value: record.checkOut ?? '--:--',
                            color: const Color(0xFFEF4444),
                            isDark: isDark,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _DetailMetricCard(
                            icon: Icons.schedule_rounded,
                            label: 'Total travaillé',
                            value: formatDuration(record.hours),
                            color: const Color(0xFF2563EB),
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _DetailMetricCard(
                            icon: Icons.trending_up_rounded,
                            label: 'Heures sup.',
                            value: formatDuration(overtime),
                            color: const Color(0xFFF59E0B),
                            isDark: isDark,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Progression journalière',
                      style: TextStyle(
                        color: onSurface,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 9),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: progress.clamp(0, 1),
                        minHeight: 8,
                        color: statusColor,
                        backgroundColor: onSurface.withValues(alpha: 0.07),
                      ),
                    ),
                    if (extraSessions.isNotEmpty) ...[
                      const SizedBox(height: 18),
                      Text(
                        'Sessions supplémentaires',
                        style: TextStyle(
                          color: onSurface,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ...extraSessions.map(
                        (session) => _ExtraSessionRow(
                          session: session,
                          isDark: isDark,
                          onSurface: onSurface,
                        ),
                      ),
                    ],
                  ] else ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: statusColor.withValues(alpha: 0.15),
                        ),
                      ),
                      child: Text(
                        'Aucune heure de travail enregistrée pour cette journée.',
                        style: TextStyle(
                          color: onSurface.withValues(alpha: 0.70),
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        backgroundColor: onSurface.withValues(alpha: 0.05),
                      ),
                      child: Text(
                        'Fermer',
                        style: TextStyle(
                          color: onSurface.withValues(alpha: 0.62),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DetailMetricCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool isDark;

  const _DetailMetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.14 : 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 19),
          const SizedBox(height: 10),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 17,
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
    );
  }
}

class _ExtraSessionRow extends StatelessWidget {
  final WorkSession session;
  final bool isDark;
  final Color onSurface;

  const _ExtraSessionRow({
    required this.session,
    required this.isDark,
    required this.onSurface,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: onSurface.withValues(alpha: isDark ? 0.055 : 0.035),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            Icons.add_circle_outline_rounded,
            size: 18,
            color: onSurface.withValues(alpha: 0.42),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${session.startTime} - ${session.endTime}',
              style: TextStyle(color: onSurface, fontWeight: FontWeight.w800),
            ),
          ),
          Text(
            formatDuration(session.hours),
            style: const TextStyle(
              color: Color(0xFF2563EB),
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _LegendMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Row(
      children: [
        Container(
          width: 11,
          height: 11,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: onSurface.withValues(alpha: 0.45),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  color: onSurface,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;

  const _SectionTitle({
    required this.icon,
    required this.title,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: onSurface,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _HeaderIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
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

class _StatsModel {
  final double totalHours;
  final double overtime;
  final double avgHours;
  final double rate;
  final int present;
  final int absent;
  final int open;
  final int registered;
  final double defaultWorkHours;

  const _StatsModel({
    required this.totalHours,
    required this.overtime,
    required this.avgHours,
    required this.rate,
    required this.present,
    required this.absent,
    required this.open,
    required this.registered,
    required this.defaultWorkHours,
  });

  factory _StatsModel.fromRecords(
    List<AttendanceRecord> records,
    double defaultWorkHours,
  ) {
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
    final totalHours = records.fold<double>(
      0,
      (sum, record) => sum + record.hours,
    );
    double overtime = 0;
    for (final record in records) {
      if (record.status == AttendanceStatus.present && record.hours > 0) {
        final target = record.scheduledHours > 0
            ? record.scheduledHours
            : defaultWorkHours;
        if (record.hours > target) overtime += record.hours - target;
      }
    }
    final rate = records.isEmpty ? 0.0 : (present / records.length) * 100;

    return _StatsModel(
      totalHours: totalHours,
      overtime: overtime,
      avgHours: present == 0 ? 0 : totalHours / present,
      rate: rate,
      present: present,
      absent: absent,
      open: open,
      registered: records.length,
      defaultWorkHours: defaultWorkHours,
    );
  }
}

BoxDecoration _premiumCardDecoration({
  required bool isDark,
  required Color surface,
  required Color tint,
  double radius = 24,
}) {
  return BoxDecoration(
    color: surface.withValues(alpha: isDark ? 0.88 : 0.94),
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(
      color: isDark
          ? Colors.white.withValues(alpha: 0.07)
          : tint.withValues(alpha: 0.10),
    ),
    boxShadow: [
      BoxShadow(
        color: tint.withValues(alpha: isDark ? 0.07 : 0.10),
        blurRadius: 20,
        offset: const Offset(0, 10),
      ),
    ],
  );
}
