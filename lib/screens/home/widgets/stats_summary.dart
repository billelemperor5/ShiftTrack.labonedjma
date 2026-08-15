import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/attendance_provider.dart';
import '../../../models/attendance_record.dart';

class StatsSummary extends StatelessWidget {
  const StatsSummary({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AttendanceProvider>(
      builder: (context, attendance, child) {
        final focusedDate = attendance.viewedMonth;
        final recs = attendance.records
            .where(
              (r) =>
                  r.date.year == focusedDate.year &&
                  r.date.month == focusedDate.month,
            )
            .toList();

        int present = recs
            .where((r) => r.status == AttendanceStatus.present)
            .length;
        int absent = recs
            .where((r) => r.status == AttendanceStatus.absent)
            .length;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Expanded(
                child: _Card(
                  'Enregistré',
                  '${recs.length}',
                  Icons.event_note_rounded,
                  const [Color(0xFF2563EB), Color(0xFF60A5FA)],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _Card(
                  'Présent',
                  '$present',
                  Icons.check_circle_rounded,
                  const [Color(0xFF059669), Color(0xFF34D399)],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _Card('Absent', '$absent', Icons.cancel_rounded, const [
                  Color(0xFFDC2626),
                  Color(0xFFF87171),
                ]),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Card extends StatelessWidget {
  final String title, value;
  final IconData icon;
  final List<Color> colors;
  const _Card(this.title, this.value, this.icon, this.colors);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: colors.first.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white.withValues(alpha: 0.85), size: 26),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
