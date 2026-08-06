import 'package:flutter/material.dart';
import 'package:nwt_app/constants/colors.dart';

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.lightBackground,
    primaryColor: AppColors.lightPrimary,
    fontFamily: 'Montserrat',

    colorScheme: ColorScheme.light(
      primary: AppColors.lightPrimary,
      secondary: AppColors.lightSecondary,
      surface: AppColors.lightBackground,
      onSurface: AppColors.lightTextPrimary,
      onPrimary: AppColors.lightButtonPrimaryText,
    ),

    appBarTheme: const AppBarTheme(
      surfaceTintColor: Colors.transparent,
      backgroundColor: AppColors.lightBackground,
      foregroundColor: AppColors.lightTextPrimary,
      elevation: 0,
      iconTheme: IconThemeData(color: AppColors.lightTextPrimary),
      titleTextStyle: TextStyle(
        color: AppColors.lightTextPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        fontFamily: "Montserrat"
      ),
    ),

    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: AppColors.lightPrimary,
      selectionColor: Color(0x1F000000),
      selectionHandleColor: Color(0x8A000000),
    ),

    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: AppColors.lightTextPrimary),
      bodyMedium: TextStyle(color: AppColors.lightTextSecondary),
      bodySmall: TextStyle(color: AppColors.lightTextTertiary),
    ),

    inputDecorationTheme: InputDecorationTheme(
      fillColor: AppColors.lightInputPrimaryBackground,
      filled: true,
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      border: OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(15)),
        borderSide: BorderSide(color: AppColors.lightInputPrimaryBorder, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(15)),
        borderSide: BorderSide(color: AppColors.lightInputPrimaryBorder, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(15)),
        borderSide: BorderSide(color: AppColors.lightPrimary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(15)),
        borderSide: BorderSide(color: Colors.red, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(15)),
        borderSide: BorderSide(color: Colors.red, width: 1.5),
      ),
      hintStyle: const TextStyle(color: AppColors.lightInputPrimaryText, fontSize: 14, fontWeight: FontWeight.w400),
      errorStyle: const TextStyle(color: Colors.red, fontSize: 12),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.lightButtonPrimaryBackground,
        foregroundColor: AppColors.lightButtonPrimaryText,
        side: const BorderSide(color: AppColors.lightButtonPrimaryBorder),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      ),
    ),
    
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.darkBackground,
      disabledColor: AppColors.darkBackground,
      selectedColor: AppColors.darkBackground,
      secondarySelectedColor: AppColors.darkBackground,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      labelStyle: const TextStyle(
        color: AppColors.darkTextPrimary,
        fontFamily: 'Montserrat',
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      secondaryLabelStyle: const TextStyle(
        color: AppColors.darkTextPrimary,
        fontFamily: 'Montserrat',
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      brightness: Brightness.dark,
      checkmarkColor: Colors.transparent,
      showCheckmark: false,
      selectedShadowColor: Colors.transparent,
      side: const BorderSide(color: AppColors.darkButtonBorder),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: AppColors.darkButtonBorder),
      ),
    ),
    
    iconButtonTheme: IconButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.all(AppColors.lightBackground),
        iconColor: WidgetStateProperty.all(AppColors.lightTextSecondary),
        padding: WidgetStateProperty.all(const EdgeInsets.all(10)),
        side: WidgetStateProperty.resolveWith((states) {
          return const BorderSide(color: AppColors.lightButtonBorder, width: 1);
        }),
        shape: WidgetStateProperty.all(RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        )),
      ),
    ),

    extensions: <ThemeExtension<dynamic>>[AppTextThemeColors.light],
  );

  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.darkBackground,
    primaryColor: AppColors.darkPrimary,
    fontFamily: 'Montserrat',
    colorScheme: ColorScheme.dark(
      primary: AppColors.darkPrimary,
      surface: AppColors.darkBackground,
      onSurface: AppColors.darkTextPrimary,
      onPrimary: AppColors.darkButtonPrimaryText,
    ),

    appBarTheme: const AppBarTheme(
          surfaceTintColor: Colors.transparent,
      backgroundColor: AppColors.darkBackground,
      foregroundColor: AppColors.darkTextPrimary,
      elevation: 0,
      iconTheme: IconThemeData(color: AppColors.darkTextPrimary),
      titleTextStyle: TextStyle(
        color: AppColors.darkTextPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        fontFamily: "Montserrat"
      ),
    ),

    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: Colors.white,
      selectionColor: Colors.white24,
      selectionHandleColor: Colors.white70,
    ),

    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: AppColors.darkTextPrimary),
      bodyMedium: TextStyle(color: AppColors.darkTextSecondary),
      bodySmall: TextStyle(color: AppColors.darkTextTertiary),
    ),

    inputDecorationTheme: InputDecorationTheme(
      fillColor: AppColors.darkInputBackground,
      filled: true,
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      border: OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(15)),
        borderSide: BorderSide(color: AppColors.darkInputBorder, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(15)),
        borderSide: BorderSide(color: AppColors.darkInputBorder, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(15)),
        borderSide: BorderSide(color: AppColors.darkPrimary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(15)),
        borderSide: BorderSide(color: Colors.redAccent, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(15)),
        borderSide: BorderSide(color: Colors.redAccent, width: 1.5),
      ),
      hintStyle: const TextStyle(color: AppColors.darkInputHintText, fontSize: 14, fontWeight: FontWeight.w400),
      errorStyle: const TextStyle(color: Colors.redAccent, fontSize: 12),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.darkButtonPrimaryBackground,
        foregroundColor: AppColors.darkButtonPrimaryText,
        side: const BorderSide(color: AppColors.darkButtonPrimaryBorder),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      ),
    ),
    
    iconButtonTheme: IconButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.all(AppColors.darkRoundedButtonBackground),
        iconColor: WidgetStateProperty.all(AppColors.darkTextGray),
        padding: WidgetStateProperty.all(const EdgeInsets.all(10)),
        side: WidgetStateProperty.resolveWith((states) {
          return const BorderSide(color: AppColors.darkButtonBorder, width: 1);
        }),
        shape: WidgetStateProperty.all(RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        )),
      ),
    ),

    // Chip Theme
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.darkButtonBorder,
      disabledColor: AppColors.darkButtonBorder.withValues(alpha: 0.5),
      selectedColor: AppColors.darkButtonBorder,
      secondarySelectedColor: AppColors.darkButtonBorder,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      labelStyle: const TextStyle(
        color: AppColors.darkTextPrimary,
        fontFamily: 'Montserrat',
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      secondaryLabelStyle: const TextStyle(
        color: AppColors.darkTextPrimary,
        fontFamily: 'Montserrat',
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      brightness: Brightness.dark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: AppColors.darkButtonBorder),
      ),
    ),
    
    // Add extension data to store our custom text colors
    extensions: <ThemeExtension<dynamic>>[AppTextThemeColors.dark],
  );

  static ThemeData datePickerTheme(bool isDarkMode) {
    return ThemeData(
      colorScheme: isDarkMode
          ? const ColorScheme.dark(
              primary: Color(0xFFFFFFFF),
              onPrimary: Color(0xFF000000),
              surface: Color(0xFF0C0C0C),
              onSurface: Color(0xFFFFFFFF),
            )
          : const ColorScheme.light(
              primary: Color(0xFF000000),
              onPrimary: Color(0xFFFFFFFF),
              surface: Color(0xFFFFFFFF),
              onSurface: Color(0xFF000000),
            ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: isDarkMode ? Colors.white : Colors.black,
        ),
      ), dialogTheme: DialogThemeData(backgroundColor: isDarkMode ? const Color(0xFF0C0C0C) : Colors.white),
    );
  }
}

// Theme extension to properly handle text colors in theme changes
class AppTextThemeColors extends ThemeExtension<AppTextThemeColors> {
  final Color primaryText;
  final Color secondaryText;
  final Color tertiaryText;
  final Color mutedText;
  final Color grayText;
  final Color buttonText;

  const AppTextThemeColors({
    required this.primaryText,
    required this.secondaryText,
    required this.tertiaryText,
    required this.mutedText,
    required this.grayText,
    required this.buttonText,
  });

  // Light theme text colors
  static const light = AppTextThemeColors(
    primaryText: AppColors.lightTextPrimary,
    secondaryText: AppColors.lightTextSecondary,
    tertiaryText: AppColors.lightTextTertiary,
    mutedText: AppColors.lightTextMuted,
    grayText: AppColors.lightTextGray,
    buttonText: AppColors.lightButtonPrimaryText,
  );

  // Dark theme text colors
  static const dark = AppTextThemeColors(
    primaryText: AppColors.darkTextPrimary,
    secondaryText: AppColors.darkTextSecondary,
    tertiaryText: AppColors.lightTextTertiary,
    mutedText: AppColors.darkTextMuted,
    grayText: AppColors.darkTextGray,
    buttonText: AppColors.darkButtonPrimaryText,
  );

  @override
  ThemeExtension<AppTextThemeColors> copyWith({
    Color? primaryText,
    Color? secondaryText,
    Color? tertiaryText,
    Color? mutedText,
    Color? grayText,
    Color? buttonText,
  }) {
    return AppTextThemeColors(
      primaryText: primaryText ?? this.primaryText,
      secondaryText: secondaryText ?? this.secondaryText,
      tertiaryText: tertiaryText ?? this.tertiaryText,
      mutedText: mutedText ?? this.mutedText,
      grayText: grayText ?? this.grayText,
      buttonText: buttonText ?? this.buttonText,
    );
  }

  @override
  ThemeExtension<AppTextThemeColors> lerp(
    covariant ThemeExtension<AppTextThemeColors>? other,
    double t,
  ) {
    if (other is! AppTextThemeColors) {
      return this;
    }
    return AppTextThemeColors(
      primaryText: Color.lerp(primaryText, other.primaryText, t)!,
      secondaryText: Color.lerp(secondaryText, other.secondaryText, t)!,
      tertiaryText: Color.lerp(tertiaryText, other.tertiaryText, t)!,
      mutedText: Color.lerp(mutedText, other.mutedText, t)!,
      grayText: Color.lerp(grayText, other.grayText, t)!,
      buttonText: Color.lerp(buttonText, other.buttonText, t)!,
    );
  }
}

// Helper extension to get theme colors
extension AppTextThemeColorsExtension on BuildContext {
  AppTextThemeColors get textThemeColors =>
      Theme.of(this).extension<AppTextThemeColors>() ??
      AppTextThemeColors.dark;
}
