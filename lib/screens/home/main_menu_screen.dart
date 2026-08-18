import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../utils/image_helper.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import '../../providers/app_provider.dart';
import '../../providers/attendance_provider.dart';
import '../../models/attendance_record.dart';
import '../../core/theme/app_design.dart';
import '../../core/utils/time_utils.dart';

import '../attendance/monthly_attendance_screen.dart';
import '../analytics/analytics_screen.dart';
import '../settings/settings_screen.dart';
import '../payroll/payroll_slips_screen.dart';
import '../wallet/wallet_screen.dart';

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final attendance = context.read<AttendanceProvider>();
      final appProvider = context.read<AppProvider>();
      final empCode = attendance.currentEmpCode.isNotEmpty
          ? attendance.currentEmpCode
          : appProvider.savedMatricule;

      if (empCode.isNotEmpty && (attendance.currentReport == null || attendance.currentReport!.days.isEmpty)) {
        attendance.fetchAttendance(empCode).then((emp) {
          if (emp != null && mounted) {
            final first = emp.firstName.isNotEmpty ? emp.firstName : emp.fullName;
            final last = emp.lastName;
            final dept = emp.department.isNotEmpty ? emp.department : 'Direction';
            context.read<AppProvider>().setZkUserProfile(
              firstName: first,
              lastName: last,
              department: dept,
              matricule: empCode,
            );
          }
        });
      }
    });
  }

  void _openFeature(BuildContext context, int tabIndex, Widget screen) {
    final attProvider = context.read<AttendanceProvider>();
    final width = MediaQuery.of(context).size.width;
    if (width > 850) {
      setState(() {
        _selectedIndex = tabIndex;
      });
      if (tabIndex == 0) {
        attProvider.resetToCurrentMonth();
      }
    } else {
      Navigator.of(context).push(
        PageRouteBuilder<void>(
          transitionDuration: const Duration(milliseconds: 180),
          reverseTransitionDuration: const Duration(milliseconds: 140),
          pageBuilder: (_, _, _) => screen,
          transitionsBuilder: (_, animation, _, child) {
            final curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            );
            return FadeTransition(
              opacity: curved,
              child: child,
            );
          },
        ),
      ).then((_) {
        if (mounted) {
          attProvider.resetToCurrentMonth();
        }
      });
    }
  }

  Widget _buildSelectedDesktopPage() {
    switch (_selectedIndex) {
      case 0:
        return _buildDesktopHomeTab();
      case 1:
        return const MonthlyAttendanceScreen();
      case 2:
        return const AnalyticsScreen();
      case 3:
        return const PayrollSlipsScreen();
      case 4:
        return const WalletScreen();
      case 5:
        return const SettingsScreen();
      default:
        return _buildDesktopHomeTab();
    }
  }

  Widget _buildDesktopHomeTab() {
    final attendance = context.watch<AttendanceProvider>();
    final profile = context.watch<AppProvider>().userProfile;
    final name = (attendance.currentEmployee?.fullName.isNotEmpty == true)
        ? attendance.currentEmployee!.fullName
        : ((attendance.currentReport?.empName.isNotEmpty == true)
            ? attendance.currentReport!.empName
            : (profile?.firstName?.isNotEmpty == true
                ? profile!.firstName!
                : (attendance.currentEmpCode.isNotEmpty ? 'Employé ${attendance.currentEmpCode}' : 'Collaborateur')));
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final cardColor = Theme.of(context).cardColor;

    return Consumer<AttendanceProvider>(
      builder: (context, attendance, child) {
        final now = DateTime.now();
        final recs = attendance.records
            .where((r) => r.date.year == now.year && r.date.month == now.month)
            .toList();

        double totalH = 0;
        int presentCount = 0;
        for (final r in recs) {
          totalH += r.hours;
          if (r.status == AttendanceStatus.present) presentCount++;
        }

        final averageH = presentCount > 0 ? totalH / presentCount : 0.0;
        final presenceRate = recs.isEmpty ? 0.0 : presentCount / recs.length;

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              _buildImmersiveHeader(context, profile, name, isDark),
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _HeaderStatsCard(
                          isDark: isDark,
                          totalHours: totalH,
                          presentCount: presentCount,
                          averageHours: averageH,
                          presenceRate: presenceRate,
                        ),
                        const SizedBox(height: 20),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Left Column: Today's Shift & Quick Actions
                            Expanded(
                              flex: 6,
                              child: Column(
                                children: [
                                  _buildTodayCard(context, isDark, onSurface, cardColor),
                                  const SizedBox(height: 20),
                                  _buildDesktopQuickActionsCard(context, isDark, onSurface, cardColor),
                                ],
                              ),
                            ),
                            const SizedBox(width: 20),
                            // Right Column: Monthly Overview & Activities
                            Expanded(
                              flex: 6,
                              child: Column(
                                children: [
                                  _buildDesktopMonthlySummaryCard(
                                    context,
                                    isDark,
                                    onSurface,
                                    cardColor,
                                    recs,
                                    totalH,
                                    presentCount,
                                  ),
                                  const SizedBox(height: 20),
                                  _buildDesktopRecentActivityCard(
                                    context,
                                    isDark,
                                    onSurface,
                                    cardColor,
                                    recs,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDesktopQuickActionsCard(
    BuildContext context,
    bool isDark,
    Color onSurface,
    Color cardColor,
  ) {
    final surface = isDark ? const Color(0xFF111827) : Colors.white;

    Widget buildActionBtn({
      required String label,
      required String subtitle,
      required IconData icon,
      required List<Color> gradient,
      required VoidCallback onTap,
    }) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: gradient),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: onSurface,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: onSurface.withValues(alpha: 0.50),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: onSurface.withValues(alpha: 0.35),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surface.withValues(alpha: isDark ? 0.84 : 0.96),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.8),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0F766E), Color(0xFF2563EB)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.flash_on_rounded, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 10),
              Text(
                'Actions Rapides',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          buildActionBtn(
            label: 'Suivi Mensuel BioTime',
            subtitle: 'Consulter vos pointages et heures',
            icon: Icons.fingerprint_rounded,
            gradient: const [Color(0xFF059669), Color(0xFF10B981)],
            onTap: () => _openFeature(context, 1, const MonthlyAttendanceScreen()),
          ),
          const SizedBox(height: 10),
          buildActionBtn(
            label: 'Statistiques avancées',
            subtitle: 'Rapports, moyennes et taux de présence',
            icon: Icons.insights_rounded,
            gradient: const [Color(0xFF2563EB), Color(0xFF7C3AED)],
            onTap: () => _openFeature(context, 2, const AnalyticsScreen()),
          ),
          const SizedBox(height: 10),
          buildActionBtn(
            label: 'Bulletins de salaire',
            subtitle: 'Consulter et ajouter des fiches de paie',
            icon: Icons.receipt_long_rounded,
            gradient: const [Color(0xFF0D9488), Color(0xFF06B6D4)],
            onTap: () => _openFeature(context, 3, const PayrollSlipsScreen()),
          ),
          const SizedBox(height: 10),
          buildActionBtn(
            label: 'Portefeuille & Dépenses',
            subtitle: 'Gérer vos finances et opérations',
            icon: Icons.account_balance_wallet_rounded,
            gradient: const [Color(0xFFF97316), Color(0xFFF43F5E)],
            onTap: () => _openFeature(context, 4, const WalletScreen()),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopMonthlySummaryCard(
    BuildContext context,
    bool isDark,
    Color onSurface,
    Color cardColor,
    List<AttendanceRecord> recs,
    double totalH,
    int presentCount,
  ) {
    final surface = isDark ? const Color(0xFF111827) : Colors.white;
    final now = DateTime.now();
    final monthStr = DateFormat('MMMM yyyy', 'fr').format(now);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surface.withValues(alpha: isDark ? 0.84 : 0.96),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.8),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF7C3AED), Color(0xFF2563EB)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.pie_chart_rounded, color: Colors.white, size: 16),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Bilan du mois ($monthStr)',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: onSurface,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () => _openFeature(context, 2, const AnalyticsScreen()),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Text(
                    'Détails →',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F766E),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F766E).withValues(alpha: isDark ? 0.12 : 0.06),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF0F766E).withValues(alpha: 0.15),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Travaillé',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: onSurface.withValues(alpha: 0.55),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        formatDuration(totalH),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF0F766E),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB).withValues(alpha: isDark ? 0.12 : 0.06),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF2563EB).withValues(alpha: 0.15),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Jours Pointés',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: onSurface.withValues(alpha: 0.55),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$presentCount jour(s)',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF2563EB),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopRecentActivityCard(
    BuildContext context,
    bool isDark,
    Color onSurface,
    Color cardColor,
    List<AttendanceRecord> recs,
  ) {
    final surface = isDark ? const Color(0xFF111827) : Colors.white;
    final recentRecs = (recs.toList()..sort((a, b) => b.date.compareTo(a.date))).take(4).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surface.withValues(alpha: isDark ? 0.84 : 0.96),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.8),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF59E0B), Color(0xFFEF4444)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.history_rounded, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 10),
              Text(
                'Derniers Pointages',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (recentRecs.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  'Aucun pointage ce mois',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: onSurface.withValues(alpha: 0.40),
                  ),
                ),
              ),
            )
          else
            ...recentRecs.map((r) {
              final dateFmt = DateFormat('EEEE dd MMM', 'fr').format(r.date);
              final isPresent = r.status == AttendanceStatus.present;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.03) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isPresent ? Icons.check_circle_rounded : Icons.cancel_rounded,
                          size: 16,
                          color: isPresent ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          dateFmt,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: onSurface,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      isPresent ? '${formatDuration(r.hours)} (${r.checkIn ?? '--'} - ${r.checkOut ?? '--'})' : 'Absent',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: isPresent ? const Color(0xFF0F766E) : const Color(0xFFEF4444),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildDesktopSidebar(
    BuildContext context,
    dynamic profile,
    String name,
    bool isDark,
    Color onSurface,
  ) {
    final logoPath = profile?.logoPath as String?;
    final company = (profile?.companyName as String?) ?? '';
    final sidebarBg = isDark ? const Color(0xFF0B1319) : const Color(0xFFF8FAFC);

    return Container(
      width: 280,
      color: sidebarBg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0F766E), Color(0xFF14B8A6)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.layers_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'ShiftTrack',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                    color: Color(0xFF0F766E),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.04)
                    : const Color(0xFFEDF2F7),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: const Color(0xFF0F766E).withValues(alpha: 0.15),
                    backgroundImage: (logoPath != null && logoPath.isNotEmpty)
                        ? AppImageHelper.getImageProvider(logoPath)
                        : const AssetImage(AppImageHelper.officialLogo),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name.isNotEmpty ? name : 'Utilisateur',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: onSurface,
                          ),
                        ),
                        if (company.isNotEmpty)
                          Text(
                            company,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: onSurface.withValues(alpha: 0.48),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _buildSidebarItem(0, Icons.dashboard_rounded, 'Tableau de bord'),
                _buildSidebarItem(1, Icons.fingerprint_rounded, 'Présence'),
                _buildSidebarItem(2, Icons.insights_rounded, 'Statistiques'),
                _buildSidebarItem(3, Icons.receipt_long_rounded, 'Fiches de paie'),
                _buildSidebarItem(4, Icons.account_balance_wallet_rounded, 'Portefeuille'),
                _buildSidebarItem(5, Icons.settings_rounded, 'Paramètres'),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Mode sombre',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: onSurface.withValues(alpha: 0.6),
                  ),
                ),
                Switch(
                  activeThumbColor: const Color(0xFF0F766E),
                  value: isDark,
                  onChanged: (val) {
                    final provider = context.read<AppProvider>();
                    provider.changeTheme(val ? 'dark' : 'light');
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(int index, IconData icon, String label) {
    final isSelected = _selectedIndex == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = const Color(0xFF0F766E);
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: isSelected
            ? activeColor.withValues(alpha: isDark ? 0.15 : 0.08)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            setState(() {
              _selectedIndex = index;
            });
          },
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isSelected ? activeColor : onSurface.withValues(alpha: 0.54),
                  size: 20,
                ),
                const SizedBox(width: 14),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                    color: isSelected ? activeColor : onSurface.withValues(alpha: 0.72),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final attendance = context.watch<AttendanceProvider>();
    final profile = context.watch<AppProvider>().userProfile;
    final emp = attendance.currentEmployee;
    final name = (emp?.fullName.isNotEmpty == true)
        ? emp!.fullName
        : ((attendance.currentReport?.empName.isNotEmpty == true)
            ? attendance.currentReport!.empName
            : (profile?.firstName?.isNotEmpty == true && !profile!.firstName!.startsWith('Employé')
                ? '${profile.firstName} ${profile.lastName ?? ''}'.trim()
                : (attendance.currentEmpCode.isNotEmpty ? 'Employé ${attendance.currentEmpCode}' : 'Utilisateur')));
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final cardColor = Theme.of(context).cardColor;
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width > 850;

    if (isDesktop) {
      return Scaffold(
        backgroundColor: bgColor,
        body: Container(
          decoration: AppDesign.pageBackground(isDark),
          child: Row(
            children: [
              _buildDesktopSidebar(context, profile, name, isDark, onSurface),
              VerticalDivider(
                width: 1,
                thickness: 1,
                color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
              ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 260),
                  transitionBuilder: (child, animation) {
                    return FadeTransition(opacity: animation, child: child);
                  },
                  child: KeyedSubtree(
                    key: ValueKey(_selectedIndex),
                    child: _buildSelectedDesktopPage(),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: bgColor,
        body: Container(
          decoration: AppDesign.pageBackground(isDark),
          child: SingleChildScrollView(
            child: Column(
              children: [
                _buildImmersiveHeader(context, profile, name, isDark),
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1200),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(7),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF0F766E), Color(0xFF2563EB)],
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(
                                        0xFF0F766E,
                                      ).withValues(alpha: 0.24),
                                      blurRadius: 12,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.grid_view_rounded,
                                  color: Colors.white,
                                  size: 17,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Menu Principal',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: onSurface,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          _buildMenuGrid(context, isDark, onSurface, cardColor),
                          const SizedBox(height: 22),
                          _buildTodayCard(context, isDark, onSurface, cardColor),
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
    );
  }

  // Immersive header.

  Widget _buildImmersiveHeader(
    BuildContext context,
    dynamic profile,
    String name,
    bool isDark,
  ) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width > 850;
    final attendance = context.watch<AttendanceProvider>();

    if (isDesktop) {
      final gradientColors = isDark 
          ? const [Color(0xFF0D1E1B), Color(0xFF091412)]
          : const [Color(0xFF0D9488), Color(0xFF0F766E)];
      final borderSideColor = isDark ? Colors.white10 : const Color(0xFF0F766E).withValues(alpha: 0.15);
      final now = DateTime.now();

      return Container(
        height: 80,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: gradientColors),
          border: Border(bottom: BorderSide(color: borderSideColor)),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tableau de bord',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Aperçu général et statistiques',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.70),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    _GlassSyncButton(
                      isLoading: attendance.isLoading,
                      isWhiteText: true,
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        attendance.refresh();
                      },
                    ),
                    const SizedBox(width: 12),
                    _GlassDatePill(now: now, isWhiteText: true),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    return _EnterpriseHeaderBanner(
      profile: profile,
      name: name,
      isDark: isDark,
      onSettingsTap: () {
        _openFeature(context, 5, const SettingsScreen());
      },
    );
  }

  // Menu grid.

  Widget _buildMenuGrid(
    BuildContext context,
    bool isDark,
    Color onSurface,
    Color cardColor,
  ) {
    final items = [
      _MenuItem(
        type: _MenuVisualType.attendance,
        title: 'Présence',
        subtitle: 'Pointage & présence en temps réel',
        icon: Icons.fingerprint_rounded,
        gradient: const [Color(0xFF059669), Color(0xFF34D399)],
        onTap: () => _openFeature(context, 1, const MonthlyAttendanceScreen()),
      ),
      _MenuItem(
        type: _MenuVisualType.analytics,
        title: 'Statistiques',
        subtitle: 'Rapports et analyses avancées',
        icon: Icons.insights_rounded,
        gradient: const [Color(0xFF2563EB), Color(0xFF7C3AED)],
        onTap: () => _openFeature(context, 2, const AnalyticsScreen()),
      ),
      _MenuItem(
        type: _MenuVisualType.payroll,
        title: 'Fiches de paie',
        subtitle: 'Gestion des bulletins de salaire',
        icon: Icons.receipt_long_rounded,
        gradient: const [Color(0xFF14B8A6), Color(0xFF06B6D4)],
        onTap: () => _openFeature(context, 3, const PayrollSlipsScreen()),
      ),
      _MenuItem(
        type: _MenuVisualType.wallet,
        title: 'Portefeuille',
        subtitle: 'Suivi financier et transactions',
        icon: Icons.account_balance_wallet_rounded,
        gradient: const [Color(0xFFF97316), Color(0xFFF43F5E)],
        onTap: () => _openFeature(context, 4, const WalletScreen()),
      ),
    ];

    final width = MediaQuery.of(context).size.width;
    final crossAxisCount = width > 900 ? 4 : (width > 600 ? 3 : 2);
    final childAspectRatio = width > 900 ? 1.15 : (width > 600 ? 1.05 : 0.70);

    return GridView.builder(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: childAspectRatio,
      ),
      itemCount: items.length,
      itemBuilder: (ctx, i) => _PremiumMenuCard(
        item: items[i],
        isDark: isDark,
        onSurface: onSurface,
      ),
    );
  }

  // Today card.

  Widget _buildTodayCard(
    BuildContext context,
    bool isDark,
    Color onSurface,
    Color cardColor,
  ) {
    return Consumer<AttendanceProvider>(
      builder: (context, attendance, _) {
        final todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
        final todayRec = attendance.records.where(
          (r) => DateFormat('yyyy-MM-dd').format(r.date) == todayKey,
        );

        final hasToday = todayRec.isNotEmpty;
        final rec = hasToday ? todayRec.first : null;
        final isPresent = rec?.status == AttendanceStatus.present;
        final hasCheckOut = (rec?.checkOut ?? '').trim().isNotEmpty;
        final isPause = isPresent && !hasCheckOut;
        final workedHours = rec?.hours ?? 0.0;
        final targetHours = (rec?.scheduledHours ?? 0) > 0
            ? rec!.scheduledHours
            : 8.0;
        final productivity = isPresent
            ? (workedHours / targetHours).clamp(0.0, 1.0)
            : 0.0;
        final productivityColor = productivity >= 0.85
            ? const Color(0xFF10B981)
            : productivity >= 0.55
            ? const Color(0xFFF97316)
            : const Color(0xFFEF4444);
        final statusColor = isPause
            ? const Color(0xFFF59E0B)
            : isPresent
            ? const Color(0xFF10B981)
            : const Color(0xFFEF4444);
        final statusLabel = isPause
            ? 'Pause'
            : isPresent
            ? 'Présent'
            : 'Absent';
        final cardSurface = isDark ? const Color(0xFF111827) : Colors.white;

        return RepaintBoundary(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardSurface.withValues(alpha: isDark ? 0.84 : 0.96),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.white.withValues(alpha: 0.78),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.055),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  color: const Color(
                    0xFF0F766E,
                  ).withValues(alpha: isDark ? 0.05 : 0.035),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
                        ),
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF2563EB,
                            ).withValues(alpha: 0.22),
                            blurRadius: 14,
                            offset: const Offset(0, 7),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.calendar_month_rounded,
                        color: Colors.white,
                        size: 21,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Aujourd’hui',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 17,
                              color: onSurface,
                              height: 1.05,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Aperçu de votre journée',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: onSurface.withValues(alpha: 0.46),
                            ),
                          ),
                        ],
                      ),
                    ),
                    _TodayStatusBadge(label: statusLabel, color: statusColor),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _TodayMetricTile(
                      icon: Icons.login_rounded,
                      value: isPresent ? (rec?.checkIn ?? '--:--') : '--:--',
                      label: 'Arrivée',
                      color: const Color(0xFF10B981),
                      onSurface: onSurface,
                      isDark: isDark,
                    ),
                    const SizedBox(width: 10),
                    _TodayMetricTile(
                      icon: Icons.logout_rounded,
                      value: isPresent ? (rec?.checkOut ?? '--:--') : '--:--',
                      label: 'Départ',
                      color: const Color(0xFFEF4444),
                      onSurface: onSurface,
                      isDark: isDark,
                    ),
                    const SizedBox(width: 10),
                    _TodayMetricTile(
                      icon: Icons.schedule_rounded,
                      value: formatDuration(workedHours),
                      label: 'Total travaillé',
                      color: const Color(0xFF2563EB),
                      onSurface: onSurface,
                      isDark: isDark,
                      animatedHours: workedHours,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _TodayProductivityPanel(
                  productivity: productivity,
                  color: productivityColor,
                  onSurface: onSurface,
                  isDark: isDark,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

void _openFeature(BuildContext context, Widget screen) {
  Navigator.of(context).push(
    PageRouteBuilder<void>(
      transitionDuration: const Duration(milliseconds: 180),
      reverseTransitionDuration: const Duration(milliseconds: 140),
      pageBuilder: (_, _, _) => screen,
      transitionsBuilder: (_, animation, _, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.035, 0),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
    ),
  );
}

class _TodayStatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _TodayStatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.35),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _TodayMetricTile extends StatefulWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final Color onSurface;
  final bool isDark;
  final double? animatedHours;

  const _TodayMetricTile({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    required this.onSurface,
    required this.isDark,
    this.animatedHours,
  });

  @override
  State<_TodayMetricTile> createState() => _TodayMetricTileState();
}

class _TodayMetricTileState extends State<_TodayMetricTile> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    if (value) HapticFeedback.lightImpact();
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final fill = widget.isDark
        ? Color.lerp(const Color(0xFF111827), widget.color, 0.10)!
        : Color.lerp(Colors.white, widget.color, 0.055)!;

    return Expanded(
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 130),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: widget.color.withValues(alpha: _pressed ? 0.18 : 0.10),
            ),
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: _pressed ? 0.16 : 0.08),
                blurRadius: _pressed ? 18 : 14,
                offset: Offset(0, _pressed ? 9 : 7),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              splashColor: widget.color.withValues(alpha: 0.10),
              highlightColor: widget.color.withValues(alpha: 0.05),
              onTapDown: (_) => _setPressed(true),
              onTapCancel: () => _setPressed(false),
              onTapUp: (_) => _setPressed(false),
              onTap: () {},
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 12,
                ),
                child: Column(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: widget.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Icon(widget.icon, color: widget.color, size: 18),
                    ),
                    const SizedBox(height: 9),
                    widget.animatedHours == null
                        ? Text(
                            widget.value,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: widget.onSurface,
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              height: 1,
                            ),
                          )
                        : TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: widget.animatedHours),
                            duration: const Duration(milliseconds: 850),
                            curve: Curves.easeOutCubic,
                            builder: (context, value, _) {
                              return FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  _formatAnimatedDuration(value),
                                  maxLines: 1,
                                  style: TextStyle(
                                    color: widget.onSurface,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w900,
                                    height: 1,
                                  ),
                                ),
                              );
                            },
                          ),
                    const SizedBox(height: 5),
                    Text(
                      widget.label,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: widget.onSurface.withValues(alpha: 0.48),
                        fontSize: 10,
                        height: 1.05,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TodayProductivityPanel extends StatelessWidget {
  final double productivity;
  final Color color;
  final Color onSurface;
  final bool isDark;

  const _TodayProductivityPanel({
    required this.productivity,
    required this.color,
    required this.onSurface,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final label = productivity >= 0.85
        ? 'Excellent'
        : productivity >= 0.55
        ? 'Stable'
        : 'À améliorer';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.055)
            : const Color(0xFFF8FAFC).withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : const Color(0xFFE2E8F0).withValues(alpha: 0.78),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color,
                  Color.lerp(color, const Color(0xFF7C3AED), 0.32)!,
                ],
              ),
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.22),
                  blurRadius: 14,
                  offset: const Offset(0, 7),
                ),
              ],
            ),
            child: const Icon(
              Icons.insights_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Productivité aujourd’hui',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: onSurface,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: productivity * 100),
                      duration: const Duration(milliseconds: 900),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, _) {
                        return Text(
                          '${value.round()}%',
                          style: TextStyle(
                            color: onSurface,
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: productivity),
                  duration: const Duration(milliseconds: 900),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, _) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: value,
                        minHeight: 6,
                        backgroundColor: color.withValues(alpha: 0.12),
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.arrow_upward_rounded, color: color, size: 18),
          ),
        ],
      ),
    );
  }
}

// Widgets.

class _EnterpriseHeaderBanner extends StatefulWidget {
  final dynamic profile;
  final String name;
  final bool isDark;
  final VoidCallback? onSettingsTap;

  const _EnterpriseHeaderBanner({
    required this.profile,
    required this.name,
    required this.isDark,
    this.onSettingsTap,
  });

  @override
  State<_EnterpriseHeaderBanner> createState() =>
      _EnterpriseHeaderBannerState();
}

class _EnterpriseHeaderBannerState extends State<_EnterpriseHeaderBanner> {
  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    final now = DateTime.now();
    final String? logoPath = widget.profile?.logoPath as String?;
    final company = (widget.profile?.companyName as String?) ?? '';

    return Consumer<AttendanceProvider>(
      builder: (context, attendance, _) {
        final dynamicName = (attendance.currentEmployee?.fullName.isNotEmpty == true)
            ? attendance.currentEmployee!.fullName
            : ((attendance.currentReport?.empName.isNotEmpty == true)
                ? attendance.currentReport!.empName
                : (widget.name.isNotEmpty
                    ? widget.name
                    : (attendance.currentEmpCode.isNotEmpty ? 'Employé ${attendance.currentEmpCode}' : 'Collaborateur')));
        final dynamicDept = attendance.currentEmployee?.department ?? attendance.currentReport?.department ?? company;

        final recs = attendance.records
            .where((r) => r.date.year == now.year && r.date.month == now.month)
            .toList();

        if (attendance.selectedMonth.year != now.year || attendance.selectedMonth.month != now.month) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              attendance.resetToCurrentMonth();
            }
          });
        }

        double totalH = 0;
        int presentCount = 0;
        for (final r in recs) {
          totalH += r.hours;
          if (r.status == AttendanceStatus.present) presentCount++;
        }

        final averageH = presentCount > 0 ? totalH / presentCount : 0.0;
        final presenceRate = recs.isEmpty ? 0.0 : presentCount / recs.length;
        final bannerHeight = topPad + 188.0;
        const statsHeight = 126.0;
        const statsOverlap = 24.0;
        final totalHeight = bannerHeight + statsHeight - statsOverlap + 10;

        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 520),
          curve: Curves.easeOutCubic,
          builder: (context, fade, child) {
            return Opacity(
              opacity: fade,
              child: Transform.translate(
                offset: Offset(0, (1 - fade) * 18),
                child: child,
              ),
            );
          },
          child: SizedBox(
            height: totalHeight,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: bannerHeight,
                  child: RepaintBoundary(
                    child: Builder(
                      builder: (context) {
                        const t = 0.0;
                        return Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: AppDesign.heroGradient(widget.isDark),
                            ),
                            borderRadius: const BorderRadius.vertical(
                              bottom: Radius.circular(30),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(
                                  alpha: widget.isDark ? 0.16 : 0.06,
                                ),
                                blurRadius: 22,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Stack(
                            children: [
                              _FloatingOrb(
                                top: -38 + math.sin(t) * 6,
                                right: -54 + math.cos(t) * 5,
                                size: 180,
                                opacity: 0.10,
                              ),
                              _FloatingOrb(
                                bottom: -66 + math.cos(t * 0.8) * 6,
                                left: -42 + math.sin(t) * 5,
                                size: 142,
                                opacity: 0.08,
                              ),
                              _FloatingOrb(
                                bottom: 22 + math.sin(t * 1.2) * 4,
                                right: 44 + math.cos(t) * 5,
                                size: 72,
                                opacity: 0.06,
                              ),
                              Positioned.fill(
                                child: CustomPaint(
                                  painter: _HeaderWavePainter(progress: 0),
                                ),
                              ),
                              Center(
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(maxWidth: 1200),
                                  child: Padding(
                                    padding: EdgeInsets.fromLTRB(
                                      20,
                                      topPad + 16,
                                      20,
                                      0,
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            _GlassIconButton(
                                              icon: Icons.menu_rounded,
                                              onTap: () {
                                                if (widget.onSettingsTap != null) {
                                                  widget.onSettingsTap!();
                                                } else {
                                                  _openFeature(
                                                    context,
                                                    const SettingsScreen(),
                                                  );
                                                }
                                              },
                                            ),
                                            const Spacer(),
                                            _GlassSyncButton(
                                              isLoading: attendance.isLoading,
                                              onTap: () async {
                                                HapticFeedback.mediumImpact();
                                                final empCode = attendance.currentEmpCode;
                                                if (empCode.isEmpty) return;
                                                final res = await attendance.fetchAttendance(empCode, forceSync: true);
                                                if (context.mounted) {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(
                                                      content: Row(
                                                        children: [
                                                          Icon(
                                                            res != null ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                                                            color: Colors.white,
                                                            size: 20,
                                                          ),
                                                          const SizedBox(width: 10),
                                                          Text(
                                                            res != null
                                                                ? 'Synchronisation des pointages réussie !'
                                                                : 'Mise à jour effectuée.',
                                                            style: const TextStyle(fontWeight: FontWeight.bold),
                                                          ),
                                                        ],
                                                      ),
                                                      backgroundColor: res != null ? const Color(0xFF059669) : const Color(0xFF2563EB),
                                                      behavior: SnackBarBehavior.floating,
                                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                                      duration: const Duration(seconds: 2),
                                                    ),
                                                  );
                                                }
                                              },
                                            ),
                                            const SizedBox(width: 10),
                                            _GlassDatePill(now: now),
                                          ],
                                        ),
                                        const SizedBox(height: 16),
                                        _CompactUserCard(
                                          greeting: _headerGreeting(),
                                          employeeName: dynamicName,
                                          company: dynamicDept,
                                          logoPath: logoPath,
                                          photoUrl: attendance.currentEmployee?.photoUrl,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  top: bannerHeight - statsOverlap,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1200),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _HeaderStatsCard(
                          isDark: widget.isDark,
                          totalHours: totalH,
                          presentCount: presentCount,
                          averageHours: averageH,
                          presenceRate: presenceRate,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _headerGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Bonjour';
    if (hour < 18) return 'Bon apres-midi';
    return 'Bonsoir';
  }
}

class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _GlassIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return _GlassSurface(
      radius: 14,
      isDark: isDark,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(
            icon,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
            size: 22,
          ),
        ),
      ),
    );
  }
}

class _GlassSyncButton extends StatefulWidget {
  final bool isLoading;
  final VoidCallback onTap;
  final bool isWhiteText;

  const _GlassSyncButton({
    required this.isLoading,
    required this.onTap,
    this.isWhiteText = false,
  });

  @override
  State<_GlassSyncButton> createState() => _GlassSyncButtonState();
}

class _GlassSyncButtonState extends State<_GlassSyncButton> with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    if (widget.isLoading) {
      _rotationController.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant _GlassSyncButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLoading && !_rotationController.isAnimating) {
      _rotationController.repeat();
    } else if (!widget.isLoading && _rotationController.isAnimating) {
      _rotationController.stop();
      _rotationController.reset();
    }
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = widget.isWhiteText ? Colors.white : (isDark ? Colors.white : const Color(0xFF0F172A));

    return _GlassSurface(
      radius: 14,
      isDark: isDark || widget.isWhiteText,
      child: Tooltip(
        message: 'Synchroniser avec ZKBioTime',
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: widget.isLoading ? null : widget.onTap,
          child: SizedBox(
            width: 44,
            height: 44,
            child: Center(
              child: RotationTransition(
                turns: _rotationController,
                child: Icon(
                  Icons.sync_rounded,
                  color: iconColor,
                  size: 20,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassDatePill extends StatelessWidget {
  final DateTime now;
  final bool isWhiteText;

  const _GlassDatePill({required this.now, this.isWhiteText = false});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isWhiteText ? Colors.white : (isDark ? Colors.white : const Color(0xFF0F172A));
    return _GlassSurface(
      radius: 14,
      isDark: isDark || isWhiteText,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.calendar_month_rounded,
              color: textColor,
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              DateFormat('EEE, d MMM', 'fr').format(now),
              style: TextStyle(
                color: textColor,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompactUserCard extends StatelessWidget {
  final String greeting;
  final String employeeName;
  final String company;
  final String? logoPath;
  final String? photoUrl;

  const _CompactUserCard({
    required this.greeting,
    required this.employeeName,
    required this.company,
    required this.logoPath,
    this.photoUrl,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subColor = isDark ? Colors.white.withValues(alpha: 0.64) : const Color(0xFF475569);

    return _GlassSurface(
      radius: 24,
      isDark: isDark,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            _CompactAvatar(logoPath: logoPath, photoUrl: photoUrl, name: employeeName),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  RichText(
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    text: TextSpan(
                      style: TextStyle(
                        color: titleColor.withValues(alpha: 0.86),
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                      children: [
                        TextSpan(text: '$greeting, '),
                        TextSpan(
                          text: employeeName,
                          style: TextStyle(
                            color: titleColor,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    company.isNotEmpty ? company : 'Bonne journée de travail',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: subColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
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

class _CompactAvatar extends StatelessWidget {
  final String? logoPath;
  final String? photoUrl;
  final String name;

  const _CompactAvatar({
    required this.logoPath,
    this.photoUrl,
    required this.name,
  });

  @override
  Widget build(BuildContext context) {
    final hasLogo = AppImageHelper.exists(logoPath);
    final hasPhotoUrl = photoUrl != null && photoUrl!.isNotEmpty;

    ImageProvider imageProvider;
    if (hasLogo) {
      imageProvider = ResizeImage(AppImageHelper.getImageProvider(logoPath!), width: 120, height: 120);
    } else if (hasPhotoUrl) {
      imageProvider = NetworkImage(photoUrl!);
    } else {
      imageProvider = AppImageHelper.officialLogoProvider;
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: const EdgeInsets.all(2.5),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFF06B6D4), Color(0xFF2563EB)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2563EB).withValues(alpha: 0.35),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: CircleAvatar(
            radius: 25,
            backgroundColor: const Color(0xFF1E3A8A),
            backgroundImage: imageProvider,
          ),
        ),
        Positioned(
          right: -1,
          bottom: 3,
          child: Container(
            width: 15,
            height: 15,
            decoration: BoxDecoration(
              color: const Color(0xFF22C55E),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF22C55E).withValues(alpha: 0.35),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _HeaderStatsCard extends StatelessWidget {
  final bool isDark;
  final double totalHours;
  final int presentCount;
  final double averageHours;
  final double presenceRate;

  const _HeaderStatsCard({
    required this.isDark,
    required this.totalHours,
    required this.presentCount,
    required this.averageHours,
    required this.presenceRate,
  });

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? const Color(0xFF111827) : Colors.white;
    return Container(
      height: 126,
      decoration: BoxDecoration(
        color: surface.withValues(alpha: isDark ? 0.90 : 1.0),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.09)
              : const Color(0xFFE5ECF5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.16 : 0.055),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: const Color(
              0xFF2563EB,
            ).withValues(alpha: isDark ? 0.05 : 0.035),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            _AnimatedHeaderMetric(
              icon: Icons.schedule_rounded,
              color: const Color(0xFF7C3AED),
              value: totalHours,
              label: 'Heures ce mois',
              progress: (totalHours / 180).clamp(0.0, 1.0),
              formatter: _formatAnimatedDuration,
            ),
            _StatDivider(isDark: isDark),
            _AnimatedHeaderMetric(
              icon: Icons.check_circle_rounded,
              color: const Color(0xFF10B981),
              value: presentCount.toDouble(),
              label: 'Présences',
              progress: (presentCount / 22).clamp(0.0, 1.0),
              formatter: (value) => '${value.round()} j',
            ),
            _StatDivider(isDark: isDark),
            _AnimatedHeaderMetric(
              icon: Icons.trending_up_rounded,
              color: const Color(0xFFF97316),
              value: averageHours,
              label: 'Moyenne / jour',
              progress: (averageHours / 8).clamp(0.0, 1.0),
              formatter: _formatAnimatedDuration,
            ),
            _StatDivider(isDark: isDark),
            _AnimatedHeaderMetric(
              icon: Icons.data_usage_rounded,
              color: const Color(0xFF3B82F6),
              value: presenceRate * 100,
              label: 'Taux de présence',
              progress: presenceRate.clamp(0.0, 1.0),
              formatter: (value) => '${value.round()}%',
            ),
          ],
        ),
      ),
    );
  }
}

class _AnimatedHeaderMetric extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double value;
  final String label;
  final double progress;
  final String Function(double value) formatter;

  const _AnimatedHeaderMetric({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
    required this.progress,
    required this.formatter,
  });

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Expanded(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: value),
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeOutCubic,
        builder: (context, animatedValue, _) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 21),
              ),
              const SizedBox(height: 8),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  formatter(animatedValue),
                  maxLines: 1,
                  style: TextStyle(
                    color: onSurface,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
              ),
              const SizedBox(height: 5),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: onSurface.withValues(alpha: 0.54),
                  fontSize: 9.2,
                  fontWeight: FontWeight.w700,
                  height: 1.05,
                ),
              ),
              const SizedBox(height: 8),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: progress),
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeOutCubic,
                builder: (context, progressValue, _) {
                  return Container(
                    width: 42,
                    height: 4,
                    alignment: Alignment.centerLeft,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.13),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: FractionallySizedBox(
                      widthFactor: progressValue,
                      child: Container(
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  final bool isDark;

  const _StatDivider({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 88,
      color: isDark
          ? Colors.white.withValues(alpha: 0.08)
          : const Color(0xFF0F172A).withValues(alpha: 0.08),
    );
  }
}

class _GlassSurface extends StatelessWidget {
  final double radius;
  final Widget child;
  final bool isDark;

  const _GlassSurface({
    required this.radius,
    required this.child,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    final dark = isDark || Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: dark ? Colors.white.withValues(alpha: 0.16) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: dark
              ? Colors.white.withValues(alpha: 0.18)
              : const Color(0xFFE2E8F0),
        ),
      ),
      child: child,
    );
  }
}

class _FloatingOrb extends StatelessWidget {
  final double? top;
  final double? left;
  final double? right;
  final double? bottom;
  final double size;
  final double opacity;

  const _FloatingOrb({
    this.top,
    this.left,
    this.right,
    this.bottom,
    required this.size,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      bottom: bottom,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: opacity),
        ),
      ),
    );
  }
}

class _HeaderWavePainter extends CustomPainter {
  final double progress;

  _HeaderWavePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.10)
      ..style = PaintingStyle.fill;
    final wave = Path()
      ..moveTo(0, size.height * 0.62)
      ..cubicTo(
        size.width * 0.28,
        size.height * (0.48 + math.sin(progress * math.pi * 2) * 0.02),
        size.width * 0.52,
        size.height * 0.80,
        size.width,
        size.height * 0.56,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(wave, paint);
  }

  @override
  bool shouldRepaint(covariant _HeaderWavePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

String _formatAnimatedDuration(double hours) {
  var h = hours.floor();
  var m = ((hours - h) * 60).round();
  if (m == 60) {
    h += 1;
    m = 0;
  }
  return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')} h';
}

enum _MenuVisualType { attendance, analytics, payroll, wallet }

class _MenuItem {
  final _MenuVisualType type;
  final String title, subtitle;
  final IconData icon;
  final List<Color> gradient;
  final VoidCallback onTap;

  const _MenuItem({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.onTap,
  });
}

class _PremiumMenuCard extends StatefulWidget {
  final _MenuItem item;
  final bool isDark;
  final Color onSurface;

  const _PremiumMenuCard({
    required this.item,
    required this.isDark,
    required this.onSurface,
  });

  @override
  State<_PremiumMenuCard> createState() => _PremiumMenuCardState();
}

class _PremiumMenuCardState extends State<_PremiumMenuCard> {
  bool _pressed = false;

  void _handlePressDown() {
    if (!_pressed) {
      HapticFeedback.lightImpact();
    }
    _setPressed(true);
  }

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final isDark = widget.isDark;
    final onSurface = widget.onSurface;
    final surface = isDark ? const Color(0xFF14212B) : Colors.white;
    final titleColor = isDark
        ? Colors.white.withValues(alpha: 0.94)
        : onSurface;
    final subtitleColor = isDark
        ? Colors.white.withValues(alpha: 0.62)
        : onSurface.withValues(alpha: 0.54);

    return AnimatedScale(
      scale: _pressed ? 0.97 : 1,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOutCubic,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 130),
        curve: Curves.easeOutCubic,
        transform: Matrix4.identity()
          ..rotateZ(_pressed ? -0.0035 : 0.0)
          ..setTranslationRaw(_pressed ? 0.8 : 0.0, _pressed ? 1.5 : 0.0, 0.0),
        transformAlignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    Color.lerp(surface, item.gradient.first, 0.26)!,
                    Color.lerp(surface, item.gradient.last, 0.12)!,
                    surface.withValues(alpha: 0.98),
                  ]
                : [
                    Colors.white.withValues(alpha: 0.94),
                    Color.lerp(Colors.white, item.gradient.first, 0.10)!,
                  ],
          ),
          border: Border.all(
            color: isDark
                ? item.gradient.first.withValues(alpha: _pressed ? 0.34 : 0.22)
                : item.gradient.first.withValues(alpha: _pressed ? 0.25 : 0.16),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: item.gradient.first.withValues(
                alpha: _pressed
                    ? (isDark ? 0.28 : 0.26)
                    : (isDark ? 0.18 : 0.18),
              ),
              blurRadius: _pressed ? 22 : 18,
              offset: Offset(0, _pressed ? 12 : 10),
            ),
            BoxShadow(
              color: Colors.black.withValues(
                alpha: _pressed
                    ? (isDark ? 0.22 : 0.09)
                    : (isDark ? 0.16 : 0.06),
              ),
              blurRadius: _pressed ? 16 : 12,
              offset: Offset(0, _pressed ? 8 : 6),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            splashColor: item.gradient.first.withValues(alpha: 0.12),
            highlightColor: item.gradient.first.withValues(alpha: 0.06),
            hoverColor: item.gradient.first.withValues(alpha: 0.04),
            onTapDown: (_) => _handlePressDown(),
            onTapCancel: () => _setPressed(false),
            onTapUp: (_) => _setPressed(false),
            onTap: item.onTap,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Stack(
                children: [
                  Positioned(
                    right: -42,
                    bottom: -48,
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: item.gradient.first.withValues(
                          alpha: isDark ? 0.24 : 0.10,
                        ),
                      ),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: item.gradient,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: item.gradient.first.withValues(
                                    alpha: _pressed ? 0.40 : 0.30,
                                  ),
                                  blurRadius: _pressed ? 20 : 16,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Icon(
                              item.icon,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const Spacer(),
                          _ArrowButton(
                            colors: item.gradient,
                            pressed: _pressed,
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Text(
                        item.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: titleColor,
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                          height: 1.05,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item.subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: subtitleColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          height: 1.32,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: Align(
                          alignment: Alignment.bottomRight,
                          child: SizedBox(
                            width: 140,
                            height: 118,
                            child: FittedBox(
                              alignment: Alignment.bottomRight,
                              fit: BoxFit.contain,
                              child: _MenuVisual(item: item, isDark: isDark),
                            ),
                          ),
                        ),
                      ),
                    ],
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

class _ArrowButton extends StatelessWidget {
  final List<Color> colors;
  final bool pressed;

  const _ArrowButton({required this.colors, required this.pressed});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      width: 38,
      height: 38,
      transform: Matrix4.translationValues(pressed ? 3 : 0, 0, 0),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color:
            (Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFFF8FAFC)
                    : Colors.white)
                .withValues(alpha: 0.92),
        boxShadow: [
          BoxShadow(
            color: colors.first.withValues(
              alpha: Theme.of(context).brightness == Brightness.dark
                  ? 0.26
                  : 0.18,
            ),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Icon(
        Icons.arrow_forward_ios_rounded,
        color: colors.first,
        size: 16,
      ),
    );
  }
}

class _MenuVisual extends StatelessWidget {
  final _MenuItem item;
  final bool isDark;

  const _MenuVisual({required this.item, required this.isDark});

  @override
  Widget build(BuildContext context) {
    switch (item.type) {
      case _MenuVisualType.attendance:
        return _AttendanceVisual(colors: item.gradient);
      case _MenuVisualType.analytics:
        return _AnalyticsVisual(colors: item.gradient);
      case _MenuVisualType.payroll:
        return _PayrollVisual(colors: item.gradient);
      case _MenuVisualType.wallet:
        return _WalletVisual(colors: item.gradient);
    }
  }
}

class _AttendanceVisual extends StatelessWidget {
  final List<Color> colors;

  const _AttendanceVisual({required this.colors});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 126,
      height: 120,
      child: Stack(
        children: [
          Positioned(
            left: 28,
            top: 10,
            child: Transform.rotate(
              angle: -0.08,
              child: _Soft3DBox(
                width: 88,
                height: 78,
                radius: 16,
                colors: [
                  Colors.white,
                  Color.lerp(Colors.white, colors.first, 0.18)!,
                ],
                child: Column(
                  children: [
                    Container(
                      height: 18,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: colors),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(9),
                        child: GridView.count(
                          crossAxisCount: 3,
                          mainAxisSpacing: 5,
                          crossAxisSpacing: 5,
                          physics: const NeverScrollableScrollPhysics(),
                          children: List.generate(
                            6,
                            (i) => Container(
                              decoration: BoxDecoration(
                                color: i == 4
                                    ? colors.first.withValues(alpha: 0.88)
                                    : const Color(0xFFE8EEF2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: i == 4
                                  ? const Icon(
                                      Icons.check_rounded,
                                      color: Colors.white,
                                      size: 13,
                                    )
                                  : null,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 8,
            bottom: 22,
            child: _FloatingBadge(
              text: '98%',
              color: colors.first,
              icon: Icons.fingerprint_rounded,
            ),
          ),
          Positioned(
            right: 6,
            bottom: 4,
            child: _TinyStatusDot(color: colors.last),
          ),
        ],
      ),
    );
  }
}

class _AnalyticsVisual extends StatelessWidget {
  final List<Color> colors;

  const _AnalyticsVisual({required this.colors});

  @override
  Widget build(BuildContext context) {
    final heights = [30.0, 46.0, 62.0, 82.0];
    return SizedBox(
      width: 116,
      height: 112,
      child: Stack(
        children: [
          Positioned(
            left: 12,
            bottom: 14,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(
                heights.length,
                (i) => Container(
                  width: 16,
                  height: heights[i],
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        colors.first.withValues(alpha: 0.42 + (i * 0.08)),
                        colors.last.withValues(alpha: 0.88),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(7),
                    boxShadow: [
                      BoxShadow(
                        color: colors.last.withValues(alpha: 0.18),
                        blurRadius: 10,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 20,
            left: 15,
            right: 8,
            child: CustomPaint(
              size: const Size(90, 46),
              painter: _LineChartPainter(colors.last),
            ),
          ),
          Positioned(
            right: 6,
            top: 4,
            child: _TinyStatusDot(color: colors.last),
          ),
        ],
      ),
    );
  }
}

class _PayrollVisual extends StatelessWidget {
  final List<Color> colors;

  const _PayrollVisual({required this.colors});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 128,
      height: 120,
      child: Stack(
        children: [
          Positioned(
            right: 10,
            top: 18,
            child: Transform.rotate(
              angle: 0.08,
              child: _Soft3DBox(
                width: 82,
                height: 94,
                radius: 10,
                colors: [
                  Colors.white,
                  Color.lerp(Colors.white, colors.last, 0.16)!,
                ],
                child: Padding(
                  padding: const EdgeInsets.all(11),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 34,
                        height: 6,
                        decoration: BoxDecoration(
                          color: colors.last.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...List.generate(
                        4,
                        (i) => Container(
                          width: 42 - (i * 5),
                          height: 5,
                          margin: const EdgeInsets.only(bottom: 7),
                          decoration: BoxDecoration(
                            color: const Color(0xFFCBD5E1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 8,
            bottom: 16,
            child: _FloatingBadge(
              text: 'DA',
              color: colors.first,
              icon: Icons.payments_rounded,
            ),
          ),
        ],
      ),
    );
  }
}

class _WalletVisual extends StatelessWidget {
  final List<Color> colors;

  const _WalletVisual({required this.colors});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 118,
      height: 112,
      child: Stack(
        children: [
          Positioned(
            right: 10,
            bottom: 12,
            child: _Soft3DBox(
              width: 78,
              height: 60,
              radius: 18,
              colors: [colors.first.withValues(alpha: 0.86), colors.last],
              child: Stack(
                children: [
                  Positioned(
                    left: 10,
                    top: 10,
                    child: Container(
                      width: 52,
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 10,
                    bottom: 12,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.72),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 8,
            top: 24,
            child: Transform.rotate(
              angle: -0.08,
              child: _Soft3DBox(
                width: 62,
                height: 38,
                radius: 12,
                colors: [Colors.white, const Color(0xFFFFF7ED)],
                child: Center(
                  child: Text(
                    '+1200',
                    style: TextStyle(
                      color: colors.first,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Soft3DBox extends StatelessWidget {
  final double width;
  final double height;
  final double radius;
  final List<Color> colors;
  final Widget child;

  const _Soft3DBox({
    required this.width,
    required this.height,
    required this.radius,
    required this.colors,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: Colors.white.withValues(alpha: 0.55)),
        boxShadow: [
          BoxShadow(
            color: colors.last.withValues(alpha: 0.20),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

class _FloatingBadge extends StatelessWidget {
  final String text;
  final Color color;
  final IconData icon;

  const _FloatingBadge({
    required this.text,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.16),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _TinyStatusDot extends StatelessWidget {
  final Color color;

  const _TinyStatusDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.20),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Icon(Icons.check_rounded, size: 13, color: color),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  final Color color;

  _LineChartPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final path = Path()
      ..moveTo(0, size.height * 0.82)
      ..lineTo(size.width * 0.25, size.height * 0.50)
      ..lineTo(size.width * 0.48, size.height * 0.62)
      ..lineTo(size.width * 0.72, size.height * 0.30)
      ..lineTo(size.width, size.height * 0.10);
    canvas.drawPath(path, paint);

    final dotPaint = Paint()..color = color;
    for (final point in [
      Offset(0, size.height * 0.82),
      Offset(size.width * 0.25, size.height * 0.50),
      Offset(size.width * 0.48, size.height * 0.62),
      Offset(size.width * 0.72, size.height * 0.30),
      Offset(size.width, size.height * 0.10),
    ]) {
      canvas.drawCircle(point, 4.2, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
