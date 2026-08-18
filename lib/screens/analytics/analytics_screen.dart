import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_design.dart';
import '../../core/utils/time_utils.dart';
import '../../models/attendance_record.dart';
import '../../models/team_member.dart';
import '../../providers/app_provider.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/team_provider.dart';

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
    _tabController = TabController(length: 3, vsync: this);
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
                          : _tabController.index == 1
                              ? _DetailsTab(
                                  key: const ValueKey('details'),
                                  records: records,
                                  stats: stats,
                                  isDark: isDark,
                                  onSurface: onSurface,
                                )
                              : _TeamTab(
                                  key: const ValueKey('team'),
                                  isDark: isDark,
                                  onSurface: onSurface,
                                  onSelectMember: () {
                                    _tabController.animateTo(0);
                                  },
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
      padding: EdgeInsets.fromLTRB(18, topPad + 6, 18, 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: AppDesign.heroGradient(isDark),
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
        border: isDark
            ? null
            : const Border(
                bottom: BorderSide(color: Color(0xFFE2E8F0)),
              ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.25)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.16)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.14)
                        : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Icon(
                  Icons.insights_rounded,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                  size: 22,
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
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      DateFormat('MMMM yyyy', 'fr').format(month),
                      style: TextStyle(
                        color: subColor,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            height: 46,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.15)
                  : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(16),
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
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
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
                Tab(text: 'Équipe'),
              ],
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
                      icon: Icons.verified_user_rounded,
                      label: 'Ponctualité',
                      value: '100%',
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
                      icon: Icons.verified_user_rounded,
                      label: 'Ponctualité',
                      value: '100%',
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
                width: 120,
                height: 120,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    PieChart(
                      PieChartData(
                        sectionsSpace: 0,
                        centerSpaceRadius: 38,
                        sections: [
                          PieChartSectionData(
                            value: 100.0,
                            color: const Color(0xFF0F766E),
                            radius: 18,
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
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1,
                          ),
                        ),
                        Text(
                          'validé',
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
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _LegendMetric(
                            label: 'Présences',
                            value: '${stats.present} jours',
                            color: const Color(0xFF0F766E),
                          ),
                        ),
                        Expanded(
                          child: _LegendMetric(
                            label: 'Ponctualité',
                            value: '100%',
                            color: const Color(0xFF0284C7),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _LegendMetric(
                            label: 'Moyenne/j',
                            value: formatDuration(stats.avgHours),
                            color: const Color(0xFFF59E0B),
                          ),
                        ),
                        Expanded(
                          child: _LegendMetric(
                            label: 'Total Heures',
                            value: formatDuration(stats.totalHours),
                            color: const Color(0xFF6366F1),
                          ),
                        ),
                      ],
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

class _DailyHoursCard extends StatefulWidget {
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
  State<_DailyHoursCard> createState() => _DailyHoursCardState();
}

class _DailyHoursCardState extends State<_DailyHoursCard> {
  int _viewMode = 0; // 0 = Chart, 1 = Table

  @override
  Widget build(BuildContext context) {
    final surface = widget.isDark ? const Color(0xFF17232D) : Colors.white;
    final recordsSorted = widget.records.toList()..sort((a, b) => a.date.compareTo(b.date));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _premiumCardDecoration(
        isDark: widget.isDark,
        surface: surface,
        tint: const Color(0xFF2563EB),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _SectionTitle(
                icon: _viewMode == 0 ? Icons.bar_chart_rounded : Icons.table_chart_rounded,
                title: 'Heures quotidiennes',
                color: const Color(0xFF2563EB),
              ),
              // Segmented view toggle
              Container(
                height: 34,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: widget.isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: widget.isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Row(
                  children: [
                    _buildToggleBtn(0, Icons.show_chart_rounded, 'Graphe'),
                    _buildToggleBtn(1, Icons.table_rows_rounded, 'Tableau'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_viewMode == 0)
            _HoursBarChart(
              records: recordsSorted,
              defaultWorkHours: widget.stats.defaultWorkHours,
              onSurface: widget.onSurface,
              isDark: widget.isDark,
            )
          else
            _HoursDataTable(
              records: recordsSorted,
              onSurface: widget.onSurface,
              isDark: widget.isDark,
            ),
        ],
      ),
    );
  }

  Widget _buildToggleBtn(int index, IconData icon, String label) {
    final isSelected = _viewMode == index;
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => _viewMode = index);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2563EB) : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? Colors.white : widget.onSurface.withValues(alpha: 0.6),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? Colors.white : widget.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HoursBarChart extends StatefulWidget {
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
  State<_HoursBarChart> createState() => _HoursBarChartState();
}

class _HoursBarChartState extends State<_HoursBarChart> {
  AttendanceRecord? _touchedRecord;

  @override
  Widget build(BuildContext context) {
    if (widget.records.isEmpty) {
      return SizedBox(
        height: 184,
        child: Center(
          child: Text(
            'Pas de données',
            style: TextStyle(
              color: widget.onSurface.withValues(alpha: 0.35),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
    }

    final days = widget.records;
    final maxHours = days.map((e) => e.hours).fold(0.0, math.max);
    final calculatedMaxY = math.max(maxHours + 4.5, widget.defaultWorkHours + 5.0);

    const barWidth = 22.0;
    const spacing = 14.0;
    final chartWidth = math.max(320.0, days.length * (barWidth + spacing) + 32);

    final activeRecord = _touchedRecord ?? (days.isNotEmpty ? days.last : null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Highlight details pill
        if (activeRecord != null)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: widget.isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: widget.isDark
                    ? Colors.white12
                    : const Color(0xFFBFDBFE),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF2563EB),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  DateFormat('EEEE dd MMMM', 'fr').format(activeRecord.date),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: widget.onSurface,
                  ),
                ),
                const Spacer(),
                Text(
                  '${activeRecord.checkIn ?? '--:--'} → ${activeRecord.checkOut ?? '--:--'}',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: widget.onSurface.withValues(alpha: 0.65),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F766E),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    formatDuration(activeRecord.hours),
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        SizedBox(
          height: 230,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: SizedBox(
              width: chartWidth,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.center,
                  maxY: calculatedMaxY,
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchCallback: (event, response) {
                      if (response != null && response.spot != null) {
                        final spotIdx = response.spot!.touchedBarGroupIndex;
                        if (spotIdx >= 0 && spotIdx < days.length) {
                          if (_touchedRecord != days[spotIdx]) {
                            setState(() => _touchedRecord = days[spotIdx]);
                          }
                        }
                      }
                    },
                    touchTooltipData: BarTouchTooltipData(
                      fitInsideVertically: true,
                      fitInsideHorizontally: true,
                      tooltipMargin: 6,
                      getTooltipColor: (_) => widget.isDark
                          ? const Color(0xFF0F172A)
                          : const Color(0xFF1E293B),
                      tooltipBorderRadius: BorderRadius.circular(10),
                      tooltipPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final rec = days[group.x];
                        final dateStr = DateFormat('dd MMM', 'fr').format(rec.date);
                        final hoursStr = formatDuration(rec.hours);
                        return BarTooltipItem(
                          '$dateStr: $hoursStr',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 11.5,
                          ),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 32,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= days.length) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              DateFormat('dd').format(days[index].date),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: widget.onSurface.withValues(alpha: 0.5),
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
                      color: widget.onSurface.withValues(alpha: 0.055),
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
                        : const [Color(0xFF2563EB), Color(0xFF06B6D4)];

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
                            toY: calculatedMaxY,
                            color: widget.onSurface.withValues(
                              alpha: widget.isDark ? 0.06 : 0.04,
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
        ),
      ],
    );
  }
}

class _HoursDataTable extends StatelessWidget {
  final List<AttendanceRecord> records;
  final Color onSurface;
  final bool isDark;

  const _HoursDataTable({
    required this.records,
    required this.onSurface,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: Text(
            'Aucun enregistrement disponible',
            style: TextStyle(color: onSurface.withValues(alpha: 0.4)),
          ),
        ),
      );
    }

    final tableRecords = records.reversed.toList();

    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.02) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        children: [
          // Table header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFEDF2F7),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    'DATE',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w900,
                      color: onSurface.withValues(alpha: 0.6),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'ENTRÉE',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w900,
                      color: onSurface.withValues(alpha: 0.6),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'SORTIE',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w900,
                      color: onSurface.withValues(alpha: 0.6),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    'DURÉE',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w900,
                      color: onSurface.withValues(alpha: 0.6),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Rows
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: tableRecords.length,
            separatorBuilder: (context, index) => Divider(
              height: 1,
              thickness: 1,
              color: isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFE2E8F0),
            ),
            itemBuilder: (context, idx) {
              final r = tableRecords[idx];
              final dateStr = DateFormat('EEE dd MMM', 'fr').format(r.date);
              final isPresent = r.status == AttendanceStatus.present;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isPresent ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            dateStr,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        r.checkIn ?? '--:--',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF2563EB),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        r.checkOut ?? '--:--',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF10B981),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F766E).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            formatDuration(r.hours),
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0F766E),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
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
                            icon: record.status == AttendanceStatus.present ? Icons.check_circle_rounded : Icons.cancel_rounded,
                            label: 'Statut',
                            value: record.status == AttendanceStatus.present ? 'Présent' : 'Absent',
                            color: record.status == AttendanceStatus.present ? const Color(0xFF10B981) : const Color(0xFFEF4444),
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

class _TeamTab extends StatelessWidget {
  final bool isDark;
  final Color onSurface;
  final VoidCallback onSelectMember;

  const _TeamTab({
    super.key,
    required this.isDark,
    required this.onSurface,
    required this.onSelectMember,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer3<TeamProvider, AttendanceProvider, AppProvider>(
      builder: (context, team, attendance, app, _) {
        final currentEmp = attendance.currentEmpCode;
        if (team.currentOwner != currentEmp && currentEmp.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            team.setOwner(currentEmp);
          });
        }

        final members = team.members;
        final presentTodayCount = members.where((m) => team.getTodayStats(m.empCode).hasPunchedToday).length;
        final totalTeamMonthHours = members.fold<double>(0.0, (sum, m) => sum + team.getMonthStats(m.empCode).totalHours);

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 34),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (members.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 44, horizontal: 24),
                      decoration: _premiumCardDecoration(
                        isDark: isDark,
                        surface: isDark ? const Color(0xFF17232D) : Colors.white,
                        tint: const Color(0xFF0F766E),
                        radius: 20,
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 68,
                            height: 68,
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F766E).withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.group_add_rounded,
                              size: 34,
                              color: Color(0xFF0F766E),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Aucun collaborateur enregistré',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: onSurface,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Ajoutez des collaborateurs via leur matricule pour suivre leurs pointages en temps réel.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: onSurface.withValues(alpha: 0.5),
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 22),
                          ElevatedButton.icon(
                            onPressed: () => _showAddEmployeeModal(context),
                            icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                            label: const Text('Ajouter un matricule'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0F766E),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else ...[
                    // Top KPI Summary Cards
                    Row(
                      children: [
                        Expanded(
                          child: _TeamKpiCard(
                            icon: Icons.how_to_reg_rounded,
                            title: "Présents aujourd'hui",
                            value: '$presentTodayCount / ${members.length}',
                            subtitle: presentTodayCount == members.length
                                ? 'Tous présents'
                                : '${members.length - presentTodayCount} non pointé(s)',
                            accentColor: const Color(0xFF10B981),
                            isDark: isDark,
                            onSurface: onSurface,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _TeamKpiCard(
                            icon: Icons.timer_rounded,
                            title: 'Cumul équipe (mois)',
                            value: formatDuration(totalTeamMonthHours),
                            subtitle: '${members.length} collaborateur(s)',
                            accentColor: const Color(0xFF0F766E),
                            isDark: isDark,
                            onSurface: onSurface,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Top bar with team count and add button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: const Color(0xFF0F766E).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.groups_rounded,
                                color: Color(0xFF0F766E),
                                size: 19,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Collaborateurs (${members.length})',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w900,
                                    color: onSurface,
                                  ),
                                ),
                                Text(
                                  'Pointages en direct ZKBioTime',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: onSurface.withValues(alpha: 0.5),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        // Add Button
                        GestureDetector(
                          onTap: () => _showAddEmployeeModal(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF0D9488), Color(0xFF2563EB)],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF0D9488).withValues(alpha: 0.25),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.person_add_alt_1_rounded,
                                  color: Colors.white,
                                  size: 15,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'Ajouter',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: members.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 14),
                      itemBuilder: (context, index) {
                        final member = members[index];
                        final isCurrentActive = attendance.currentEmpCode == member.empCode;
                        final dailyStats = team.getTodayStats(member.empCode);
                        final weekStats = team.getWeekStats(member.empCode);
                        final monthStats = team.getMonthStats(member.empCode);

                        return _TeamMemberCard(
                          member: member,
                          isCurrentActive: isCurrentActive,
                          dailyStats: dailyStats,
                          weekStats: weekStats,
                          monthStats: monthStats,
                          isDark: isDark,
                          onSurface: onSurface,
                          onSelect: () {
                            HapticFeedback.mediumImpact();
                            _showMemberDetailsModal(context, member, team, isDark, onSurface);
                          },
                          onDelete: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                                title: const Text('Retirer le collaborateur ?'),
                                content: Text('Voulez-vous retirer ${member.fullName} de votre liste ?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: const Text('Annuler'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () => Navigator.pop(ctx, true),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFEF4444),
                                      foregroundColor: Colors.white,
                                    ),
                                    child: const Text('Retirer'),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              team.removeMember(member.empCode);
                            }
                          },
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showAddEmployeeModal(BuildContext context) {
    final matriculeController = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    bool isSubmitting = false;
    String? localError;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalContext, setModalState) {
            final bottomPad = MediaQuery.of(modalContext).viewInsets.bottom;

            return Container(
              padding: EdgeInsets.fromLTRB(22, 22, 22, bottomPad + 22),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 28,
                    offset: const Offset(0, -6),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: onSurface.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0D9488), Color(0xFF2563EB)],
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.badge_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Ajouter un collaborateur',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: onSurface,
                              ),
                            ),
                            Text(
                              'Synchronisation directe avec ZKBioTime',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: onSurface.withValues(alpha: 0.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'NUMÉRO DE MATRICULE',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: onSurface.withValues(alpha: 0.55),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: matriculeController,
                    keyboardType: TextInputType.number,
                    autofocus: true,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: onSurface,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Ex: 12345',
                      hintStyle: TextStyle(
                        color: onSurface.withValues(alpha: 0.3),
                      ),
                      filled: true,
                      fillColor: isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : const Color(0xFFF1F5F9),
                      prefixIcon: const Icon(
                        Icons.tag_rounded,
                        color: Color(0xFF0D9488),
                        size: 20,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: Color(0xFF0D9488),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                  if (localError != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline_rounded, size: 16, color: Color(0xFFEF4444)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              localError!,
                              style: const TextStyle(
                                color: Color(0xFFEF4444),
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              final text = matriculeController.text.trim();
                              if (text.isEmpty) {
                                setModalState(() => localError = 'Veuillez saisir un numéro de matricule');
                                return;
                              }
                              setModalState(() {
                                isSubmitting = true;
                                localError = null;
                              });

                              final attendanceProvider = Provider.of<AttendanceProvider>(context, listen: false);
                              final teamProvider = Provider.of<TeamProvider>(context, listen: false);
                              final success = await teamProvider.addMemberByMatricule(
                                text,
                                ownerEmpCode: attendanceProvider.currentEmpCode,
                              );

                              if (success) {
                                if (modalContext.mounted) {
                                  Navigator.pop(modalContext);
                                }
                              } else {
                                setModalState(() {
                                  isSubmitting = false;
                                  localError = teamProvider.errorMessage ?? 'Erreur lors de la vérification';
                                });
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D9488),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Vérifier & Enregistrer',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
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

  void _showMemberDetailsModal(
    BuildContext context,
    TeamMember member,
    TeamProvider team,
    bool isDark,
    Color onSurface,
  ) {
    final report = team.getMemberReport(member.empCode);
    final monthStats = team.getMonthStats(member.empCode);
    final workedDays = report?.days.where((d) => d.punches.isNotEmpty || d.workTimeMinutes > 0).toList() ?? [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (_, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 28,
                    offset: const Offset(0, -6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: onSurface.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF0D9488), Color(0xFF2563EB)],
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            member.firstName.isNotEmpty ? member.firstName[0].toUpperCase() : '?',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                member.fullName,
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w900,
                                  color: onSurface,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Matricule: ${member.empCode} • ${member.department}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: onSurface.withValues(alpha: 0.55),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Divider(height: 1),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _MiniKpiBox(
                                label: 'TOTAL MOIS',
                                value: formatDuration(monthStats.totalHours),
                                icon: Icons.timer_rounded,
                                color: const Color(0xFF0F766E),
                                isDark: isDark,
                                onSurface: onSurface,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _MiniKpiBox(
                                label: 'JOURS TRAVAILLÉS',
                                value: '${monthStats.daysWorked} j',
                                icon: Icons.calendar_today_rounded,
                                color: const Color(0xFF7C3AED),
                                isDark: isDark,
                                onSurface: onSurface,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _MiniKpiBox(
                                label: 'MOYENNE / J',
                                value: formatDuration(monthStats.avgHours),
                                icon: Icons.speed_rounded,
                                color: const Color(0xFF2563EB),
                                isDark: isDark,
                                onSurface: onSurface,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'DÉTAIL DES POINTAGES (${workedDays.length} JOURS)',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                            color: onSurface.withValues(alpha: 0.55),
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (workedDays.isEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            alignment: Alignment.center,
                            child: Text(
                              'Aucun pointage enregistré pour ce mois.',
                              style: TextStyle(
                                fontSize: 13,
                                color: onSurface.withValues(alpha: 0.5),
                              ),
                            ),
                          )
                        else
                          ...workedDays.map((d) {
                            final dateLabel = DateFormat('EEEE d MMMM yyyy', 'fr').format(d.date);
                            final hours = d.workTimeMinutes / 60.0;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0F766E).withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.access_time_filled_rounded,
                                      color: Color(0xFF0F766E),
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          dateLabel,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w800,
                                            color: onSurface,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          'Entrée: ${d.entryTime}  •  Sortie: ${d.exitTime}',
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w600,
                                            color: onSurface.withValues(alpha: 0.55),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0F766E).withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      formatDuration(hours),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w900,
                                        color: Color(0xFF0F766E),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                      ],
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
}

class _TeamMemberCard extends StatelessWidget {
  final TeamMember member;
  final bool isCurrentActive;
  final MemberDailyStats dailyStats;
  final MemberPeriodStats weekStats;
  final MemberPeriodStats monthStats;
  final bool isDark;
  final Color onSurface;
  final VoidCallback onSelect;
  final VoidCallback onDelete;

  const _TeamMemberCard({
    required this.member,
    required this.isCurrentActive,
    required this.dailyStats,
    required this.weekStats,
    required this.monthStats,
    required this.isDark,
    required this.onSurface,
    required this.onSelect,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? const Color(0xFF17232D) : Colors.white;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface.withValues(alpha: isDark ? 0.88 : 0.94),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isCurrentActive
              ? const Color(0xFF0D9488)
              : isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : const Color(0xFFE2E8F0),
          width: isCurrentActive ? 1.8 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isCurrentActive
                ? const Color(0xFF0D9488).withValues(alpha: isDark ? 0.15 : 0.12)
                : Colors.black.withValues(alpha: isDark ? 0.10 : 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Avatar, Name, Matricule, and Delete
          Row(
            children: [
              // Avatar
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    member.firstName.isNotEmpty
                        ? member.firstName[0].toUpperCase()
                        : member.empCode[0],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            member.fullName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: onSurface,
                            ),
                          ),
                        ),
                        if (isCurrentActive) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0D9488),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'ACTIF',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Mat: ${member.empCode}',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF2563EB),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '• ${member.department}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Delete Button
              IconButton(
                icon: Icon(
                  Icons.delete_outline_rounded,
                  size: 19,
                  color: onSurface.withValues(alpha: 0.3),
                ),
                onPressed: onDelete,
                tooltip: 'Retirer',
              ),
            ],
          ),
          const SizedBox(height: 14),
          // 3 Metric Pills: Aujourd'hui, Semaine, Mois
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.03) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFEDF2F7),
              ),
            ),
            child: Row(
              children: [
                // Aujourd'hui
                Expanded(
                  child: _MiniTeamStat(
                    label: "AUJOURD'HUI",
                    value: dailyStats.hasPunchedToday
                        ? (dailyStats.isCurrentlyWorking
                            ? 'En poste (${dailyStats.checkIn})'
                            : formatDuration(dailyStats.hours))
                        : 'Non pointé',
                    dotColor: dailyStats.hasPunchedToday
                        ? (dailyStats.isCurrentlyWorking ? const Color(0xFF10B981) : const Color(0xFF2563EB))
                        : const Color(0xFF94A3B8),
                    onSurface: onSurface,
                  ),
                ),
                Container(
                  width: 1,
                  height: 32,
                  color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                ),
                // Semaine
                Expanded(
                  child: _MiniTeamStat(
                    label: 'SEMAINE',
                    value: '${formatDuration(weekStats.totalHours)} (${weekStats.daysWorked}j)',
                    dotColor: const Color(0xFF7C3AED),
                    onSurface: onSurface,
                  ),
                ),
                Container(
                  width: 1,
                  height: 32,
                  color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                ),
                // Mois
                Expanded(
                  child: _MiniTeamStat(
                    label: 'MOIS',
                    value: '${formatDuration(monthStats.totalHours)} (${monthStats.daysWorked}j)',
                    dotColor: const Color(0xFF0F766E),
                    onSurface: onSurface,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Action Button: View Detailed Member Stats
          SizedBox(
            width: double.infinity,
            height: 40,
            child: OutlinedButton.icon(
              onPressed: onSelect,
              icon: const Icon(
                Icons.analytics_rounded,
                size: 16,
                color: Color(0xFF0F766E),
              ),
              label: const Text(
                'Voir le rapport détaillé',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F766E),
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: const Color(0xFF0F766E).withValues(alpha: 0.35),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                backgroundColor: const Color(0xFF0F766E).withValues(alpha: 0.04),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniKpiBox extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool isDark;
  final Color onSurface;

  const _MiniKpiBox({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.isDark,
    required this.onSurface,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              color: onSurface.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniTeamStat extends StatelessWidget {
  final String label;
  final String value;
  final Color dotColor;
  final Color onSurface;

  const _MiniTeamStat({
    required this.label,
    required this.value,
    required this.dotColor,
    required this.onSurface,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: dotColor,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: onSurface.withValues(alpha: 0.45),
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _TeamKpiCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String subtitle;
  final Color accentColor;
  final bool isDark;
  final Color onSurface;

  const _TeamKpiCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.accentColor,
    required this.isDark,
    required this.onSurface,
  });

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? const Color(0xFF17232D) : Colors.white;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: _premiumCardDecoration(
        isDark: isDark,
        surface: surface,
        tint: accentColor,
        radius: 18,
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: accentColor, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: onSurface.withValues(alpha: 0.55),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: onSurface,
                  ),
                ),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                    color: accentColor,
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


