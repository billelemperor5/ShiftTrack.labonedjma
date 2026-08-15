import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../../utils/storage_utils.dart';
import '../../../utils/image_helper.dart';
import 'onboarding_components.dart';

class ProfileStep extends StatelessWidget {
  final VoidCallback onFinish;
  final TextEditingController firstNameCtrl;
  final TextEditingController lastNameCtrl;
  final TextEditingController companyCtrl;
  final String? logoPath;
  final Function(String?) onLogoPicked;

  const ProfileStep({
    super.key,
    required this.onFinish,
    required this.firstNameCtrl,
    required this.lastNameCtrl,
    required this.companyCtrl,
    required this.logoPath,
    required this.onLogoPicked,
  });

  Future<void> _pickImage() async {
    HapticFeedback.lightImpact();
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;
    final savedPath = await StorageUtils.saveImage(pickedFile.path);
    onLogoPicked(savedPath);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF111827) : Colors.white;
    final onCard = isDark ? Colors.white : OnboardingPalette.ink;

    return OnboardingBackground(
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 82),
            const OnboardingHeader(
              icon: Icons.person_outline_rounded,
              title: 'Profil & Identité',
              subtitle:
                  'Personnalisez votre espace de travail et vos rapports professionnels.',
            ),
            const SizedBox(height: 22),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: isDark ? 0.08 : 1),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.18),
                        blurRadius: 34,
                        offset: const Offset(0, 18),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: GestureDetector(
                          onTap: _pickImage,
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                width: 104,
                                height: 104,
                                padding: const EdgeInsets.all(5),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: [
                                      OnboardingPalette.teal.withValues(
                                        alpha: 0.25,
                                      ),
                                      OnboardingPalette.blue.withValues(
                                        alpha: 0.12,
                                      ),
                                    ],
                                  ),
                                ),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.05)
                                        : const Color(0xFFF1F5F9),
                                    shape: BoxShape.circle,
                                    image: logoPath != null
                                        ? DecorationImage(
                                            image: ResizeImage(AppImageHelper.getImageProvider(logoPath!), width: 150, height: 150),
                                            fit: BoxFit.cover,
                                          )
                                        : null,
                                  ),
                                  child: logoPath == null
                                      ? Icon(
                                          Icons.add_a_photo_rounded,
                                          size: 34,
                                          color: OnboardingPalette.teal
                                              .withValues(alpha: 0.66),
                                        )
                                      : null,
                                ),
                              ),
                              Positioned(
                                right: 0,
                                bottom: 4,
                                child: Container(
                                  width: 30,
                                  height: 30,
                                  decoration: BoxDecoration(
                                    color: OnboardingPalette.teal,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: cardColor,
                                      width: 3,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.edit_rounded,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 26),
                      _ProfileField(
                        controller: firstNameCtrl,
                        label: 'Prénom',
                        icon: Icons.badge_outlined,
                        onCard: onCard,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 14),
                      _ProfileField(
                        controller: lastNameCtrl,
                        label: 'Nom',
                        icon: Icons.person_outline_rounded,
                        onCard: onCard,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 14),
                      _ProfileField(
                        controller: companyCtrl,
                        label: 'Entreprise',
                        hint: 'Optionnel',
                        icon: Icons.business_outlined,
                        onCard: onCard,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 24),
                      _FinishButton(onTap: onFinish),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData icon;
  final Color onCard;
  final bool isDark;

  const _ProfileField({
    required this.controller,
    required this.label,
    required this.icon,
    required this.onCard,
    required this.isDark,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: onCard.withValues(alpha: 0.58),
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : const Color(0xFFE5E7EB),
            ),
          ),
          child: TextField(
            controller: controller,
            textInputAction: TextInputAction.next,
            style: TextStyle(
              color: onCard,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
            decoration: InputDecoration(
              prefixIcon: Icon(
                icon,
                color: OnboardingPalette.teal.withValues(alpha: 0.70),
                size: 20,
              ),
              hintText: hint == null
                  ? 'Saisir ici...'
                  : 'Saisir ici... ($hint)',
              hintStyle: TextStyle(
                color: onCard.withValues(alpha: 0.32),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 15,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FinishButton extends StatefulWidget {
  final VoidCallback onTap;

  const _FinishButton({required this.onTap});

  @override
  State<_FinishButton> createState() => _FinishButtonState();
}

class _FinishButtonState extends State<_FinishButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _pressed ? 0.975 : 1,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOutCubic,
      child: Container(
        height: 58,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              OnboardingPalette.teal,
              OnboardingPalette.blue,
              OnboardingPalette.violet,
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: OnboardingPalette.blue.withValues(alpha: 0.24),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTapDown: (_) {
              HapticFeedback.lightImpact();
              setState(() => _pressed = true);
            },
            onTapCancel: () => setState(() => _pressed = false),
            onTapUp: (_) => setState(() => _pressed = false),
            onTap: widget.onTap,
            child: const Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Terminer & Commencer',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
