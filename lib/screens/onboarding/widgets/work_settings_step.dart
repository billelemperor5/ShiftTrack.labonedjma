import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'onboarding_components.dart';

class WorkSettingsStep extends StatefulWidget {
  final VoidCallback onNext;
  final String initialCheckIn;
  final String initialCheckOut;
  final bool initialFaceCheckin;
  final Function(String, String, bool) onUpdate;

  const WorkSettingsStep({
    super.key,
    required this.onNext,
    required this.initialCheckIn,
    required this.initialCheckOut,
    required this.initialFaceCheckin,
    required this.onUpdate,
  });

  @override
  State<WorkSettingsStep> createState() => _WorkSettingsStepState();
}

class _WorkSettingsStepState extends State<WorkSettingsStep> {
  late String _checkIn;
  late String _checkOut;
  late bool _faceCheckin;

  @override
  void initState() {
    super.initState();
    _checkIn = widget.initialCheckIn;
    _checkOut = widget.initialCheckOut;
    _faceCheckin = widget.initialFaceCheckin;
  }

  Future<void> _selectTime(BuildContext context, bool isCheckIn) async {
    final current = (isCheckIn ? _checkIn : _checkOut).split(':');
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: int.parse(current[0]),
        minute: int.parse(current[1]),
      ),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: OnboardingPalette.teal,
              secondary: OnboardingPalette.blue,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked == null) return;
    final formatted =
        '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    setState(() {
      if (isCheckIn) {
        _checkIn = formatted;
      } else {
        _checkOut = formatted;
      }
    });
    widget.onUpdate(_checkIn, _checkOut, _faceCheckin);
  }

  void _toggleFace(bool value) {
    HapticFeedback.selectionClick();
    setState(() => _faceCheckin = value);
    widget.onUpdate(_checkIn, _checkOut, _faceCheckin);
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingBackground(
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 82),
            const OnboardingHeader(
              icon: Icons.settings_suggest_rounded,
              title: 'Configuration de travail',
              subtitle:
                  'Définissez vos horaires par défaut et préparez votre pointage quotidien.',
            ),
            const SizedBox(height: 30),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _TimeCard(
                            title: 'Arrivée',
                            time: _checkIn,
                            icon: Icons.login_rounded,
                            color: const Color(0xFF10B981),
                            onTap: () => _selectTime(context, true),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _TimeCard(
                            title: 'Départ',
                            time: _checkOut,
                            icon: Icons.logout_rounded,
                            color: const Color(0xFFF87171),
                            onTap: () => _selectTime(context, false),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    OnboardingGlassCard(
                      child: Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: const Icon(
                              Icons.face_unlock_rounded,
                              color: Colors.white,
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Pointage par visage',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  'Activez la caméra pour pointer plus vite',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.56),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: _faceCheckin,
                            onChanged: _toggleFace,
                            activeThumbColor: Colors.white,
                            activeTrackColor: Colors.white.withValues(
                              alpha: 0.30,
                            ),
                            inactiveThumbColor: Colors.white,
                            inactiveTrackColor: Colors.white.withValues(
                              alpha: 0.18,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    OnboardingGlassCard(
                      padding: const EdgeInsets.all(15),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.notifications_active_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Ces horaires seront utilisés pour les rappels automatiques de pointage.',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.66),
                                fontSize: 12,
                                height: 1.4,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            OnboardingFooter(
              child: OnboardingPrimaryButton(
                label: 'Continuer',
                icon: Icons.arrow_forward_rounded,
                onTap: widget.onNext,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimeCard extends StatefulWidget {
  final String title;
  final String time;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _TimeCard({
    required this.title,
    required this.time,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  State<_TimeCard> createState() => _TimeCardState();
}

class _TimeCardState extends State<_TimeCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _pressed ? 0.97 : 1,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOutCubic,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          onTapDown: (_) {
            HapticFeedback.lightImpact();
            setState(() => _pressed = true);
          },
          onTapCancel: () => setState(() => _pressed = false),
          onTapUp: (_) => setState(() => _pressed = false),
          borderRadius: BorderRadius.circular(24),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
              boxShadow: [
                BoxShadow(
                  color: widget.color.withValues(alpha: 0.12),
                  blurRadius: 24,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: widget.color.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(widget.icon, color: Colors.white, size: 22),
                ),
                const SizedBox(height: 24),
                Text(
                  widget.time,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 27,
                    height: 1,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.title,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.58),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
