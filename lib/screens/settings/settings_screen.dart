import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_design.dart';
import '../../models/user_profile.dart';
import '../../providers/app_provider.dart';
import '../../providers/attendance_provider.dart';
import '../../services/notification_service.dart';
import '../../utils/storage_utils.dart';
import '../../utils/image_helper.dart';
import '../auth/biotime_login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const List<int> _saturdayToThursday = [6, 7, 1, 2, 3, 4];

  late final TextEditingController _companyCtrl;
  late final TextEditingController _nameCtrl;
  late final TextEditingController _lastNameCtrl;

  String? _logoPath;
  String _defaultIn = '08:00';
  String _defaultOut = '17:00';
  int _breakDuration = 30;
  bool _isBreakPaid = false;
  bool _faceCheckinEnabled = false;
  bool _notificationsEnabled = false;
  List<int> _notificationWorkDays = _saturdayToThursday;
  String _selectedTheme = 'light';
  int _selectedTab = 0;
  bool _saving = false;
  bool _saved = false;

  final ValueNotifier<double> _progressNotifier = ValueNotifier(0.0);

  @override
  void initState() {
    super.initState();
    final profile = context.read<AppProvider>().userProfile;
    final attendance = context.read<AttendanceProvider>();
    final emp = attendance.currentEmployee;

    String initialFirst = profile?.firstName ?? '';
    String initialLast = profile?.lastName ?? '';
    String initialCompany = profile?.companyName ?? '';

    if (emp != null) {
      if (emp.firstName.isNotEmpty && (initialFirst.isEmpty || initialFirst.startsWith('Employé') || initialFirst == 'Utilisateur')) {
        initialFirst = emp.firstName;
      }
      if (emp.lastName.isNotEmpty && (initialLast.isEmpty || initialLast == 'Non renseigné')) {
        initialLast = emp.lastName;
      }
      if (emp.department.isNotEmpty && (initialCompany.isEmpty || initialCompany == 'Direction' || initialCompany == 'IT' || initialCompany == 'ShiftTrack' || initialCompany == 'Organisation')) {
        initialCompany = emp.department;
      }
    }

    _companyCtrl = TextEditingController(text: initialCompany);
    _nameCtrl = TextEditingController(text: initialFirst);
    _lastNameCtrl = TextEditingController(text: initialLast);
    _logoPath = profile?.logoPath;
    _defaultIn = profile?.defaultCheckIn ?? '08:00';
    _defaultOut = profile?.defaultCheckOut ?? '17:00';
    _breakDuration = profile?.breakDuration ?? 30;
    _isBreakPaid = profile?.isBreakPaid ?? false;
    _faceCheckinEnabled = profile?.faceCheckinEnabled ?? false;
    _notificationsEnabled = profile?.notificationsEnabled ?? false;
    _notificationWorkDays = List<int>.from(
      profile?.notificationWorkDays ?? _saturdayToThursday,
    );
    _selectedTheme = profile?.themeMode ?? 'light';
  }

  @override
  void dispose() {
    _companyCtrl.dispose();
    _nameCtrl.dispose();
    _lastNameCtrl.dispose();
    _progressNotifier.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile == null) return;
    final savedPath = await StorageUtils.saveImage(pickedFile.path);
    if (mounted) setState(() => _logoPath = savedPath);
  }

  void _confirmLogout() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.logout_rounded, color: Color(0xFFEF4444), size: 24),
            ),
            const SizedBox(width: 14),
            const Text(
              'Déconnexion',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
            ),
          ],
        ),
        content: const Text(
          'Voulez-vous vraiment vous déconnecter ? Vous devrez saisir votre matricule pour vous reconnecter.',
          style: TextStyle(fontSize: 14.5, height: 1.45),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Annuler',
              style: TextStyle(
                color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await context.read<AppProvider>().logout();
              if (!mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const BioTimeLoginScreen()),
                (route) => false,
              );
            },
            icon: const Icon(Icons.logout_rounded, size: 18, color: Colors.white),
            label: const Text('Déconnexion', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }





  Future<void> _save(UserProfile oldProfile) async {
    if (_saving) return;
    if (_nameCtrl.text.trim().isEmpty || _lastNameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez renseigner le prénom et le nom'),
        ),
      );
      return;
    }

    HapticFeedback.lightImpact();
    setState(() {
      _saving = true;
      _saved = false;
    });

    final updated = UserProfile(
      firstName: _nameCtrl.text.trim(),
      lastName: _lastNameCtrl.text.trim(),
      companyName: _companyCtrl.text.trim(),
      logoPath: _logoPath,
      locale: oldProfile.locale,
      isFirstLaunchDone: true,
      workDays: oldProfile.workDays,
      defaultCheckIn: _defaultIn,
      defaultCheckOut: _defaultOut,
      themeMode: _selectedTheme,
      breakDuration: _breakDuration,
      isBreakPaid: _isBreakPaid,
      faceCheckinEnabled: _faceCheckinEnabled,
      notificationsEnabled: _notificationsEnabled,
      notificationWorkDays: _notificationWorkDays,
    );

    await context.read<AppProvider>().saveProfile(updated);
    await NotificationService.configure(updated);
    if (!mounted) return;

    setState(() {
      _saving = false;
      _saved = true;
    });
    await Future.delayed(const Duration(milliseconds: 650));
    if (mounted) Navigator.pop(context);
  }



  void _showInfo() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Info',
      barrierColor: Colors.black.withValues(alpha: 0.65),
      transitionDuration: const Duration(milliseconds: 320),
      pageBuilder: (ctx, anim1, anim2) => const _DeveloperAboutDialog(),
      transitionBuilder: (ctx, anim1, anim2, child) {
        return FadeTransition(
          opacity: anim1,
          child: ScaleTransition(
            scale: CurvedAnimation(parent: anim1, curve: Curves.easeOutCubic),
            child: child,
          ),
        );
      },
    );
  }

  Future<void> _showEditFieldSheet({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required Color color,
    bool requiredField = false,
  }) async {
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _EditFieldSheet(
        label: label,
        initialValue: controller.text.trim(),
        icon: icon,
        color: color,
        requiredField: requiredField,
      ),
    );

    if (result == null) return;
    setState(() => controller.text = result.trim());
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<AppProvider>().userProfile ??
        UserProfile(
          firstName: 'BILLEL',
          lastName: '',
          companyName: 'IT',
          defaultCheckIn: '08:00',
          defaultCheckOut: '17:00',
        );
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width > 850;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Container(
          decoration: AppDesign.pageBackground(isDark),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                0,
                0,
                0,
                MediaQuery.of(context).padding.bottom + 32,
              ),
              child: Column(
                children: [
                  _buildHeader(profile, isDark),
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1000),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _SettingsTabs(
                              selected: _selectedTab,
                              onSelected: (value) =>
                                  setState(() => _selectedTab = value),
                            ),
                            const SizedBox(height: 18),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 260),
                              switchInCurve: Curves.easeOutCubic,
                              switchOutCurve: Curves.easeOutCubic,
                              child: KeyedSubtree(
                                key: ValueKey(_selectedTab),
                                child: _tabContent(isDark, onSurface),
                              ),
                            ),
                            const SizedBox(height: 24),
                            isDesktop
                                ? Center(
                                    child: SizedBox(
                                      width: 320,
                                      child: _PremiumSaveButton(
                                        saving: _saving,
                                        saved: _saved,
                                        onTap: () => _save(profile),
                                      ),
                                    ),
                                  )
                                : _PremiumSaveButton(
                                    saving: _saving,
                                    saved: _saved,
                                    onTap: () => _save(profile),
                                  ),
                          ],
                        ),
                      ),
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

  Widget _buildHeader(UserProfile profile, bool isDark) {
    final topPad = MediaQuery.of(context).padding.top;
    final attendance = context.watch<AttendanceProvider>();
    final emp = attendance.currentEmployee;

    // Always prefer live employee data for display
    final effectiveFirst = (emp?.firstName.isNotEmpty == true)
        ? emp!.firstName
        : (_nameCtrl.text.isNotEmpty && !_nameCtrl.text.startsWith('Employé') ? _nameCtrl.text.trim() : '');
    final effectiveLast = (emp?.lastName.isNotEmpty == true)
        ? emp!.lastName
        : (_lastNameCtrl.text.trim().isNotEmpty ? _lastNameCtrl.text.trim() : '');
    final effectiveCompany = (emp?.department.isNotEmpty == true)
        ? emp!.department
        : (_companyCtrl.text.trim().isNotEmpty ? _companyCtrl.text.trim() : '');

    final fullName = '$effectiveFirst $effectiveLast'.trim();
    final displayName = fullName.isEmpty ? (emp?.fullName.isNotEmpty == true ? emp!.fullName : 'Utilisateur') : fullName;
    final company = effectiveCompany.isEmpty ? 'Organisation' : effectiveCompany;
    final hasLogo = AppImageHelper.exists(_logoPath);

    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subColor = isDark ? Colors.white.withValues(alpha: 0.72) : const Color(0xFF475569);

    final width = MediaQuery.of(context).size.width;
    final isDesktop = width > 850;

    if (isDesktop) {
      final gradientColors = isDark 
          ? const [Color(0xFF0D1E1B), Color(0xFF091412)]
          : const [Color(0xFF0D9488), Color(0xFF0F766E)];
      final borderSideColor = isDark ? Colors.white10 : const Color(0xFF0F766E).withValues(alpha: 0.15);
      return Container(
        height: 80,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: gradientColors),
          border: Border(bottom: BorderSide(color: borderSideColor)),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
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
                        Icons.settings_suggest_rounded,
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
                          'Paramètres du système',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          'Profil, préférences et options de travail',
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
                Row(
                  children: [
                    _GlassRoundButton(
                      icon: Icons.info_outline_rounded,
                      iconColor: Colors.white,
                      color: Colors.white.withValues(alpha: 0.15),
                      onTap: _showInfo,
                    ),
                    const SizedBox(width: 14),
                    ElevatedButton.icon(
                      onPressed: _saving ? null : () => _save(profile),
                      icon: _saving
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0F766E)),
                            )
                          : Icon(_saved ? Icons.check_rounded : Icons.save_rounded, size: 16),
                      label: Text(
                        _saved ? 'Enregistré !' : (_saving ? 'Sauvegarde...' : 'Enregistrer'),
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF0F766E),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        elevation: 0,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(16, topPad + 12, 16, 0),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 520),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) => Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 16),
            child: child,
          ),
        ),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: AppDesign.heroGradient(isDark),
            ),
            borderRadius: BorderRadius.circular(32),
            border: isDark
                ? null
                : const Border(
                    bottom: BorderSide(color: Color(0xFFE2E8F0)),
                  ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.3)
                    : Colors.black.withValues(alpha: 0.05),
                blurRadius: 30,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              if (isDark) ...[
                Positioned(
                  right: -48,
                  top: -52,
                  child: _HeaderOrb(size: 150, opacity: 0.13),
                ),
                Positioned(
                  left: -42,
                  bottom: -48,
                  child: _HeaderOrb(size: 120, opacity: 0.08),
                ),
              ],
              Column(
                children: [
                  Row(
                    children: [
                      if (Navigator.canPop(context)) ...[
                        _GlassRoundButton(
                          icon: Icons.arrow_back_rounded,
                          onTap: () => Navigator.pop(context),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        child: Text(
                          'Paramètres',
                          style: TextStyle(
                            color: textColor,
                            fontSize: 21,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      _GlassRoundButton(
                        icon: Icons.info_outline_rounded,
                        onTap: _showInfo,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          InkWell(
                            onTap: _pickImage,
                            borderRadius: BorderRadius.circular(999),
                            child: Container(
                              width: 88,
                              height: 88,
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.18)
                                    : const Color(0xFFF1F5F9),
                                border: Border.all(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.30)
                                      : const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: CircleAvatar(
                                backgroundColor: isDark
                                    ? const Color(0xFF1E3A8A)
                                    : const Color(0xFF2563EB),
                                backgroundImage: hasLogo
                                    ? ResizeImage(AppImageHelper.getImageProvider(_logoPath!), width: 150, height: 150)
                                    : (emp?.photoUrl != null && emp!.photoUrl!.isNotEmpty
                                        ? NetworkImage(emp.photoUrl!)
                                        : AppImageHelper.officialLogoProvider),
                              ),
                            ),
                          ),
                          Positioned(
                            right: 0,
                            bottom: 5,
                            child: Container(
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                color: const Color(0xFF22C55E),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isDark ? Colors.black : Colors.white,
                                  width: 3,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: textColor,
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                height: 1,
                              ),
                            ),
                            const SizedBox(height: 7),
                            Text(
                              company,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: subColor,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _HeaderBadge(
                                  icon: Icons.verified_rounded,
                                  label: 'Compte actif',
                                ),
                                _LogoutHeaderButton(onTap: _confirmLogout),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tabContent(bool isDark, Color onSurface) {
    switch (_selectedTab) {
      case 1:
        return _preferencesTab(isDark, onSurface);
      case 0:
      default:
        return _accountTab(isDark, onSurface);
    }
  }

  Widget _accountTab(bool isDark, Color onSurface) {
    final attendance = context.watch<AttendanceProvider>();
    final emp = attendance.currentEmployee;
    if (emp != null) {
      // Always prefer live employee data over stale Hive profile
      if (emp.firstName.isNotEmpty && (_nameCtrl.text.isEmpty || _nameCtrl.text.startsWith('Employé') || _nameCtrl.text == 'Utilisateur')) {
        _nameCtrl.text = emp.firstName;
      }
      if (emp.lastName.isNotEmpty && (_lastNameCtrl.text.isEmpty || _lastNameCtrl.text == 'Non renseigné')) {
        _lastNameCtrl.text = emp.lastName;
      }
      if (emp.department.isNotEmpty && (_companyCtrl.text.isEmpty || _companyCtrl.text == 'Direction' || _companyCtrl.text == 'IT' || _companyCtrl.text == 'ShiftTrack' || _companyCtrl.text == 'Organisation')) {
        _companyCtrl.text = emp.department;
      }
    }

    return _SlideFadeGroup(
      children: [
        _SectionHeader(
          icon: Icons.person_rounded,
          title: 'Informations personnelles',
        ),
        const SizedBox(height: 12),
        _PremiumPanel(
          isDark: isDark,
          child: Column(
            children: [
              _EditableSettingTile(
                controller: _nameCtrl,
                icon: Icons.person_rounded,
                label: 'Prénom',
                color: const Color(0xFF0F766E),
                onTap: () => _showEditFieldSheet(
                  label: 'Prénom',
                  controller: _nameCtrl,
                  icon: Icons.person_rounded,
                  color: const Color(0xFF0F766E),
                  requiredField: true,
                ),
              ),
              _PanelDivider(onSurface: onSurface),
              _EditableSettingTile(
                controller: _lastNameCtrl,
                icon: Icons.badge_rounded,
                label: 'Nom',
                color: const Color(0xFF2563EB),
                onTap: () => _showEditFieldSheet(
                  label: 'Nom',
                  controller: _lastNameCtrl,
                  icon: Icons.badge_rounded,
                  color: const Color(0xFF2563EB),
                  requiredField: true,
                ),
              ),
              _PanelDivider(onSurface: onSurface),
              _EditableSettingTile(
                controller: _companyCtrl,
                icon: Icons.business_rounded,
                label: 'Département',
                color: const Color(0xFF7C3AED),
                onTap: () => _showEditFieldSheet(
                  label: 'Département',
                  controller: _companyCtrl,
                  icon: Icons.business_rounded,
                  color: const Color(0xFF7C3AED),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _preferencesTab(bool isDark, Color onSurface) {
    return _SlideFadeGroup(
      children: [
        _SectionHeader(icon: Icons.palette_rounded, title: 'Thème'),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _ThemeChoiceCard(
                mode: 'light',
                selected: _selectedTheme == 'light',
                title: 'Clair',
                icon: Icons.light_mode_rounded,
                colors: const [Color(0xFFFFFBEB), Color(0xFFF59E0B)],
                onTap: () => setState(() => _selectedTheme = 'light'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ThemeChoiceCard(
                mode: 'dark',
                selected: _selectedTheme == 'dark',
                title: 'Sombre',
                icon: Icons.dark_mode_rounded,
                colors: const [Color(0xFF111827), Color(0xFF0F766E)],
                onTap: () => setState(() => _selectedTheme = 'dark'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ThemeChoiceCard(
                mode: 'system',
                selected: _selectedTheme == 'system',
                title: 'Système',
                icon: Icons.computer_rounded,
                colors: const [Color(0xFF2563EB), Color(0xFF7C3AED)],
                onTap: () => setState(() => _selectedTheme = 'system'),
              ),
            ),
          ],
        ),
      ],
    );
  }

}

class _SettingsTabs extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onSelected;

  const _SettingsTabs({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final tabs = [
      (Icons.person_rounded, 'Compte'),
      (Icons.tune_rounded, 'Préférences'),
    ];
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.10),
        ),
      ),
      child: Row(
        children: List.generate(tabs.length, (index) {
          final isSelected = selected == index;
          return Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => onSelected(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? const LinearGradient(
                          colors: [Color(0xFF0F766E), Color(0xFF2563EB)],
                        )
                      : null,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: const Color(
                              0xFF2563EB,
                            ).withValues(alpha: 0.20),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      tabs[index].$1,
                      size: 17,
                      color: isSelected
                          ? Colors.white
                          : Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.58),
                    ),
                    const SizedBox(height: 3),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        tabs[index].$2,
                        maxLines: 1,
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.58),
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _SlideFadeGroup extends StatelessWidget {
  final List<Widget> children;

  const _SlideFadeGroup({required this.children});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 340),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, (1 - value) * 12),
          child: child,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

class _PremiumPanel extends StatelessWidget {
  final bool isDark;
  final Widget child;

  const _PremiumPanel({required this.isDark, required this.child});

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? const Color(0xFF111827) : Colors.white;
    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: surface.withValues(alpha: isDark ? 0.76 : 0.92),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.white.withValues(alpha: 0.76),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.07),
                blurRadius: 28,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SectionHeader({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Row(
      children: [
        _SoftIcon(icon: icon, color: const Color(0xFF0F766E), size: 34),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            color: onSurface,
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _EditableSettingTile extends StatelessWidget {
  final TextEditingController controller;
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _EditableSettingTile({
    required this.controller,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final value = controller.text.trim().isEmpty
        ? 'Non renseigné'
        : controller.text.trim();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              _SoftIcon(icon: icon, color: color),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: onSurface.withValues(alpha: 0.48),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: controller.text.trim().isEmpty
                            ? onSurface.withValues(alpha: 0.42)
                            : onSurface,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: onSurface.withValues(alpha: 0.22),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EditFieldSheet extends StatefulWidget {
  final String label;
  final String initialValue;
  final IconData icon;
  final Color color;
  final bool requiredField;

  const _EditFieldSheet({
    required this.label,
    required this.initialValue,
    required this.icon,
    required this.color,
    required this.requiredField,
  });

  @override
  State<_EditFieldSheet> createState() => _EditFieldSheetState();
}

class _EditFieldSheetState extends State<_EditFieldSheet> {
  late final TextEditingController _controller;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _validateAndClose() {
    final value = _controller.text.trim();
    if (widget.requiredField && value.isEmpty) {
      HapticFeedback.mediumImpact();
      setState(() => _error = 'Ce champ est obligatoire');
      return;
    }
    HapticFeedback.lightImpact();
    Navigator.pop(context, value);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        top: false,
        child: Container(
          margin: const EdgeInsets.all(8),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 22),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF17232D) : Colors.white,
            borderRadius: BorderRadius.circular(34),
            border: Border.all(color: widget.color.withValues(alpha: 0.12)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.34 : 0.16),
                blurRadius: 36,
                offset: const Offset(0, -10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
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
                  _SoftIcon(icon: widget.icon, color: widget.color, size: 50),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Modifier ${widget.label}',
                          style: TextStyle(
                            color: onSurface,
                            fontSize: 21,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Cette valeur sera utilisée dans le profil.',
                          style: TextStyle(
                            color: onSurface.withValues(alpha: 0.48),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _controller,
                textCapitalization: TextCapitalization.words,
                onSubmitted: (_) => _validateAndClose(),
                style: TextStyle(
                  color: onSurface,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
                decoration: InputDecoration(
                  labelText: widget.label,
                  errorText: _error,
                  prefixIcon: Icon(widget.icon, color: widget.color),
                  filled: true,
                  fillColor: isDark
                      ? Colors.white.withValues(alpha: 0.055)
                      : const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(
                      color: onSurface.withValues(alpha: 0.08),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(
                      color: onSurface.withValues(alpha: 0.08),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(color: widget.color, width: 1.4),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(54),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: const Text(
                        'Annuler',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _validateAndClose,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(54),
                        backgroundColor: widget.color,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: const Text(
                        'Valider',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThemeChoiceCard extends StatelessWidget {
  final String mode;
  final bool selected;
  final String title;
  final IconData icon;
  final List<Color> colors;
  final VoidCallback onTap;

  const _ThemeChoiceCard({
    required this.mode,
    required this.selected,
    required this.title,
    required this.icon,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: selected
                ? const Color(0xFF0F766E)
                : Theme.of(context).colorScheme.outline.withValues(alpha: 0.10),
            width: selected ? 1.6 : 1,
          ),
          boxShadow: [
            if (selected)
              BoxShadow(
                color: const Color(0xFF0F766E).withValues(alpha: 0.16),
                blurRadius: 18,
                offset: const Offset(0, 9),
              ),
          ],
        ),
        child: Column(
          children: [
            Container(
              height: 58,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: colors),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Stack(
                children: [
                  Center(child: Icon(icon, color: Colors.white, size: 28)),
                  if (selected)
                    const Positioned(
                      right: 8,
                      top: 8,
                      child: Icon(
                        Icons.check_circle_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              maxLines: 1,
              style: TextStyle(
                color: selected ? const Color(0xFF0F766E) : onSurface,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class _PremiumSaveButton extends StatelessWidget {
  final bool saving;
  final bool saved;
  final VoidCallback onTap;

  const _PremiumSaveButton({
    required this.saving,
    required this.saved,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      height: 58,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: saved
              ? const [Color(0xFF10B981), Color(0xFF22C55E)]
              : const [Color(0xFF0F766E), Color(0xFF2563EB), Color(0xFF7C3AED)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withValues(alpha: 0.26),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: saving ? null : onTap,
          borderRadius: BorderRadius.circular(20),
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: saving
                  ? const SizedBox(
                      key: ValueKey('loading'),
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.6,
                        color: Colors.white,
                      ),
                    )
                  : Row(
                      key: ValueKey(saved ? 'saved' : 'save'),
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          saved
                              ? Icons.check_circle_rounded
                              : Icons.save_rounded,
                          color: Colors.white,
                          size: 21,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          saved ? 'Enregistré' : 'Enregistrer',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
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

class _SoftIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;

  const _SoftIcon({required this.icon, required this.color, this.size = 38});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(size * 0.34),
      ),
      child: Icon(icon, color: color, size: size * 0.52),
    );
  }
}

class _PanelDivider extends StatelessWidget {
  final Color onSurface;

  const _PanelDivider({required this.onSurface});

  @override
  Widget build(BuildContext context) {
    return Divider(height: 1, color: onSurface.withValues(alpha: 0.07));
  }
}

class _GlassRoundButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;
  final Color? iconColor;

  const _GlassRoundButton({
    required this.icon,
    required this.onTap,
    this.color,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveIconColor = iconColor ?? (isDark ? Colors.white : const Color(0xFF0F172A));
    final effectiveBgColor = color ??
        (isDark
            ? Colors.white.withValues(alpha: 0.15)
            : const Color(0xFF0F172A).withValues(alpha: 0.08));
    final effectiveBorder = Border.all(
      color: isDark
          ? Colors.white.withValues(alpha: 0.16)
          : const Color(0xFF0F172A).withValues(alpha: 0.12),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Material(
          color: effectiveBgColor,
          child: InkWell(
            onTap: onTap,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: effectiveBorder,
              ),
              child: Icon(
                icon,
                color: effectiveIconColor,
                size: 21,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderBadge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _HeaderBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.14)
            : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.14)
              : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
            size: 14,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF0F172A),
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}



class _LogoutHeaderButton extends StatelessWidget {
  final VoidCallback onTap;

  const _LogoutHeaderButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444).withValues(alpha: isDark ? 0.22 : 0.12),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: const Color(0xFFEF4444).withValues(alpha: isDark ? 0.40 : 0.25),
          ),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.logout_rounded,
              color: Color(0xFFEF4444),
              size: 14,
            ),
            SizedBox(width: 6),
            Text(
              'Déconnexion',
              style: TextStyle(
                color: Color(0xFFEF4444),
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}



class _HeaderOrb extends StatelessWidget {
  final double size;
  final double opacity;

  const _HeaderOrb({required this.size, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: opacity),
      ),
    );
  }
}

class _DeveloperAboutDialog extends StatelessWidget {
  const _DeveloperAboutDialog();

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.28),
              blurRadius: 30,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text(
                    'À propos',
                    style: TextStyle(
                      color: onSurface,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Container(
                width: 104,
                height: 104,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF0F766E).withValues(alpha: 0.25),
                    width: 4,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.asset(
                  'assets/images/developer_logo.jpg',
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const Icon(
                    Icons.person_rounded,
                    color: Color(0xFF0F766E),
                    size: 54,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Billel BOURABA',
                style: TextStyle(
                  color: onSurface,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Text(
                'Entrepreneur Technologique',
                style: TextStyle(
                  color: Color(0xFF0F766E),
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Entrepreneur technologique et développeur systèmes & applications expert.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: onSurface.withValues(alpha: 0.58),
                  height: 1.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 22),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _SocialButton(
                    label: 'Facebook',
                    icon: Icons.facebook_rounded,
                    color: const Color(0xFF1877F2),
                    url: 'https://www.facebook.com/billel.bouraba',
                  ),
                  const SizedBox(width: 12),
                  _SocialButton(
                    label: 'Email',
                    icon: Icons.email_rounded,
                    color: const Color(0xFFEA4335),
                    url: 'mailto:billel.dadi123@gmail.com',
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'ShiftTrack v3.0.0',
                style: TextStyle(
                  color: onSurface.withValues(alpha: 0.38),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                '© 2026 Tous droits réservés',
                style: TextStyle(
                  color: onSurface.withValues(alpha: 0.28),
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final String url;

  const _SocialButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.url,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final uri = Uri.parse(url);
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.16)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 19),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


