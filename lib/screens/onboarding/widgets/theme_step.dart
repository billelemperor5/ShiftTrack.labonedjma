import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../providers/app_provider.dart';
import 'onboarding_components.dart';

class ThemeStep extends StatefulWidget {
  final VoidCallback onNext;

  const ThemeStep({super.key, required this.onNext});

  @override
  State<ThemeStep> createState() => _ThemeStepState();
}

class _ThemeStepState extends State<ThemeStep> {
  String _selected = 'light';

  void _continue() {
    context.read<AppProvider>().changeTheme(_selected);
    widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingBackground(
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 82),
            const OnboardingHeader(
              icon: Icons.palette_rounded,
              title: 'Choisissez votre thème',
              subtitle:
                  'Sélectionnez l’ambiance visuelle idéale. Vous pourrez la modifier depuis les paramètres.',
            ),
            const SizedBox(height: 34),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    _ThemeOption(
                      label: 'Clair',
                      subtitle: 'Interface lumineuse et moderne',
                      icon: Icons.light_mode_rounded,
                      previewColors: const [
                        Color(0xFFFFF7E6),
                        Color(0xFFFFB020),
                      ],
                      isSelected: _selected == 'light',
                      onTap: () => setState(() => _selected = 'light'),
                    ),
                    const SizedBox(height: 14),
                    _ThemeOption(
                      label: 'Sombre',
                      subtitle: 'Confort visuel pour la nuit',
                      icon: Icons.dark_mode_rounded,
                      previewColors: const [
                        Color(0xFF111827),
                        Color(0xFF0F766E),
                      ],
                      isSelected: _selected == 'dark',
                      onTap: () => setState(() => _selected = 'dark'),
                    ),
                    const SizedBox(height: 14),
                    _ThemeOption(
                      label: 'Système',
                      subtitle: 'Suit automatiquement votre téléphone',
                      icon: Icons.computer_rounded,
                      previewColors: const [
                        Color(0xFF2563EB),
                        Color(0xFF7C3AED),
                      ],
                      isSelected: _selected == 'system',
                      onTap: () => setState(() => _selected = 'system'),
                    ),
                  ],
                ),
              ),
            ),
            OnboardingFooter(
              child: OnboardingPrimaryButton(
                label: 'Continuer',
                icon: Icons.arrow_forward_rounded,
                onTap: _continue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  final List<Color> previewColors;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.previewColors,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: isSelected ? 1.01 : 1,
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOutCubic,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          borderRadius: BorderRadius.circular(24),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: isSelected ? 0.20 : 0.10),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withValues(alpha: isSelected ? 0.54 : 0.12),
                width: isSelected ? 1.6 : 1,
              ),
              boxShadow: [
                if (isSelected)
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 22,
                    offset: const Offset(0, 12),
                  ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(colors: previewColors),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.26),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    icon,
                    size: 24,
                    color: previewColors.first.computeLuminance() > 0.45
                        ? OnboardingPalette.teal
                        : Colors.white,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.58),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isSelected ? Icons.check_rounded : Icons.circle_outlined,
                    size: isSelected ? 18 : 14,
                    color: isSelected
                        ? OnboardingPalette.teal
                        : Colors.white.withValues(alpha: 0.36),
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
