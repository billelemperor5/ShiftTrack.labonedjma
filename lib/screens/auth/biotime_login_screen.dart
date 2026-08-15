import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/zkbiotime_service.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/app_provider.dart';
import '../home/main_menu_screen.dart';

class BioTimeLoginScreen extends StatefulWidget {
  const BioTimeLoginScreen({super.key});

  @override
  State<BioTimeLoginScreen> createState() => _BioTimeLoginScreenState();
}

class _BioTimeLoginScreenState extends State<BioTimeLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _serverUrlController = TextEditingController(text: 'http://105.96.0.211:8080');
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _matriculeController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _serverUrlController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _matriculeController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final server = _serverUrlController.text.trim().isNotEmpty
          ? _serverUrlController.text.trim()
          : 'http://105.96.0.211:8080';
      final username = _usernameController.text.trim().isNotEmpty
          ? _usernameController.text.trim()
          : 'billel.bouraba';
      final password = _passwordController.text.isNotEmpty
          ? _passwordController.text
          : 'Billel02081987*';

      final success = await ZKBioTimeService().login(
        serverUrl: server,
        username: username,
        password: password,
      );

      if (success) {
        final matricule = _matriculeController.text.trim();
        if (!mounted) return;
        final attendanceProvider = context.read<AttendanceProvider>();
        final emp = await attendanceProvider.fetchAttendance(matricule);

        if (!mounted) return;
        final first = (emp?.firstName.isNotEmpty == true)
            ? emp!.firstName
            : (emp?.fullName.isNotEmpty == true ? emp!.fullName.split(' ').first : 'Employé $matricule');
        final last = (emp?.lastName.isNotEmpty == true)
            ? emp!.lastName
            : (emp?.fullName.isNotEmpty == true && emp!.fullName.contains(' ') ? emp.fullName.split(' ').sublist(1).join(' ') : '');
        final dept = emp?.department.isNotEmpty == true ? emp!.department : 'Direction';

        await context.read<AppProvider>().setZkUserProfile(
          firstName: first,
          lastName: last,
          department: dept,
          matricule: matricule,
        );

        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainMenuScreen()),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur de connexion: $e';
      });
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
                ? [const Color(0xFF090D16), const Color(0xFF1E1B4B), const Color(0xFF0F172A)]
                : [const Color(0xFFF8FAFC), const Color(0xFFE0F2FE), const Color(0xFFEEF2FF)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Card(
                  elevation: 12,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  color: isDark ? const Color(0xFF0F172A).withOpacity(0.9) : Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Header Icon
                          Center(
                            child: Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF2563EB), Color(0xFF0284C7)],
                                ),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF2563EB).withOpacity(0.35),
                                    blurRadius: 16,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.fingerprint_rounded, size: 40, color: Colors.white),
                            ),
                          ),
                          const SizedBox(height: 18),

                          // Title
                          Text(
                            'ShiftTrack BIO Connect',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Connexion directe au serveur ZKBioTime 9.0.3',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Error Box
                          if (_errorMessage != null) ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.12),
                                border: Border.all(color: Colors.red.withOpacity(0.3)),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.error_outline_rounded, color: Colors.red, size: 20),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      _errorMessage!,
                                      style: const TextStyle(color: Colors.red, fontSize: 12.5),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Server URL
                          TextFormField(
                            controller: _serverUrlController,
                            decoration: InputDecoration(
                              labelText: 'URL Serveur ZKBioTime',
                              prefixIcon: const Icon(Icons.cloud_outlined),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            validator: (v) => v == null || v.trim().isEmpty ? 'Veuillez saisir l\'URL du serveur' : null,
                          ),
                          const SizedBox(height: 14),

                          // Username
                          TextFormField(
                            controller: _usernameController,
                            decoration: InputDecoration(
                              labelText: 'Nom d\'utilisateur ZKBioTime (Optionnel)',
                              hintText: 'Laisser vide pour utiliser le compte par défaut',
                              prefixIcon: const Icon(Icons.person_outline),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Password
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: 'Mot de passe (Optionnel)',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              ),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Matricule
                          TextFormField(
                            controller: _matriculeController,
                            decoration: InputDecoration(
                              labelText: 'Matricule Employé * (Ex: 40754, 30031...)',
                              hintText: 'Entrez votre matricule',
                              prefixIcon: const Icon(Icons.badge_outlined),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            validator: (v) => v == null || v.trim().isEmpty ? 'Veuillez saisir votre matricule' : null,
                          ),
                          const SizedBox(height: 24),

                          // Login Button
                          ElevatedButton(
                            onPressed: _isLoading ? null : _handleLogin,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              backgroundColor: const Color(0xFF2563EB),
                              foregroundColor: Colors.white,
                              elevation: 4,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                  )
                                : const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.login_rounded, size: 20),
                                      SizedBox(width: 10),
                                      Text(
                                        'Se Connecter à ZKBioTime',
                                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                                      ),
                                    ],
                                  ),
                          ),
                          const SizedBox(height: 16),

                          // 100% Read-Only Safety badge
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.security_rounded, size: 16, color: Color(0xFF10B981)),
                                SizedBox(width: 8),
                                Text(
                                  'Sécurité Garantie : Mode 100% Lecture Seule',
                                  style: TextStyle(
                                    color: Color(0xFF10B981),
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
