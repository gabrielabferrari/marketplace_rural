import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';

import 'app_colors.dart';

abstract final class AppTheme {
  static const radius = 16.0;
  static const radiusSmall = 12.0;

  static ThemeData light() {
    const scheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.green,
      onPrimary: Colors.white,
      primaryContainer: AppColors.greenSoft,
      onPrimaryContainer: AppColors.forest,
      secondary: AppColors.forest,
      onSecondary: Colors.white,
      secondaryContainer: Color(0xFFDCEBD3),
      onSecondaryContainer: AppColors.forest,
      tertiary: AppColors.brown,
      onTertiary: Colors.white,
      tertiaryContainer: AppColors.beige,
      onTertiaryContainer: Color(0xFF4A321C),
      error: AppColors.danger,
      onError: Colors.white,
      errorContainer: Color(0xFFFBE4E1),
      onErrorContainer: Color(0xFF7A1D13),
      surface: AppColors.white,
      onSurface: AppColors.ink,
      onSurfaceVariant: AppColors.muted,
      surfaceContainerLowest: AppColors.white,
      surfaceContainerLow: AppColors.offWhite,
      surfaceContainer: AppColors.offWhite,
      surfaceContainerHigh: AppColors.beige,
      surfaceContainerHighest: Color(0xFFEDE6D9),
      outline: Color(0xFFCFC6B6),
      outlineVariant: AppColors.border,
      shadow: Colors.black,
      inverseSurface: AppColors.forest,
      onInverseSurface: Colors.white,
      inversePrimary: AppColors.greenLight,
    );
    return _build(scheme, AppPalette.light);
  }

  static ThemeData dark() {
    const scheme = ColorScheme(
      brightness: Brightness.dark,
      primary: AppColors.darkGreen,
      onPrimary: Color(0xFF07210E),
      primaryContainer: Color(0xFF24442E),
      onPrimaryContainer: Color(0xFFCDEBD0),
      secondary: Color(0xFF9CCB9F),
      onSecondary: Color(0xFF0B2312),
      secondaryContainer: Color(0xFF2A4433),
      onSecondaryContainer: Color(0xFFD5EBD7),
      tertiary: AppColors.brownLight,
      onTertiary: Color(0xFF2B1A08),
      tertiaryContainer: Color(0xFF3B2D1E),
      onTertiaryContainer: Color(0xFFF1DFC6),
      error: Color(0xFFE5675A),
      onError: Color(0xFF2D0602),
      errorContainer: Color(0xFF5A1D16),
      onErrorContainer: Color(0xFFFFDAD4),
      surface: AppColors.darkBackground,
      onSurface: AppColors.darkInk,
      onSurfaceVariant: AppColors.darkMuted,
      surfaceContainerLowest: Color(0xFF0B120E),
      surfaceContainerLow: AppColors.darkSurface,
      surfaceContainer: AppColors.darkCard,
      surfaceContainerHigh: Color(0xFF223429),
      surfaceContainerHighest: Color(0xFF2A3E31),
      outline: Color(0xFF4A5F51),
      outlineVariant: AppColors.darkBorder,
      shadow: Colors.black,
      inverseSurface: AppColors.darkInk,
      onInverseSurface: AppColors.darkBackground,
      inversePrimary: AppColors.green,
    );
    return _build(scheme, AppPalette.dark);
  }

  static ThemeData _build(ColorScheme scheme, AppPalette palette) {
    final isDark = scheme.brightness == Brightness.dark;
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      brightness: scheme.brightness,
    );
    final textTheme = base.textTheme
        .apply(bodyColor: scheme.onSurface, displayColor: scheme.onSurface)
        .copyWith(
          headlineMedium: base.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
              color: isDark ? scheme.onSurface : AppColors.forest),
          headlineSmall: base.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
              color: isDark ? scheme.onSurface : AppColors.forest),
          titleLarge: base.textTheme.titleLarge
              ?.copyWith(fontWeight: FontWeight.w700, color: scheme.onSurface),
          titleMedium: base.textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w600, color: scheme.onSurface),
          titleSmall: base.textTheme.titleSmall
              ?.copyWith(fontWeight: FontWeight.w600, color: scheme.onSurface),
          labelLarge: base.textTheme.labelLarge
              ?.copyWith(fontWeight: FontWeight.w600, letterSpacing: 0.1),
        );

    final cardColor = isDark ? AppColors.darkCard : AppColors.white;
    final roundedBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(radiusSmall),
      borderSide: BorderSide(color: palette.border),
    );

    return base.copyWith(
      scaffoldBackgroundColor: scheme.surface,
      textTheme: textTheme,
      extensions: [palette],
      splashFactory: InkSparkle.splashFactory,
      pageTransitionsTheme: const PageTransitionsTheme(builders: {
        TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
      }),
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge?.copyWith(fontSize: 20),
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
          side: BorderSide(color: palette.border),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: palette.border,
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? AppColors.darkSurface : AppColors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: TextStyle(color: palette.muted.withValues(alpha: 0.8)),
        border: roundedBorder,
        enabledBorder: roundedBorder,
        focusedBorder: roundedBorder.copyWith(
          borderSide: BorderSide(color: scheme.primary, width: 1.6),
        ),
        errorBorder: roundedBorder.copyWith(
          borderSide: BorderSide(color: scheme.error),
        ),
        focusedErrorBorder: roundedBorder.copyWith(
          borderSide: BorderSide(color: scheme.error, width: 1.6),
        ),
        prefixIconColor: palette.muted,
        suffixIconColor: palette.muted,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 50),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radiusSmall)),
          textStyle:
              const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 50),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          side: BorderSide(color: palette.border),
          foregroundColor: scheme.primary,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radiusSmall)),
          textStyle:
              const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: cardColor,
        selectedColor: scheme.primaryContainer,
        side: BorderSide(color: palette.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        labelStyle: TextStyle(color: scheme.onSurface, fontSize: 13),
        secondaryLabelStyle: TextStyle(
            color: scheme.onPrimaryContainer, fontWeight: FontWeight.w600),
        checkmarkColor: scheme.onPrimaryContainer,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: scheme.primary,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSmall)),
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.white,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.horizontal(right: Radius.circular(24)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: cardColor,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: cardColor,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? Colors.white : null),
        trackColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? scheme.primary : null),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          selectedBackgroundColor: scheme.primaryContainer,
          selectedForegroundColor: scheme.onPrimaryContainer,
          side: BorderSide(color: palette.border),
        ),
      ),
      progressIndicatorTheme:
          ProgressIndicatorThemeData(color: scheme.primary),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
