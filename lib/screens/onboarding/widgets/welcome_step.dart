import 'package:flutter/material.dart';

import 'onboarding_components.dart';

class WelcomeStep extends StatelessWidget {
  final VoidCallback onNext;

  const WelcomeStep({super.key, required this.onNext});

  @override
  Widget build(BuildContext context) {
    return OnboardingBackground(
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 78),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 26),
                child: Column(
                  children: [
                    const Spacer(),
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: const Duration(milliseconds: 700),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, child) => Opacity(
                        opacity: value,
                        child: Transform.scale(
                          scale: 0.92 + (value * 0.08),
                          child: child,
                        ),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 172,
                            height: 172,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.08),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.11),
                              ),
                            ),
                          ),
                          Container(
                            width: 124,
                            height: 124,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.white.withValues(alpha: 0.30),
                                  Colors.white.withValues(alpha: 0.10),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.16),
                                  blurRadius: 34,
                                  offset: const Offset(0, 18),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.track_changes_rounded,
                              color: Colors.white,
                              size: 54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 34),
                    const Text(
                      'ShiftTrack',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 42,
                        fontWeight: FontWeight.w900,
                        height: 1,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Gérez votre temps de travail avec précision, présence intelligente et rapports professionnels.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.68),
                        fontSize: 15,
                        height: 1.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 26),
                    const OnboardingGlassCard(
                      padding: EdgeInsets.all(14),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: OnboardingMetricChip(
                                  icon: Icons.schedule_rounded,
                                  label: 'Horaires',
                                  value: '08:00',
                                  color: OnboardingPalette.violet,
                                ),
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: OnboardingMetricChip(
                                  icon: Icons.verified_rounded,
                                  label: 'Présence',
                                  value: 'Live',
                                  color: OnboardingPalette.teal,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: OnboardingMetricChip(
                                  icon: Icons.picture_as_pdf_rounded,
                                  label: 'Rapports',
                                  value: 'PDF',
                                  color: OnboardingPalette.orange,
                                ),
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: OnboardingMetricChip(
                                  icon: Icons.notifications_active_rounded,
                                  label: 'Rappels',
                                  value: 'Auto',
                                  color: OnboardingPalette.blue,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                  ],
                ),
              ),
            ),
            OnboardingFooter(
              child: Column(
                children: [
                  OnboardingPrimaryButton(
                    label: 'Commencer l\'aventure',
                    icon: Icons.arrow_forward_rounded,
                    onTap: onNext,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Configuration rapide en moins d’une minute',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.46),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
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
