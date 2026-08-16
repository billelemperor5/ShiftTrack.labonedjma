import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/app_provider.dart';
import '../home/main_menu_screen.dart';

class BioTimeLoginScreen extends StatefulWidget {
  const BioTimeLoginScreen({super.key});

  @override
  State<BioTimeLoginScreen> createState() => _BioTimeLoginScreenState();
}

class _BioTimeLoginScreenState extends State<BioTimeLoginScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _matriculeController = TextEditingController();
  
  bool _isLoading = false;
  bool _rememberMe = true;
  String? _errorMessage;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _matriculeController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final matricule = _matriculeController.text.trim();
    if (matricule.isEmpty) {
      setState(() {
        _errorMessage = 'Veuillez saisir votre numéro de matricule';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final attendanceProvider = context.read<AttendanceProvider>();
      final emp = await attendanceProvider.fetchAttendance(matricule);

      if (!mounted) return;

      if (emp == null && attendanceProvider.records.isEmpty && (attendanceProvider.currentReport?.days.isEmpty ?? true)) {
        setState(() {
          _errorMessage = 'Matricule non trouvé ou serveur inaccessible. Vérifiez le numéro "$matricule".';
        });
        return;
      }

      final first = (emp?.firstName.isNotEmpty == true)
          ? emp!.firstName
          : (emp?.fullName.isNotEmpty == true ? emp!.fullName.split(' ').first : 'Employé $matricule');
      final last = (emp?.lastName.isNotEmpty == true)
          ? emp!.lastName
          : (emp?.fullName.isNotEmpty == true && emp!.fullName.contains(' ') ? emp.fullName.split(' ').sublist(1).join(' ') : '');
      final dept = emp?.department.isNotEmpty == true ? emp!.department : 'Direction';

      if (_rememberMe) {
        await context.read<AppProvider>().setZkUserProfile(
          firstName: first,
          lastName: last,
          department: dept,
          matricule: matricule,
        );
      }

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainMenuScreen()),
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Erreur lors de la connexion: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [const Color(0xFF060B18), const Color(0xFF0F172A), const Color(0xFF1E1B4B)]
                : [const Color(0xFFF1F5F9), const Color(0xFFE2E8F0), const Color(0xFFEFF6FF)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Card(
                  elevation: 16,
                  shadowColor: const Color(0xFF2563EB).withValues(alpha: isDark ? 0.3 : 0.15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                  color: isDark ? const Color(0xFF131D33).withValues(alpha: 0.95) : Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 34),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Luxury Logo Header with animated glowing pulse
                          Center(
                            child: ScaleTransition(
                              scale: _pulseAnimation,
                              child: Container(
                                width: 88,
                                height: 88,
                                padding: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF2563EB), Color(0xFF38BDF8), Color(0xFF6366F1)],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF2563EB).withValues(alpha: 0.4),
                                      blurRadius: 20,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: Container(
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white,
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: Image.asset(
                                    'assets/images/official_logo.jpg',
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => const Icon(
                                      Icons.fingerprint_rounded,
                                      size: 46,
                                      color: Color(0xFF1E3A8A),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Brand Title
                          Text(
                            'LA BONEDJIMA',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2.0,
                              color: const Color(0xFF1E40AF),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Portail Collaborateur & Pointage',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 28),

                          // Error Alert Box
                          if (_errorMessage != null) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.red.withValues(alpha: 0.1),
                                border: Border.all(color: Colors.red.withValues(alpha: 0.35)),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 20),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      _errorMessage!,
                                      style: const TextStyle(
                                        color: Colors.redAccent,
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 18),
                          ],

                          // Single Clean Matricule Input Field
                          Text(
                            'NUMÉRO DE MATRICULE',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                              color: isDark ? Colors.grey[300] : const Color(0xFF475569),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _matriculeController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _handleLogin(),
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Entrez votre matricule...',
                              hintStyle: TextStyle(
                                color: isDark ? Colors.grey[600] : Colors.grey[400],
                                fontWeight: FontWeight.normal,
                              ),
                              prefixIcon: const Icon(
                                Icons.badge_rounded,
                                color: Color(0xFF2563EB),
                                size: 22,
                              ),
                              suffixIcon: _matriculeController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.cancel_rounded, size: 18),
                                      onPressed: () {
                                        _matriculeController.clear();
                                        setState(() {});
                                      },
                                    )
                                  : null,
                              filled: true,
                              fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(
                                  color: isDark ? Colors.grey[800]! : const Color(0xFFE2E8F0),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(
                                  color: isDark ? Colors.grey[700]! : const Color(0xFFCBD5E1),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2),
                              ),
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                          const SizedBox(height: 14),

                          // Remember Me Toggle
                          InkWell(
                            onTap: () => setState(() => _rememberMe = !_rememberMe),
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: Checkbox(
                                      value: _rememberMe,
                                      activeColor: const Color(0xFF2563EB),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                      onChanged: (v) => setState(() => _rememberMe = v ?? true),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Se souvenir de ma session',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? Colors.grey[300] : const Color(0xFF334155),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Login Action Button
                          Container(
                            height: 52,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF1E40AF), Color(0xFF2563EB)],
                              ),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF2563EB).withValues(alpha: 0.35),
                                  blurRadius: 14,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleLogin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              child: _isLoading
                                  ? const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2.2,
                                          ),
                                        ),
                                        SizedBox(width: 12),
                                        Text(
                                          'Connexion en cours...',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 14.5,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    )
                                  : const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
                                        SizedBox(width: 10),
                                        Text(
                                          'Se Connecter',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 15.5,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // 100% Read-Only Safety badge
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 14),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.25)),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.verified_user_rounded, size: 16, color: Color(0xFF10B981)),
                                SizedBox(width: 8),
                                Text(
                                  'Accès Sécurisé • Mode 100% Consultation',
                                  style: TextStyle(
                                    color: Color(0xFF059669),
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
