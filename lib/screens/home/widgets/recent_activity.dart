import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/attendance_provider.dart';

import '../../../models/attendance_record.dart';
import '../../../core/utils/time_utils.dart';

class RecentActivity extends StatelessWidget {
  const RecentActivity({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AttendanceProvider>(
      builder: (context, attendance, child) {
        final records = List<AttendanceRecord>.from(attendance.records)
          ..sort((a, b) => b.date.compareTo(a.date));
        final recentRecords = records.take(3).toList();

        if (recentRecords.isEmpty) {
          return const SizedBox.shrink();
        }

        final onSurface = Theme.of(context).colorScheme.onSurface;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Activité récente',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                  color: onSurface,
                ),
              ),
              const SizedBox(height: 16),
              ...recentRecords.map(
                (record) => _buildRecordTile(context, record),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRecordTile(BuildContext context, AttendanceRecord record) {
    final dateStr = DateFormat('EEEE, dd MMM', 'fr').format(record.date);
    final isPresent = record.status == AttendanceStatus.present;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final outline = Theme.of(context).colorScheme.outline;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [onSurface.withValues(alpha: 0.03), Colors.transparent],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.1 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(
          color: outline.withValues(alpha: isDark ? 0.5 : 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isPresent
                  ? const Color(0xFF10B981).withValues(alpha: 0.1)
                  : const Color(0xFFEF4444).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isPresent ? Icons.login_rounded : Icons.logout_rounded,
              color: isPresent
                  ? const Color(0xFF10B981)
                  : const Color(0xFFEF4444),
              size: 22,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dateStr,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: onSurface,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isPresent ? 'Journée complétée' : 'Journée d\'absence',
                  style: TextStyle(
                    color: onSurface.withValues(alpha: 0.3),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (isPresent)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  formatDuration(record.hours),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    color: AppColors.primaryOrange,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  '${record.checkIn} - ${record.checkOut}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: onSurface.withValues(alpha: 0.3),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
