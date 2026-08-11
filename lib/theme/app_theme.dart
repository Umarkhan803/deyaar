import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const navy = Color(0xFF002147);
  static const navyDeep = Color(0xFF001122);
  static const navySoft = Color(0xFF001133);
  static const primaryBlue = Color(0xFF6699FF);
  static const accentBlue = Color(0xFF2563EB);
  static const cyan = Color(0xFF5EC8F0);
  static const sky = Color(0xFFE6F0FA);
  static const skySoft = Color(0xFFD5E3FC);
  static const mist = Color(0xFFF7F9FB);
  static const surface = Color(0xFFFFFFFF);
  static const slate = Color(0xFF515F74);
  static const muted = Color(0xFF909BB1);
  static const border = Color(0xFFE0E3E5);
  static const success = Color(0xFF059669);
  static const successSoft = Color(0xFFECFDF5);
  static const danger = Color(0xFFDC2626);
  static const dangerSoft = Color(0xFFFEE2E2);
  static const warning = Color(0xFFD97706);
  static const warningSoft = Color(0xFFFEF3C7);
  static const amber = Color(0xFFD97706);
  static const charcoal = navy;
  static const charcoalSoft = Color(0xFF283345);

  // Dark palette (screenshot match)
  static const darkBg = Color(0xFF0B0F14);
  static const darkSurface = Color(0xFF151A22);
  static const darkCard = Color(0xFF1B2230);
  static const darkBorder = Color(0xFF2A3344);
  static const darkMuted = Color(0xFF8B95A8);
  static const darkText = Color(0xFFF2F5FA);

  /// Primary body/title text: white in dark mode, navy in light mode.
  static Color text(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return dark ? darkText : navyDeep;
  }

  /// Secondary / muted text that stays readable on both themes.
  static Color textMuted(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return dark ? darkMuted : slate;
  }

  static Color icon(BuildContext context) => text(context);
}

class AppTheme {
  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.navy,
        primary: AppColors.navy,
        onPrimary: Colors.white,
        primaryContainer: AppColors.sky,
        onPrimaryContainer: AppColors.navyDeep,
        secondary: AppColors.primaryBlue,
        onSecondary: Colors.white,
        secondaryContainer: AppColors.skySoft,
        surface: AppColors.surface,
        onSurface: AppColors.navyDeep,
        onSurfaceVariant: AppColors.slate,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: AppColors.mist,
    );
    return _applyCommon(
      base,
      appBarBg: AppColors.mist,
      appBarFg: AppColors.navy,
      cardColor: Colors.white,
      cardBorder: AppColors.border,
      inputFill: Colors.white,
      inputBorder: AppColors.border,
      fabBg: AppColors.primaryBlue,
      navBg: Colors.white,
      navIndicator: AppColors.sky,
      selected: AppColors.navy,
      unselected: AppColors.muted,
      elevatedBg: AppColors.primaryBlue,
      bodyColor: AppColors.navyDeep,
    );
  }

  static ThemeData dark() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primaryBlue,
        onPrimary: Colors.white,
        primaryContainer: AppColors.navySoft,
        onPrimaryContainer: AppColors.darkText,
        secondary: AppColors.cyan,
        onSecondary: AppColors.navyDeep,
        surface: AppColors.darkSurface,
        onSurface: AppColors.darkText,
        onSurfaceVariant: AppColors.darkMuted,
        error: AppColors.danger,
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: AppColors.darkBg,
    );
    return _applyCommon(
      base,
      appBarBg: AppColors.darkBg,
      appBarFg: AppColors.darkText,
      cardColor: AppColors.darkCard,
      cardBorder: AppColors.darkBorder,
      inputFill: AppColors.darkSurface,
      inputBorder: AppColors.darkBorder,
      fabBg: AppColors.primaryBlue,
      navBg: AppColors.darkSurface,
      navIndicator: AppColors.navySoft,
      selected: AppColors.primaryBlue,
      unselected: AppColors.darkMuted,
      elevatedBg: AppColors.primaryBlue,
      bodyColor: AppColors.darkText,
    );
  }

  static ThemeData _applyCommon(
    ThemeData base, {
    required Color appBarBg,
    required Color appBarFg,
    required Color cardColor,
    required Color cardBorder,
    required Color inputFill,
    required Color inputBorder,
    required Color fabBg,
    required Color navBg,
    required Color navIndicator,
    required Color selected,
    required Color unselected,
    required Color elevatedBg,
    required Color bodyColor,
  }) {
    return base.copyWith(
      textTheme: GoogleFonts.plusJakartaSansTextTheme(base.textTheme).apply(
        bodyColor: bodyColor,
        displayColor: bodyColor,
      ),
      primaryTextTheme:
          GoogleFonts.plusJakartaSansTextTheme(base.primaryTextTheme).apply(
        bodyColor: bodyColor,
        displayColor: bodyColor,
      ),
      iconTheme: IconThemeData(color: bodyColor),
      primaryIconTheme: IconThemeData(color: appBarFg),
      hintColor: unselected,
      listTileTheme: ListTileThemeData(
        textColor: bodyColor,
        iconColor: bodyColor,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: bodyColor,
        ),
        subtitleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          color: unselected,
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: selected,
        unselectedLabelColor: unselected,
        indicatorColor: selected,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: appBarBg,
        foregroundColor: appBarFg,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: appBarFg,
        ),
        iconTheme: IconThemeData(color: appBarFg),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: fabBg,
        foregroundColor: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 0,
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: cardBorder),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputFill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: inputBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: inputBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primaryBlue, width: 2),
        ),
        labelStyle: GoogleFonts.plusJakartaSans(color: unselected),
        hintStyle: GoogleFonts.plusJakartaSans(color: unselected),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: elevatedBg,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: selected,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          side: BorderSide(color: cardBorder),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: navBg,
        indicatorColor: navIndicator,
        elevation: 0,
        height: 68,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final sel = states.contains(WidgetState.selected);
          return GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
            color: sel ? selected : unselected,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final sel = states.contains(WidgetState.selected);
          return IconThemeData(color: sel ? selected : unselected, size: 22);
        }),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: cardColor,
        selectedColor: AppColors.primaryBlue.withValues(alpha: 0.25),
        labelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          color: bodyColor,
        ),
        secondaryLabelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          color: bodyColor,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        side: BorderSide(color: cardBorder),
      ),
      dividerColor: cardBorder,
      dialogTheme: DialogThemeData(
        backgroundColor: cardColor,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: bodyColor,
        ),
        contentTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          color: bodyColor,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: cardColor,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
    );
  }

  static ThemeMode themeModeFromString(String? value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  static String themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }
}
