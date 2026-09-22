import 'package:flutter/material.dart';

/// Climavent brend palitrasi (brend qo'llanmasi, 17.09.2026).
abstract final class Brand {
  static const navy = Color(0xFF002854); // To'q ko'k — asosiy
  static const sky = Color(0xFF55CDF8); // Moviy — urg'u, qorong'i fonda
  static const mist = Color(0xFFB3E0FE); // Osmon — yumshoq fon
  static const flame = Color(0xFFFF1918); // Olovrang — xato, aksiya
  static const link = Color(0xFF0770A8); // Oq fonda matn/havola (moviy kontrasti past)
  static const success = Color(0xFF12A150);
}

/// O'lchamlar — hamma ekranda bir xil ritm.
abstract final class Space {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;
  static const gutter = 20.0; // ekran chetidan
}

abstract final class Radii {
  static const sm = 10.0;
  static const md = 14.0;
  static const lg = 20.0;
  static const xl = 28.0;
}

/// Mavzuga bog'liq qo'shimcha ranglar (ThemeExtension).
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.background,
    required this.surface,
    required this.surfaceMuted,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.accent,
    required this.onAccent,
    required this.danger,
    required this.success,
  });

  final Color background;
  final Color surface;
  final Color surfaceMuted;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color accent;
  final Color onAccent;
  final Color danger;
  final Color success;

  static const light = AppColors(
    background: Color(0xFFF4F6FA),
    surface: Colors.white,
    surfaceMuted: Color(0xFFEEF2F7),
    border: Color(0xFFDDE3EC),
    textPrimary: Color(0xFF0B1B33),
    textSecondary: Color(0xFF5B6B82),
    textTertiary: Color(0xFF94A1B5),
    accent: Brand.navy,
    onAccent: Colors.white,
    danger: Color(0xFFE5251F),
    success: Brand.success,
  );

  static const dark = AppColors(
    background: Color(0xFF070F1D),
    surface: Color(0xFF0F1A2C),
    surfaceMuted: Color(0xFF16243A),
    border: Color(0xFF22324B),
    textPrimary: Color(0xFFEFF4FA),
    textSecondary: Color(0xFF9EB0C8),
    textTertiary: Color(0xFF6B7D96),
    accent: Brand.sky,
    onAccent: Brand.navy,
    danger: Color(0xFFFF5A55),
    success: Color(0xFF3DD68C),
  );

  @override
  AppColors copyWith() => this;

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppColors(
      background: l(background, other.background),
      surface: l(surface, other.surface),
      surfaceMuted: l(surfaceMuted, other.surfaceMuted),
      border: l(border, other.border),
      textPrimary: l(textPrimary, other.textPrimary),
      textSecondary: l(textSecondary, other.textSecondary),
      textTertiary: l(textTertiary, other.textTertiary),
      accent: l(accent, other.accent),
      onAccent: l(onAccent, other.onAccent),
      danger: l(danger, other.danger),
      success: l(success, other.success),
    );
  }
}

extension AppColorsX on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
  TextTheme get text => Theme.of(this).textTheme;
}
