import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Premium Palette
  static const Color primaryPurple = Color(0xFF6366F1); // Indigo 500 (Royal Blue-ish)
  static const Color primaryViolet = Color(0xFF818CF8); // Indigo 400
  static const Color accentPink = Color(0xFFF472B6); // Soft Pink (complementary)
  static const Color accentCyan = Color(0xFF22D3EE); // Cyan 400
  static const Color accentTeal = Color(0xFF2DD4BF); // Teal 400
  static const Color warmOrange = Color(0xFFFBBF24); // Amber 400 (Gold)
  static const Color successGreen = Color(0xFF34D399); // Emerald 400
  static const Color errorRed = Color(0xFFF87171); // Red 400

  // Stronger/Darker versions for text (Better contrast on light backgrounds)
  static const Color strongGreen = Color(0xFF059669); // Emerald 600
  static const Color strongPink = Color(0xFFDB2777); // Pink 600
  static const Color strongCyan = Color(0xFF0891B2); // Cyan 600
  static const Color strongOrange = Color(0xFFD97706); // Amber 600
  
  // Light mode surfaces (Premium Slate/White)
  static const Color lightBackground = Color(0xFFF8FAFC); // Slate 50
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceVariant = Color(0xFFF1F5F9); // Slate 100
  
  // Dark mode surfaces (Rich Night)
  static const Color darkBackground = Color(0xFF000000); // Pure Black
  static const Color darkSurface = Color(0xFF0A0A0A); // Almost Black
  static const Color darkSurfaceVariant = Color(0xFF334155); // Slate 700

  // Glass/Translucent
  static final Color glassLight = Colors.white.withOpacity(0.90);
  static final Color glassDark = const Color(0xFF1E293B).withOpacity(0.90);
  static final Color glassBorderLight = Colors.white.withOpacity(0.5);
  static final Color glassBorderDark = Colors.white.withOpacity(0.1);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)], // Indigo to Violet
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient heroGradient = LinearGradient(
    colors: [
      Color(0xFF4F46E5), // Indigo 600
      Color(0xFF7C3AED), // Violet 600
      Color(0xFFDB2777), // Pink 600
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [accentCyan, accentTeal],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class SciFiColors {
  static const Color background = Color(0xFF050510); // Deep Space Black
  static const Color surface = Color(0xFF101020); // Dark Cyber Blue
  static const Color cyan = Color(0xFF00F0FF); // Neon Cyan
  static const Color purple = Color(0xFFBD00FF); // Neon Purple
  static const Color green = Color(0xFF00FF9D); // Neon Green
  static const Color yellow = Color(0xFFFEE801); // Cyber Yellow
  static const Color warning = Color(0xFFFF5F5F); // Holo Red for errors

  static const LinearGradient cyberGradient = LinearGradient(
    colors: [cyan, purple],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient matrixGradient = LinearGradient(
    colors: [background, surface],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.light(
        primary: AppColors.primaryPurple,
        secondary: AppColors.accentCyan,
        tertiary: AppColors.accentPink,
        surface: AppColors.lightSurface,
        surfaceContainerHighest: AppColors.lightSurfaceVariant,
        error: AppColors.errorRed,
      ),
      scaffoldBackgroundColor: AppColors.lightBackground,
      textTheme: GoogleFonts.interTextTheme().copyWith(
        titleMedium: GoogleFonts.inter(
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.lightBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: AppColors.primaryPurple,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.lightSurface,
        indicatorColor: AppColors.primaryPurple.withOpacity(0.15),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: AppColors.primaryPurple, size: 26);
          }
          return IconThemeData(color: Colors.grey.shade600, size: 24);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryPurple,
            );
          }
          return GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade600);
        }),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primaryPurple,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        color: AppColors.lightSurface,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.lightSurfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.primaryPurple, width: 2),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.dark(
        primary: AppColors.primaryViolet,
        secondary: AppColors.accentCyan,
        tertiary: AppColors.accentPink,
        surface: AppColors.darkSurface,
        surfaceContainerHighest: AppColors.darkSurfaceVariant,
        error: AppColors.errorRed,
      ),
      scaffoldBackgroundColor: AppColors.darkBackground,
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
        titleMedium: GoogleFonts.inter(
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.darkBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: AppColors.primaryViolet,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.darkSurface,
        indicatorColor: AppColors.primaryViolet.withOpacity(0.2),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: AppColors.primaryViolet, size: 26);
          }
          return IconThemeData(color: Colors.grey.shade400, size: 24);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryViolet,
            );
          }
          return GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade400);
        }),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primaryViolet,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: AppColors.darkSurface,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkSurfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.primaryViolet, width: 2),
        ),
      ),
    );
  }

  static ThemeData get sciFiTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: SciFiColors.cyan,
        secondary: SciFiColors.purple,
        tertiary: SciFiColors.green,
        surface: SciFiColors.surface,
        error: SciFiColors.warning,
        onSurface: Colors.white,
      ),
      scaffoldBackgroundColor: SciFiColors.background,
      textTheme: GoogleFonts.orbitronTextTheme(ThemeData.dark().textTheme).apply(
        bodyColor: Colors.white,
        displayColor: SciFiColors.cyan,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: SciFiColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: GoogleFonts.orbitron(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: SciFiColors.cyan,
          letterSpacing: 2.0,
        ),
      ),
      iconTheme: const IconThemeData(color: SciFiColors.cyan),
    );
  }
}
