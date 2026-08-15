import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/attendance_provider.dart';
import '../../../providers/app_provider.dart';
import '../../../models/attendance_record.dart';
import '../../../widgets/custom_button.dart';
import '../../face_checkin/face_checkin_screen.dart';

class AttendanceBottomSheet extends StatefulWidget {
  final DateTime selectedDate;

  const AttendanceBottomSheet({super.key, required this.selectedDate});

  @override
  State<AttendanceBottomSheet> createState() => _AttendanceBottomSheetState();
}

class _AttendanceBottomSheetState extends State<AttendanceBottomSheet> {
  late String _checkInTime;
  late String _checkOutTime;
  List<WorkSession> _extraSessions = [];
  bool _isPresenting = false;

  @override
  void initState() {
    super.initState();
    final userProfile = context.read<AppProvider>().userProfile;
    final existingRecord = context.read<AttendanceProvider>().getRecordForDate(
      widget.selectedDate,
    );

    _checkInTime = userProfile?.defaultCheckIn ?? "08:00";
    _checkOutTime = userProfile?.defaultCheckOut ?? "17:00";

    if (existingRecord != null &&
        existingRecord.status == AttendanceStatus.present &&
        existingRecord.checkOut != null) {
      _isPresenting = true;
      _checkInTime = existingRecord.checkIn ?? _checkInTime;
      _checkOutTime = existingRecord.checkOut ?? _checkOutTime;
      _extraSessions = List.from(existingRecord.extraSessions ?? []);
    }
  }

  Future<void> _selectExtraTime(int index, bool isStart) async {
    final session = _extraSessions[index];
    final parts = (isStart ? session.startTime : session.endTime).split(':');
    final picked = await _pickTime(context, parts);

    if (picked != null) {
      setState(() {
        final formatted =
            '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
        if (isStart) {
          session.startTime = formatted;
        } else {
          session.endTime = formatted;
        }
      });
    }
  }

  Future<TimeOfDay?> _pickTime(BuildContext context, List<String> parts) {
    return showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      ),
    );
  }

  void _addExtraSession() {
    setState(() {
      _extraSessions.add(
        WorkSession(startTime: "20:00", endTime: "22:00", hours: 2.0),
      );
    });
  }

  void _removeExtraSession(int index) {
    setState(() {
      _extraSessions.removeAt(index);
    });
  }

  double _calculateHours(String start, String end, {int deductionMinutes = 0}) {
    final inParts = start.split(':');
    final outParts = end.split(':');
    final inDate = DateTime(
      2000,
      1,
      1,
      int.parse(inParts[0]),
      int.parse(inParts[1]),
    );
    final outDate = DateTime(
      2000,
      1,
      1,
      int.parse(outParts[0]),
      int.parse(outParts[1]),
    );
    var diffMinutes = outDate.difference(inDate).inMinutes;
    if (diffMinutes < 0) diffMinutes += 24 * 60;
    if (diffMinutes > 240) {
      diffMinutes -= deductionMinutes;
    }
    return diffMinutes / 60.0;
  }

  void _save(AttendanceStatus status) {
    double totalHours = 0.0;
    final profile = context.read<AppProvider>().userProfile;
    final breakDeduction = (profile?.isBreakPaid ?? true)
        ? 0
        : (profile?.breakDuration ?? 0);

    if (status == AttendanceStatus.present) {
      totalHours = _calculateHours(
        _checkInTime,
        _checkOutTime,
        deductionMinutes: breakDeduction,
      );
      for (var session in _extraSessions) {
        session.hours = _calculateHours(session.startTime, session.endTime);
        totalHours += session.hours;
      }
    }

    // Calculate the scheduled (expected) hours from current defaults
    double scheduledH = 0.0;
    if (status == AttendanceStatus.present) {
      final defIn = profile?.defaultCheckIn ?? '08:00';
      final defOut = profile?.defaultCheckOut ?? '17:00';
      scheduledH = _calculateHours(
        defIn,
        defOut,
        deductionMinutes: breakDeduction,
      ).clamp(0, 24);
    }

    final record = AttendanceRecord(
      date: widget.selectedDate,
      status: status,
      checkIn: status == AttendanceStatus.present ? _checkInTime : null,
      checkOut: status == AttendanceStatus.present ? _checkOutTime : null,
      hours: totalHours,
      extraSessions: _extraSessions,
      scheduledHours: scheduledH,
    );

    context.read<AttendanceProvider>().addOrUpdateRecord(record);
    if (status == AttendanceStatus.present) {
      _showSuccessOverlay(totalHours);
    } else {
      Navigator.pop(context);
    }
  }

  void _delete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: const Text('Voulez-vous vraiment effacer ce record ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.errorRed),
            onPressed: () {
              Navigator.pop(context); // Close dialog
              context.read<AttendanceProvider>().deleteRecord(
                widget.selectedDate,
              );
              Navigator.pop(this.context); // Close bottom sheet
            },
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  void _punch(String mode, String timeStr) {
    if (timeStr.isEmpty) return;
    final profile = context.read<AppProvider>().userProfile;
    final existingRecord = context.read<AttendanceProvider>().getRecordForDate(
      widget.selectedDate,
    );
    final breakDeduction = (profile?.isBreakPaid ?? true)
        ? 0
        : (profile?.breakDuration ?? 0);

    List<WorkSession> sessions = [];

    if (mode == 'checkin') {
      // Compute scheduled hours from current defaults
      final defIn = profile?.defaultCheckIn ?? '08:00';
      final defOut = profile?.defaultCheckOut ?? '17:00';
      double scheduledH = _calculateHours(
        defIn,
        defOut,
        deductionMinutes: breakDeduction,
      ).clamp(0, 24);

      // Morning: save only check-in, NO check-out yet
      final record = AttendanceRecord(
        date: widget.selectedDate,
        status: AttendanceStatus.present,
        checkIn: timeStr,
        checkOut: null,
        hours: 0,
        extraSessions: sessions,
        scheduledHours: scheduledH,
      );
      context.read<AttendanceProvider>().addOrUpdateRecord(record);
      if (mounted) setState(() {});
      _showCheckinOverlay();
    } else {
      // Evening: set check-out and calculate hours
      String checkIn = existingRecord?.checkIn ?? timeStr;
      if (existingRecord != null) {
        sessions = List.from(existingRecord.extraSessions ?? []);
      }

      double totalHours = _calculateHours(
        checkIn,
        timeStr,
        deductionMinutes: breakDeduction,
      );
      for (var s in sessions) {
        totalHours += s.hours;
      }

      // Keep the scheduled hours from the existing record (set during check-in)
      double scheduledH = existingRecord?.scheduledHours ?? 0.0;
      if (scheduledH == 0) {
        final defIn = profile?.defaultCheckIn ?? '08:00';
        final defOut = profile?.defaultCheckOut ?? '17:00';
        scheduledH = _calculateHours(
          defIn,
          defOut,
          deductionMinutes: breakDeduction,
        ).clamp(0, 24);
      }

      final record = AttendanceRecord(
        date: widget.selectedDate,
        status: AttendanceStatus.present,
        checkIn: checkIn,
        checkOut: timeStr,
        hours: totalHours,
        extraSessions: sessions,
        scheduledHours: scheduledH,
      );
      context.read<AttendanceProvider>().addOrUpdateRecord(record);
      if (mounted) setState(() {});
      _showSuccessOverlay(totalHours);
    }
  }

  void _manualPunch(String mode) async {
    final now = TimeOfDay.now();
    final parts = [now.hour.toString(), now.minute.toString().padLeft(2, '0')];
    final picked = await _pickTime(context, parts);
    if (picked != null) {
      final timeStr =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      _punch(mode, timeStr);
    }
  }

  void _openFaceCheckin(String mode) async {
    final timeStr = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => FaceCheckinScreen(mode: mode)),
    );
    if (timeStr != null && mounted) {
      _punch(mode, timeStr);
    }
  }

  void _showCheckinOverlay() async {
    final navigator = Navigator.of(context);
    navigator.pop(); // Close bottom sheet immediately

    showGeneralDialog(
      context: navigator.context,
      barrierDismissible: false,
      barrierLabel: 'Checkin',
      barrierColor: Colors.black.withValues(alpha: 0.85),
      transitionDuration: const Duration(milliseconds: 500),
      pageBuilder: (context, anim1, anim2) {
        return const _CheckinSuccessDialog();
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: anim1, curve: Curves.easeOutBack),
          child: FadeTransition(opacity: anim1, child: child),
        );
      },
    );

    await Future.delayed(const Duration(seconds: 2));
    if (navigator.canPop()) {
      navigator.pop(); // Close dialog
    }
  }

  void _showSuccessOverlay(double hours) async {
    final navigator = Navigator.of(context);
    navigator.pop(); // Close bottom sheet immediately

    showGeneralDialog(
      context: navigator.context,
      barrierDismissible: false,
      barrierLabel: 'Success',
      barrierColor: Colors.black.withValues(alpha: 0.85),
      transitionDuration: const Duration(milliseconds: 500),
      pageBuilder: (context, anim1, anim2) {
        return _SuccessDialog(hours: hours);
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: anim1, curve: Curves.easeOutBack),
          child: FadeTransition(opacity: anim1, child: child),
        );
      },
    );

    await Future.delayed(const Duration(seconds: 2));
    if (navigator.canPop()) {
      navigator.pop(); // Close dialog
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('dd MMM yyyy', 'fr').format(widget.selectedDate);
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final outline = Theme.of(context).colorScheme.outline;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Consumer<AttendanceProvider>(
      builder: (context, provider, _) {
        final existingRecord = provider.getRecordForDate(widget.selectedDate);

        return AnimatedPadding(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? const [Color(0xFF111827), Color(0xFF17232D)]
                    : const [
                        Colors.white,
                        Color(0xFFF8FBFA),
                        Color(0xFFF3F7FF),
                      ],
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(32),
              ),
              border: Border.all(color: outline.withValues(alpha: 0.12)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.10),
                  blurRadius: 34,
                  offset: const Offset(0, -10),
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: onSurface.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
                        ),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF2563EB,
                            ).withValues(alpha: 0.20),
                            blurRadius: 16,
                            offset: const Offset(0, 7),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.fact_check_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pointage du jour',
                            style: TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.3,
                              color: onSurface,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            dateStr,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: onSurface.withValues(alpha: 0.48),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (existingRecord != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color:
                              (existingRecord.status == AttendanceStatus.present
                                      ? const Color(0xFF10B981)
                                      : const Color(0xFFEF4444))
                                  .withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          existingRecord.status == AttendanceStatus.present
                              ? 'Présent'
                              : 'Absent',
                          style: TextStyle(
                            color:
                                existingRecord.status ==
                                    AttendanceStatus.present
                                ? const Color(0xFF10B981)
                                : const Color(0xFFEF4444),
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 22),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: onSurface.withValues(alpha: isDark ? 0.045 : 0.035),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: outline.withValues(alpha: 0.12)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _StatusMiniInfo(
                          color: const Color(0xFF10B981),
                          icon: Icons.login_rounded,
                          label: 'Arrivée',
                          value: existingRecord?.checkIn ?? '--:--',
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 42,
                        color: outline.withValues(alpha: 0.12),
                      ),
                      Expanded(
                        child: _StatusMiniInfo(
                          color: const Color(0xFFEF4444),
                          icon: Icons.logout_rounded,
                          label: 'Départ',
                          value: existingRecord?.checkOut ?? '--:--',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                if (!_isPresenting) ...[
                  Row(
                    children: [
                      Expanded(
                        child: _buildQuickButton(
                          context,
                          'Présent',
                          Icons.check_circle_rounded,
                          const Color(0xFF10B981),
                          () => setState(() => _isPresenting = true),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildQuickButton(
                          context,
                          'Absent',
                          Icons.cancel_rounded,
                          const Color(0xFFEF4444),
                          () => _save(AttendanceStatus.absent),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _buildQuickPunchCard(
                    context,
                    onSurface,
                    outline,
                    existingRecord,
                  ),
                  const SizedBox(height: 14),
                  if (context
                          .read<AppProvider>()
                          .userProfile
                          ?.faceCheckinEnabled ??
                      false) ...[
                    _buildFaceCheckinCard(
                      context,
                      onSurface,
                      outline,
                      existingRecord,
                    ),
                    const SizedBox(height: 10),
                  ],
                  if (existingRecord != null) ...[
                    _PressableCard(
                      onTap: _delete,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.errorRed.withValues(alpha: 0.11),
                              AppColors.errorRed.withValues(alpha: 0.055),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: AppColors.errorRed.withValues(alpha: 0.18),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.errorRed.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.errorRed.withValues(
                                  alpha: 0.1,
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.delete_sweep_rounded,
                                color: AppColors.errorRed,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Effacer le record du jour',
                              style: TextStyle(
                                color: AppColors.errorRed,
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ] else ...[
                  Row(
                    children: [
                      Expanded(
                        child: _TimeBox(
                          title: 'Arrivée',
                          time: _checkInTime,
                          onTap: () async {
                            final picked = await _pickTime(
                              context,
                              _checkInTime.split(':'),
                            );
                            if (picked != null) {
                              setState(
                                () => _checkInTime =
                                    '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}',
                              );
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _TimeBox(
                          title: 'Départ',
                          time: _checkOutTime,
                          onTap: () async {
                            final picked = await _pickTime(
                              context,
                              _checkOutTime.split(':'),
                            );
                            if (picked != null) {
                              setState(
                                () => _checkOutTime =
                                    '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}',
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  if (_extraSessions.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Container(
                          width: 4,
                          height: 16,
                          decoration: BoxDecoration(
                            color: AppColors.brandPurple,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Sessions supplémentaires',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: onSurface,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...List.generate(_extraSessions.length, (index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: _TimeBox(
                                title: 'Début',
                                time: _extraSessions[index].startTime,
                                onTap: () => _selectExtraTime(index, true),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _TimeBox(
                                title: 'Fin',
                                time: _extraSessions[index].endTime,
                                onTap: () => _selectExtraTime(index, false),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              onPressed: () => _removeExtraSession(index),
                              icon: const Icon(
                                Icons.remove_circle_outline,
                                color: Colors.redAccent,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: _addExtraSession,
                    icon: const Icon(Icons.add_circle_outline, size: 18),
                    label: const Text('Ajouter une session'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.brandPurple,
                      side: const BorderSide(
                        color: AppColors.brandPurple,
                        width: 1.5,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  CustomButton(
                    text: 'Confirmer',
                    onPressed: () => _save(AttendanceStatus.present),
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () => setState(() => _isPresenting = false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: onSurface.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: onSurface.withValues(alpha: 0.1),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'Retour',
                          style: TextStyle(
                            color: onSurface.withValues(alpha: 0.5),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickButton(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return _PressableCard(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withValues(alpha: 0.13),
              color.withValues(alpha: 0.06),
            ],
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: color.withValues(alpha: 0.18), width: 1),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickPunchCard(
    BuildContext context,
    Color onSurface,
    Color outline,
    AttendanceRecord? existingRecord,
  ) {
    final hasCheckin =
        existingRecord != null &&
        existingRecord.status == AttendanceStatus.present &&
        existingRecord.checkIn != null;
    final hasCheckout = hasCheckin && existingRecord.checkOut != null;
    final isComplete = hasCheckin && hasCheckout;

    final cardColor = AppColors.brandPurple;

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            cardColor.withValues(alpha: 0.11),
            cardColor.withValues(alpha: 0.045),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: cardColor.withValues(alpha: 0.17)),
        boxShadow: [
          BoxShadow(
            color: cardColor.withValues(alpha: 0.07),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: cardColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  isComplete
                      ? Icons.check_circle_rounded
                      : (hasCheckin
                            ? Icons.logout_rounded
                            : Icons.timer_rounded),
                  color: isComplete ? AppColors.successGreen : cardColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pointage rapide',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: onSurface,
                      ),
                    ),
                    Text(
                      isComplete
                          ? 'Journée complète ✓'
                          : hasCheckin
                          ? 'Arrivée à ${existingRecord.checkIn}'
                          : 'Pointer l\'heure manuellement',
                      style: TextStyle(
                        fontSize: 11,
                        color: isComplete
                            ? AppColors.successGreen
                            : onSurface.withValues(alpha: 0.4),
                        fontWeight: isComplete
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (!isComplete) ...[
            const SizedBox(height: 14),
            _PressableCard(
              onTap: () => _manualPunch(hasCheckin ? 'checkout' : 'checkin'),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: hasCheckin
                        ? [const Color(0xFFEF4444), const Color(0xFFDC2626)]
                        : [const Color(0xFF0F766E), const Color(0xFF0F766E)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color:
                          (hasCheckin
                                  ? const Color(0xFFEF4444)
                                  : const Color(0xFF0F766E))
                              .withValues(alpha: 0.3),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      hasCheckin ? Icons.logout_rounded : Icons.login_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      hasCheckin ? 'Pointer le départ' : 'Pointer l\'arrivée',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFaceCheckinCard(
    BuildContext context,
    Color onSurface,
    Color outline,
    AttendanceRecord? existingRecord,
  ) {
    final hasCheckin =
        existingRecord != null &&
        existingRecord.status == AttendanceStatus.present &&
        existingRecord.checkIn != null;
    final hasCheckout = hasCheckin && existingRecord.checkOut != null;
    final isComplete = hasCheckin && hasCheckout;

    final cardColor = AppColors.brandPurple;

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            cardColor.withValues(alpha: 0.11),
            cardColor.withValues(alpha: 0.045),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: cardColor.withValues(alpha: 0.17)),
        boxShadow: [
          BoxShadow(
            color: cardColor.withValues(alpha: 0.07),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: cardColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.face_rounded, color: cardColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pointage par visage',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: onSurface,
                      ),
                    ),
                    Text(
                      isComplete
                          ? 'Journée complète ✓'
                          : hasCheckin
                          ? 'En attente du départ...'
                          : 'Appuyez pour pointer',
                      style: TextStyle(
                        fontSize: 11,
                        color: isComplete
                            ? AppColors.successGreen
                            : (hasCheckin
                                  ? const Color(0xFFF97316)
                                  : onSurface.withValues(alpha: 0.4)),
                        fontWeight: isComplete
                            ? FontWeight.bold
                            : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Action button
          if (!isComplete) ...[
            const SizedBox(height: 12),
            _PressableCard(
              onTap: () =>
                  _openFaceCheckin(hasCheckin ? 'checkout' : 'checkin'),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: hasCheckin
                        ? [const Color(0xFFEF4444), const Color(0xFFDC2626)]
                        : [const Color(0xFF0F766E), const Color(0xFF0F766E)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color:
                          (hasCheckin
                                  ? const Color(0xFFEF4444)
                                  : const Color(0xFF0F766E))
                              .withValues(alpha: 0.3),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.camera_front_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      hasCheckin ? 'Pointer le départ' : 'Pointer l\'arrivée',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Total: ${_formatHours(existingRecord.hours)}',
                style: const TextStyle(
                  color: Color(0xFF10B981),
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatHours(double hours) {
    final h = hours.floor();
    final m = ((hours - h) * 60).round();
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')} h';
  }
}

class _StatusMiniInfo extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String label;
  final String value;

  const _StatusMiniInfo({
    required this.color,
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
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
          const SizedBox(width: 9),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: value == '--:--'
                        ? onSurface.withValues(alpha: 0.32)
                        : color,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: onSurface.withValues(alpha: 0.45),
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

class _PressableCard extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _PressableCard({required this.child, required this.onTap});

  @override
  State<_PressableCard> createState() => _PressableCardState();
}

class _PressableCardState extends State<_PressableCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _pressed ? 0.98 : 1,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOutCubic,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: widget.onTap,
          onTapDown: (_) {
            HapticFeedback.lightImpact();
            setState(() => _pressed = true);
          },
          onTapCancel: () => setState(() => _pressed = false),
          onTapUp: (_) => setState(() => _pressed = false),
          splashColor: Colors.white.withValues(alpha: 0.10),
          highlightColor: Colors.white.withValues(alpha: 0.06),
          child: widget.child,
        ),
      ),
    );
  }
}

class _CheckinSuccessDialog extends StatelessWidget {
  const _CheckinSuccessDialog();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(28),
        padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
              blurRadius: 30,
              offset: const Offset(0, 15),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                ),
                const Icon(
                  Icons.login_rounded,
                  color: Color(0xFF3B82F6),
                  size: 60,
                ),
              ],
            ),
            const SizedBox(height: 28),
            const Text(
              'Entrée Validée !',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: Color(0xFF111827),
                decoration: TextDecoration.none,
                fontFamily: 'Outfit',
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Votre arrivée a été enregistrée. Revenez en fin de journée pour pointer votre départ.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Color(0xFF6B7280),
                decoration: TextDecoration.none,
                fontWeight: FontWeight.w400,
                fontFamily: 'Outfit',
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SuccessDialog extends StatelessWidget {
  final double hours;

  const _SuccessDialog({required this.hours});

  @override
  Widget build(BuildContext context) {
    final h = hours.floor();
    final m = ((hours - h) * 60).round();
    final timeStr =
        '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')} h';

    return Center(
      child: Container(
        margin: const EdgeInsets.all(28),
        padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: AppColors.brandPurple.withValues(alpha: 0.15),
              blurRadius: 30,
              offset: const Offset(0, 15),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animated-like check icon
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.successGreen.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                ),
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.successGreen.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                ),
                const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.successGreen,
                  size: 70,
                ),
              ],
            ),
            const SizedBox(height: 28),
            const Text(
              'Félicitations !',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: Color(0xFF111827),
                decoration: TextDecoration.none,
                fontFamily: 'Outfit',
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Votre pointage de sortie a été enregistré avec succès.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Color(0xFF6B7280),
                decoration: TextDecoration.none,
                fontWeight: FontWeight.w400,
                fontFamily: 'Outfit',
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.brandPurple.withValues(alpha: 0.08),
                    AppColors.brandPurple.withValues(alpha: 0.03),
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.brandPurple.withValues(alpha: 0.1),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    'TEMPS DE TRAVAIL TOTAL',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.brandPurple.withValues(alpha: 0.6),
                      letterSpacing: 1.2,
                      decoration: TextDecoration.none,
                      fontFamily: 'Outfit',
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.timer_rounded,
                        color: AppColors.brandPurple,
                        size: 24,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        timeStr,
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: AppColors.brandPurple,
                          decoration: TextDecoration.none,
                          fontFamily: 'Outfit',
                          letterSpacing: -1,
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
    );
  }
}

class _TimeBox extends StatelessWidget {
  final String title;
  final String time;
  final VoidCallback onTap;

  const _TimeBox({
    required this.title,
    required this.time,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final outline = Theme.of(context).colorScheme.outline;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: onSurface.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: outline.withValues(alpha: 0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.access_time_filled_rounded,
                  size: 14,
                  color: onSurface.withValues(alpha: 0.3),
                ),
                const SizedBox(width: 8),
                Text(
                  title.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: onSurface.withValues(alpha: 0.4),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              time,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
