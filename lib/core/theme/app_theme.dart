import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

class AppTheme {
  static ThemeData getTheme(String themeMode) {
    switch (themeMode) {
      case 'system':
        return WidgetsBinding.instance.platformDispatcher.platformBrightness ==
                Brightness.dark
            ? _darkTheme()
            : _lightTheme();
      case 'light':
        return _lightTheme();
      case 'onyx':
        return _onyxTheme();
      case 'dark':
      default:
        return _darkTheme();
    }
  }

  // ── LIGHT THEME ─────────────────────────────
  static ThemeData _lightTheme() => _base(
    brightness: Brightness.light,
    bg: const Color(0xFFF8FBFA),
    card: AppColors.lightCard,
    text: AppColors.slate800,
    subText: AppColors.slate500,
    border: AppColors.slate200,
  );

  // ── DARK THEME (Navy) ───────────────────────
  static ThemeData _darkTheme() => _base(
    brightness: Brightness.dark,
    bg: const Color(0xFF0A1118),
    card: AppColors.darkCard,
    text: const Color(0xFFF1F5F9),
    subText: AppColors.slate400,
    border: AppColors.slate700,
  );

  // ── ONYX THEME ──────────────────────────────
  static ThemeData _onyxTheme() => _base(
    brightness: Brightness.dark,
    bg: AppColors.onyxBg,
    card: AppColors.onyxCard,
    text: const Color(0xFFF1F5F9),
    subText: AppColors.slate400,
    border: const Color(0xFF262626),
  );

  // ── BASE BUILDER ────────────────────────────
  static ThemeData _base({
    required Brightness brightness,
    required Color bg,
    required Color card,
    required Color text,
    required Color subText,
    required Color border,
  }) {
    final isDark = brightness == Brightness.dark;

    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: AppColors.brandTeal,
      onPrimary: Colors.white,
      primaryContainer: isDark ? AppColors.teal700 : AppColors.teal100,
      onPrimaryContainer: isDark ? AppColors.teal100 : AppColors.teal700,
      secondary: AppColors.brandBlue,
      onSecondary: Colors.white,
      secondaryContainer: isDark ? AppColors.blue800 : AppColors.blue100,
      onSecondaryContainer: isDark ? AppColors.blue200 : AppColors.blue800,
      tertiary: AppColors.brandViolet,
      onTertiary: Colors.white,
      error: AppColors.errorRed,
      onError: Colors.white,
      surface: bg,
      onSurface: text,
      surfaceContainerHighest: card,
      outline: border,
      outlineVariant: border.withValues(alpha: 0.5),
      shadow: isDark ? Colors.black : Colors.black.withValues(alpha: 0.08),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: bg,
      colorScheme: colorScheme,
      cardColor: card,
      dividerColor: border,
      textTheme: GoogleFonts.cairoTextTheme().apply(
        bodyColor: text,
        displayColor: text,
      ),

      // ── App Bar ──
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
        iconTheme: IconThemeData(color: text),
        titleTextStyle: GoogleFonts.cairo(
          color: text,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
      ),

      // ── Cards ──
      cardTheme: CardThemeData(
        color: card,
        elevation: isDark ? 0 : 2,
        shadowColor: isDark
            ? Colors.transparent
            : Colors.black.withValues(alpha: 0.06),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: border, width: isDark ? 1 : 0.5),
        ),
      ),

      // ── FAB ──
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.brandTeal,
        foregroundColor: Colors.white,
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),

      // ── Elevated Button ──
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.brandTeal,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          textStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ── Input Decoration ──
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? card : AppColors.slate50,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.brandTeal, width: 2),
        ),
        hintStyle: TextStyle(color: subText),
        prefixIconColor: subText,
      ),

      // ── Bottom Sheet ──
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: card,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),

      // ── Dialog ──
      dialogTheme: DialogThemeData(
        backgroundColor: card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),

      // ── SnackBar ──
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? AppColors.slate700 : AppColors.slate800,
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        behavior: SnackBarBehavior.floating,
      ),

      // ── Switch ──
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.brandTeal;
          }
          return subText;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.brandTeal.withValues(alpha: 0.3);
          }
          return border;
        }),
      ),

      // ── ListTile ──
      listTileTheme: ListTileThemeData(textColor: text, iconColor: subText),

      iconTheme: IconThemeData(color: text),

      // ── Time Picker ──
      timePickerTheme: TimePickerThemeData(
        backgroundColor: card,
        hourMinuteColor: isDark ? bg : AppColors.slate100,
        hourMinuteTextColor: text,
        dialBackgroundColor: isDark ? bg : AppColors.slate100,
        dialHandColor: AppColors.brandTeal,
        dialTextColor: text,
        entryModeIconColor: subText,
      ),

      // ── Date Picker ──
      datePickerTheme: DatePickerThemeData(
        backgroundColor: card,
        surfaceTintColor: Colors.transparent,
        headerBackgroundColor: AppColors.brandTeal,
        headerForegroundColor: Colors.white,
      ),
    );
  }
}
