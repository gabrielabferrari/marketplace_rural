import 'package:flutter/material.dart';

/// Paleta institucional do Marketplace Rural.
///
/// Os nomes descrevem o papel da cor, não o tom exato, para que o tema
/// possa evoluir sem renomear todo o código.
abstract final class AppColors {
  // Verdes
  static const forest = Color(0xFF1E4D2B); // verde-escuro institucional
  static const green = Color(0xFF2F7A3A); // verde natural (ações)
  static const greenLight = Color(0xFF8BBF5C); // verde-claro (indicadores)
  static const greenSoft = Color(0xFFE8F2E1); // fundo de destaque suave

  // Terra
  static const brown = Color(0xFF7A5534);
  static const brownLight = Color(0xFFB8956A);

  // Superfícies claras
  static const white = Color(0xFFFFFFFF);
  static const offWhite = Color(0xFFFAF8F4);
  static const beige = Color(0xFFF3EDE2);
  static const border = Color(0xFFE7E1D6);

  // Texto (modo claro)
  static const ink = Color(0xFF1B2A20);
  static const muted = Color(0xFF66736A);

  // Modo escuro (grafite esverdeado)
  static const darkBackground = Color(0xFF0F1813);
  static const darkSurface = Color(0xFF16221B);
  static const darkCard = Color(0xFF1C2B22);
  static const darkBorder = Color(0xFF2B3D32);
  static const darkInk = Color(0xFFE7EFE9);
  static const darkMuted = Color(0xFFA2B2A7);
  static const darkGreen = Color(0xFF6FBF73);

  // Semânticas
  static const danger = Color(0xFFC0392B);
  static const warning = Color(0xFFD68A1A);
  static const info = Color(0xFF2D6A9F);
}

/// Cores semânticas extras que acompanham o tema (claro/escuro).
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.muted,
    required this.border,
    required this.softSurface,
    required this.accentSoft,
    required this.earth,
    required this.success,
    required this.warning,
    required this.danger,
    required this.info,
  });

  final Color muted;
  final Color border;
  final Color softSurface;
  final Color accentSoft;
  final Color earth;
  final Color success;
  final Color warning;
  final Color danger;
  final Color info;

  static const light = AppPalette(
    muted: AppColors.muted,
    border: AppColors.border,
    softSurface: AppColors.offWhite,
    accentSoft: AppColors.greenSoft,
    earth: AppColors.brown,
    success: AppColors.green,
    warning: AppColors.warning,
    danger: AppColors.danger,
    info: AppColors.info,
  );

  static const dark = AppPalette(
    muted: AppColors.darkMuted,
    border: AppColors.darkBorder,
    softSurface: AppColors.darkSurface,
    accentSoft: Color(0xFF213A2A),
    earth: AppColors.brownLight,
    success: AppColors.darkGreen,
    warning: Color(0xFFE8A93A),
    danger: Color(0xFFE5675A),
    info: Color(0xFF6FA8DC),
  );

  @override
  AppPalette copyWith({
    Color? muted,
    Color? border,
    Color? softSurface,
    Color? accentSoft,
    Color? earth,
    Color? success,
    Color? warning,
    Color? danger,
    Color? info,
  }) {
    return AppPalette(
      muted: muted ?? this.muted,
      border: border ?? this.border,
      softSurface: softSurface ?? this.softSurface,
      accentSoft: accentSoft ?? this.accentSoft,
      earth: earth ?? this.earth,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      danger: danger ?? this.danger,
      info: info ?? this.info,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      muted: Color.lerp(muted, other.muted, t)!,
      border: Color.lerp(border, other.border, t)!,
      softSurface: Color.lerp(softSurface, other.softSurface, t)!,
      accentSoft: Color.lerp(accentSoft, other.accentSoft, t)!,
      earth: Color.lerp(earth, other.earth, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      info: Color.lerp(info, other.info, t)!,
    );
  }
}

extension AppThemeContext on BuildContext {
  ThemeData get theme => Theme.of(this);
  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme get text => Theme.of(this).textTheme;
  AppPalette get palette => Theme.of(this).extension<AppPalette>()!;
}
