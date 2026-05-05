import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppColors {
  static const bg = Color(0xFF080a08);
  static const surface = Color(0xFF111411);
  static const surface2 = Color(0xFF181c18);
  static const border = Color(0xFF2a2f2a);
  static const accent = Color(0xFFc8f000);
  static const accent2 = Color(0xFFff6b00);
  static const red = Color(0xFFff2a2a);
  static const text = Color(0xFFd4e0c8);
  static const textDim = Color(0xFF5a6a54);
  static const padEmpty = Color(0xFF131613);
  static const padLoaded = Color(0xFF1a2018);
  static const padPlaying = Color(0xFF1f2a10);
}

class AppTheme {
  static ThemeData get dark {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.bg,
      colorScheme: const ColorScheme.dark(
        surface: AppColors.surface,
        primary: AppColors.accent,
        secondary: AppColors.accent2,
        error: AppColors.red,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.bg,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarBrightness: Brightness.dark,
          statusBarIconBrightness: Brightness.light,
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: AppColors.accent,
        inactiveTrackColor: AppColors.border,
        thumbColor: AppColors.accent,
        overlayColor: AppColors.accent.withAlpha(40),
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
        trackHeight: 2,
        trackShape: const RectangularSliderTrackShape(),
      ),
      textTheme: const TextTheme(
        bodyMedium: TextStyle(
          color: AppColors.text,
          fontFamily: 'monospace',
          letterSpacing: 0.5,
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
      ),
    );
  }
}
