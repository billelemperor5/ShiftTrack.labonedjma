import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../core/theme/app_design.dart';
import '../../../models/attendance_record.dart';
import '../../../providers/attendance_provider.dart';

class CalendarWidget extends StatefulWidget {
  const CalendarWidget({super.key});

  @override
  State<CalendarWidget> createState() => _CalendarWidgetState();
}

class _CalendarWidgetState extends State<CalendarWidget> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay = DateTime.now();

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    HapticFeedback.lightImpact();
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
    });

    final provider = context.read<AttendanceProvider>();
    final summary = provider.getDaySummaryForDate(selectedDay);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final dateStr = DateFormat('EEEE dd MMMM yyyy', 'fr').format(selectedDay);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF111827) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
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
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: onSurface.withValues(alpha: 0.15),
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
                      color: const Color(0xFF0F766E).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.fingerprint_rounded, color: Color(0xFF0F766E), size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dateStr,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: onSurface,
                          ),
                        ),
                        Text(
                          summary != null && summary.punches.isNotEmpty
                              ? summary.status
                              : 'Jour non pointé',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: summary != null && summary.punches.isNotEmpty
                                ? const Color(0xFF10B981)
                                : onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              if (summary != null && summary.punches.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Entrée (Premier pointage):', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: onSurface.withValues(alpha: 0.7))),
                          Text(summary.entryTime ?? '--:--', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: onSurface)),
                        ],
                      ),
                      const Divider(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Sortie (Dernier pointage):', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: onSurface.withValues(alpha: 0.7))),
                          Text(summary.exitTime ?? '--:--', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: onSurface)),
                        ],
                      ),
                      const Divider(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Temps travaillé:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: onSurface.withValues(alpha: 0.7))),
                          Text(summary.workTimeStr, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0F766E))),
                        ],
                      ),
                    ],
                  ),
                ),
              ] else ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.03) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      'Aucun pointage biométrique enregistré pour ce jour',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F766E),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Fermer', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _goToMonth(int delta, AttendanceProvider attendance) {
    final nextMonth = DateTime(_focusedDay.year, _focusedDay.month + delta, 1);
    HapticFeedback.selectionClick();
    setState(() {
      _focusedDay = nextMonth;
      _selectedDay = nextMonth;
    });
    attendance.setViewedMonth(nextMonth);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Consumer<AttendanceProvider>(
      builder: (context, attendance, child) {
        final monthRecords = attendance.records
            .where(
              (record) =>
                  record.date.year == _focusedDay.year &&
                  record.date.month == _focusedDay.month,
            )
            .toList();
        final presentCount = monthRecords
            .where((record) => record.status == AttendanceStatus.present)
            .length;
        final absentCount = monthRecords
            .where((record) => record.status == AttendanceStatus.absent)
            .length;
        final openCount = monthRecords
            .where(
              (record) =>
                  record.status == AttendanceStatus.present &&
                  record.checkOut == null,
            )
            .length;

        final showDatePill =
            _selectedDay != null &&
            _selectedDay!.month == _focusedDay.month &&
            _selectedDay!.year == _focusedDay.year;

        return LayoutBuilder(
          builder: (context, constraints) {
            final availableWidth = constraints.maxWidth - 56;
            final dayCellSize = ((availableWidth / 7) - 10.5).clamp(29.0, 35.0);
            final rowHeight = (dayCellSize + 11).clamp(42.0, 46.0);
            final badgeSize = (dayCellSize * 0.35).clamp(11.5, 13.0);

            return TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 520),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, 18 * (1 - value)),
                    child: child,
                  ),
                );
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: AppDesign.premiumCard(
                  isDark: isDark,
                  tint: const Color(0xFF2563EB),
                  radius: 26,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        _NavButton(
                          icon: Icons.chevron_left_rounded,
                          onTap: () => _goToMonth(-1, attendance),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Container(
                            height: 54,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
                              ),
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF2563EB,
                                  ).withValues(alpha: 0.18),
                                  blurRadius: 18,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.calendar_month_rounded,
                                  color: Colors.white,
                                  size: 19,
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    showDatePill
                                        ? '${_selectedDay!.day} ${_monthName(_selectedDay!.month)} ${_selectedDay!.year}'
                                        : '${_monthName(_focusedDay.month)} ${_focusedDay.year}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        _NavButton(
                          icon: Icons.chevron_right_rounded,
                          onTap: () => _goToMonth(1, attendance),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        _LegendChip(
                          label: 'Présent',
                          value: presentCount,
                          color: const Color(0xFF10B981),
                        ),
                        const SizedBox(width: 8),
                        _LegendChip(
                          label: 'Absent',
                          value: absentCount,
                          color: const Color(0xFFF43F5E),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _LegendChip(
                          label: 'Ouvert',
                          value: openCount,
                          color: const Color(0xFFF59E0B),
                        ),
                        const SizedBox(width: 8),
                        const _LegendChip(
                          label: 'Non traité',
                          value: 0,
                          color: Color(0xFFCBD5E1),
                          showValue: false,
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.035)
                            : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.07)
                              : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: TableCalendar(
                        key: ValueKey(
                          '${_focusedDay.year}-${_focusedDay.month}',
                        ),
                        firstDay: DateTime.utc(2020, 1, 1),
                        lastDay: DateTime.utc(2030, 12, 31),
                        focusedDay: _focusedDay,
                        selectedDayPredicate: (day) =>
                            isSameDay(_selectedDay, day),
                        locale: 'fr',
                        startingDayOfWeek: StartingDayOfWeek.monday,
                        headerVisible: false,
                        availableGestures: AvailableGestures.none,
                        rowHeight: rowHeight,
                        daysOfWeekHeight: 34,
                        calendarStyle: const CalendarStyle(
                          outsideDaysVisible: false,
                          cellMargin: EdgeInsets.zero,
                        ),
                        daysOfWeekStyle: DaysOfWeekStyle(
                          weekdayStyle: TextStyle(
                            color: onSurface.withValues(alpha: 0.45),
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                          weekendStyle: TextStyle(
                            color: onSurface.withValues(alpha: 0.45),
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        calendarBuilders: CalendarBuilders(
                          dowBuilder: (context, day) {
                            final isFriday = day.weekday == DateTime.friday;
                            return Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: isFriday
                                      ? const Color(
                                          0xFFF43F5E,
                                        ).withValues(alpha: 0.08)
                                      : onSurface.withValues(alpha: 0.055),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  _shortDayName(day.weekday),
                                  maxLines: 1,
                                  style: TextStyle(
                                    color: isFriday
                                        ? const Color(0xFFF43F5E)
                                        : onSurface.withValues(alpha: 0.55),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            );
                          },
                          defaultBuilder: (context, day, focusedDay) =>
                              _dayCell(
                                day,
                                attendance,
                                size: dayCellSize,
                                badgeSize: badgeSize,
                              ),
                          todayBuilder: (context, day, focusedDay) => _dayCell(
                            day,
                            attendance,
                            isToday: true,
                            size: dayCellSize,
                            badgeSize: badgeSize,
                          ),
                          selectedBuilder: (context, day, focusedDay) =>
                              _dayCell(
                                day,
                                attendance,
                                isSelected: true,
                                size: dayCellSize,
                                badgeSize: badgeSize,
                              ),
                          disabledBuilder: (context, day, focusedDay) => Center(
                            child: Text(
                              '${day.day}',
                              style: TextStyle(
                                color: onSurface.withValues(alpha: 0.16),
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        onDaySelected: _onDaySelected,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _dayCell(
    DateTime day,
    AttendanceProvider provider, {
    bool isToday = false,
    bool isSelected = false,
    double size = 42,
    double badgeSize = 16,
  }) {
    final record = provider.getRecordForDate(day);
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color bg = isDark
        ? Colors.white.withValues(alpha: 0.02)
        : Colors.white.withValues(alpha: 0.72);
    Color textColor = onSurface.withValues(alpha: 0.70);
    Border? border;
    List<BoxShadow>? shadow;
    List<Color>? gradient;
    Color? badgeColor;
    IconData? badgeIcon;

    if (record != null) {
      if (record.status == AttendanceStatus.absent) {
        gradient = const [Color(0xFFEF4444), Color(0xFFF43F5E)];
        badgeColor = const Color(0xFFFFE4E6);
        badgeIcon = Icons.close_rounded;
      } else if (record.checkOut == null) {
        gradient = const [Color(0xFFF59E0B), Color(0xFFF97316)];
        badgeColor = const Color(0xFFFFEDD5);
        badgeIcon = Icons.schedule_rounded;
      } else {
        gradient = const [Color(0xFF10B981), Color(0xFF14B8A6)];
        badgeColor = const Color(0xFFDCFCE7);
        badgeIcon = Icons.check_rounded;
      }
      textColor = Colors.white;
      shadow = [
        BoxShadow(
          color: gradient.first.withValues(alpha: 0.22),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ];
    }

    if (isToday && record == null) {
      border = Border.all(color: const Color(0xFF2563EB), width: 1.5);
      shadow = [
        BoxShadow(
          color: const Color(0xFF2563EB).withValues(alpha: 0.16),
          blurRadius: 14,
          spreadRadius: 1,
        ),
      ];
    }

    if (isToday && record != null) {
      border = Border.all(
        color: Colors.white.withValues(alpha: 0.78),
        width: 1,
      );
    }

    if (isSelected && record == null) {
      gradient = const [Color(0xFF2563EB), Color(0xFF7C3AED)];
      textColor = Colors.white;
      shadow = [
        BoxShadow(
          color: const Color(0xFF2563EB).withValues(alpha: 0.28),
          blurRadius: 14,
          offset: const Offset(0, 6),
        ),
      ];
    }

    if (isSelected && record != null) {
      border = Border.all(
        color: Colors.white.withValues(alpha: 0.82),
        width: 1,
      );
    }

    if (record == null &&
        !isToday &&
        !isSelected &&
        day.weekday == DateTime.friday) {
      textColor = onSurface.withValues(alpha: 0.25);
    }

    return Center(
      child: AnimatedScale(
        scale: 1,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOutCubic,
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: gradient == null ? bg : null,
            gradient: gradient == null
                ? null
                : LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: gradient,
                  ),
            borderRadius: BorderRadius.circular(size * 0.34),
            border: border,
            boxShadow: shadow,
          ),
          alignment: Alignment.center,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Center(
                child: Text(
                  '${day.day}',
                  style: TextStyle(
                    color: textColor,
                    fontSize: size >= 34 ? 14.2 : 13.2,
                    fontWeight: record != null || isToday || isSelected
                        ? FontWeight.w900
                        : FontWeight.w700,
                  ),
                ),
              ),
              if (badgeColor != null && badgeIcon != null)
                Positioned(
                  right: -1,
                  top: -1,
                  child: Container(
                    width: badgeSize,
                    height: badgeSize,
                    decoration: BoxDecoration(
                      color: badgeColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1),
                    ),
                    child: Icon(
                      badgeIcon,
                      size: badgeSize * 0.62,
                      color: gradient?.first,
                    ),
                  ),
                ),
              if (isToday)
                Positioned(
                  top: 4,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      width: 5,
                      height: 5,
                      decoration: const BoxDecoration(
                        color: Color(0xFF60A5FA),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _shortDayName(int weekday) {
    const names = ['lun.', 'mar.', 'mer.', 'jeu.', 'ven.', 'sam.', 'dim.'];
    return names[weekday - 1];
  }

  String _monthName(int month) {
    const names = [
      'Janvier',
      'Février',
      'Mars',
      'Avril',
      'Mai',
      'Juin',
      'Juillet',
      'Août',
      'Septembre',
      'Octobre',
      'Novembre',
      'Décembre',
    ];
    return names[month - 1];
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _NavButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.white.withValues(alpha: 0.86),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: onSurface.withValues(alpha: 0.07)),
          ),
          child: Icon(icon, color: onSurface.withValues(alpha: 0.78), size: 26),
        ),
      ),
    );
  }
}

class _LegendChip extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  final bool showValue;

  const _LegendChip({
    required this.label,
    required this.value,
    required this.color,
    this.showValue = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isDark ? 0.16 : 0.09),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.16)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 7),
            Flexible(
              child: Text(
                showValue ? '$label  $value' : label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isDark
                      ? Colors.white
                      : onSurface.withValues(alpha: 0.82),
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
