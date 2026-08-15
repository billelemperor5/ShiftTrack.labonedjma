import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/user_profile.dart';
import '../../providers/app_provider.dart';
import 'widgets/welcome_step.dart';
import 'widgets/theme_step.dart';
import 'widgets/profile_step.dart';
import 'widgets/work_settings_step.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  static const _totalSteps = 4;

  // Form Data
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _companyController = TextEditingController();
  String? _logoPath;
  String _defaultCheckIn = "08:00";
  String _defaultCheckOut = "17:00";
  bool _faceCheckinEnabled = false;

  void _nextStep() {
    if (_currentIndex < _totalSteps - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _finishOnboarding();
    }
  }

  Future<void> _finishOnboarding() async {
    if (_firstNameController.text.isEmpty || _lastNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez saisir votre nom'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final appProvider = context.read<AppProvider>();
    final profile = UserProfile(
      firstName: _firstNameController.text,
      lastName: _lastNameController.text,
      companyName: _companyController.text,
      logoPath: _logoPath,
      locale: 'fr',
      isFirstLaunchDone: true,
      workDays: const [1, 2, 3, 4, 5],
      defaultCheckIn: _defaultCheckIn,
      defaultCheckOut: _defaultCheckOut,
      faceCheckinEnabled: _faceCheckinEnabled,
      themeMode: appProvider.currentTheme,
    );

    await appProvider.saveProfile(profile);
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        body: Stack(
          children: [
            // Pages
            PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (index) => setState(() => _currentIndex = index),
              children: [
                WelcomeStep(onNext: _nextStep),
                ThemeStep(onNext: _nextStep),
                WorkSettingsStep(
                  onNext: _nextStep,
                  initialCheckIn: _defaultCheckIn,
                  initialCheckOut: _defaultCheckOut,
                  initialFaceCheckin: _faceCheckinEnabled,
                  onUpdate: (iin, out, face) {
                    setState(() {
                      _defaultCheckIn = iin;
                      _defaultCheckOut = out;
                      _faceCheckinEnabled = face;
                    });
                  },
                ),
                ProfileStep(
                  onFinish: _finishOnboarding,
                  firstNameCtrl: _firstNameController,
                  lastNameCtrl: _lastNameController,
                  companyCtrl: _companyController,
                  logoPath: _logoPath,
                  onLogoPicked: (path) => setState(() => _logoPath = path),
                ),
              ],
            ),

            // Progress dots (top)
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _totalSteps,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentIndex == index ? 28 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentIndex == index
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
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
