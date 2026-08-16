import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'services/hive_service.dart';
import 'providers/app_provider.dart';
import 'providers/attendance_provider.dart';
import 'providers/payroll_provider.dart';
import 'providers/transaction_provider.dart';
import 'providers/team_provider.dart';
import 'services/notification_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'screens/auth/biotime_login_screen.dart';
import 'screens/home/main_menu_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveService.init();
  await initializeDateFormatting();
  await NotificationService.init();
  await NotificationService.configureFromSavedProfile();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppProvider()),
        ChangeNotifierProvider(create: (_) => AttendanceProvider()),
        ChangeNotifierProvider(create: (_) => PayrollProvider()),
        ChangeNotifierProvider(create: (_) => TransactionProvider()),
        ChangeNotifierProvider(create: (_) => TeamProvider()),
      ],
      child: const ShiftTrackApp(),
    ),
  );
}

class ShiftTrackApp extends StatelessWidget {
  const ShiftTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        final platformBrightness =
            WidgetsBinding.instance.platformDispatcher.platformBrightness;
        final isDark =
            appProvider.currentTheme == 'dark' ||
            (appProvider.currentTheme == 'system' &&
                platformBrightness == Brightness.dark);

        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: isDark
                ? Brightness.light
                : Brightness.dark,
            statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
          ),
          child: MaterialApp(
            title: 'ShiftTrack BIO Connect',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.getTheme(appProvider.currentTheme),
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('fr')],
            locale: const Locale('fr'),
            home: appProvider.isLoggedIn
                ? const MainMenuScreen()
                : const BioTimeLoginScreen(),
          ),
        );
      },
    );
  }
}
