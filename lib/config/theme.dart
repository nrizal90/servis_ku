import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF1E3A5F);
  static const primaryLight = Color(0xFF2D5A8E);
  static const accent = Color(0xFF3B7DBD);
  static const background = Color(0xFFF5F7FA);
  static const card = Colors.white;
  static const textPrimary = Color(0xFF1E293B);
  static const textSecondary = Color(0xFF64748B);
  static const textHint = Color(0xFFB0BBCC);
  static const success = Color(0xFF22C55E);
  static const successLight = Color(0xFFDCFCE7);
  static const warning = Color(0xFFF59E0B);
  static const warningLight = Color(0xFFFEF3C7);
  static const danger = Color(0xFFEF4444);
  static const dangerLight = Color(0xFFFFEEEE);
  static const border = Color(0xFFEEF2F7);

  // Gradient presets
  static const gradientPrimary = LinearGradient(
    colors: [Color(0xFF2D5A8E), Color(0xFF1E3A5F)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const gradientMotor = LinearGradient(
    colors: [Color(0xFF3B7DBD), Color(0xFF1E3A5F)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const gradientCar = LinearGradient(
    colors: [Color(0xFF0891B2), Color(0xFF0E7490)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const gradientSuccess = LinearGradient(
    colors: [Color(0xFF4ADE80), Color(0xFF22C55E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class AppShadows {
  static List<BoxShadow> get card => [
        BoxShadow(
          color: const Color(0xFF1E3A5F).withValues(alpha: 0.07),
          blurRadius: 24,
          offset: const Offset(0, 6),
          spreadRadius: 0,
        ),
        BoxShadow(
          color: const Color(0xFF1E3A5F).withValues(alpha: 0.03),
          blurRadius: 6,
          offset: const Offset(0, 2),
          spreadRadius: 0,
        ),
      ];

  static List<BoxShadow> get button => [
        BoxShadow(
          color: const Color(0xFF1E3A5F).withValues(alpha: 0.25),
          blurRadius: 16,
          offset: const Offset(0, 6),
          spreadRadius: 0,
        ),
      ];

  static List<BoxShadow> get alert => [
        BoxShadow(
          color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
          blurRadius: 16,
          offset: const Offset(0, 4),
          spreadRadius: 0,
        ),
      ];
}

class AppTheme {
  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        surface: AppColors.background,
      ),
      scaffoldBackgroundColor: AppColors.background,
    );

    return base.copyWith(
      textTheme: base.textTheme
          .apply(
            fontFamily: 'PlusJakartaSans',
            bodyColor: AppColors.textPrimary,
            displayColor: AppColors.textPrimary,
          ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          fontFamily: 'PlusJakartaSans',
          color: Colors.white,
          fontSize: 17,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
        ),
        hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 14),
        labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(vertical: 15),
          textStyle: const TextStyle(
            fontFamily: 'PlusJakartaSans',
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
