import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_dimensions.dart';
import 'app_typography.dart';

/// Assembles the two themes from the tokens.
///
/// Light and dark are built **separately**, not derived from one another (§10).
/// They share this function's structure because the component shapes are the
/// same; every colour they use is chosen for its own background.
abstract final class AppTheme {
  static ThemeData get light => _build(
    brightness: Brightness.light,
    scheme: const ColorScheme.light(
      primary: AppColors.lightPrimary,
      onPrimary: AppColors.lightOnPrimary,
      primaryContainer: AppColors.lightPrimaryContainer,
      onPrimaryContainer: AppColors.lightOnPrimaryContainer,
      secondary: AppColors.lightPrimary,
      onSecondary: AppColors.lightOnPrimary,
      secondaryContainer: AppColors.lightPrimaryContainer,
      onSecondaryContainer: AppColors.lightOnPrimaryContainer,
      surface: AppColors.lightSurface,
      onSurface: AppColors.lightOnSurface,
      onSurfaceVariant: AppColors.lightOnSurfaceVariant,
      surfaceContainerLowest: AppColors.lightSurface,
      surfaceContainerLow: AppColors.lightBackground,
      surfaceContainer: AppColors.lightSurfaceContainer,
      surfaceContainerHigh: AppColors.lightSurfaceContainerHigh,
      surfaceContainerHighest: AppColors.lightSurfaceContainerHigh,
      outline: AppColors.lightOutline,
      outlineVariant: AppColors.lightOutlineVariant,
      error: AppColors.lightError,
      onError: AppColors.lightOnError,
      errorContainer: AppColors.lightErrorContainer,
      onErrorContainer: AppColors.lightOnErrorContainer,
    ),
    background: AppColors.lightBackground,
    statuses: StatusPalette.light,
  );

  static ThemeData get dark => _build(
    brightness: Brightness.dark,
    scheme: const ColorScheme.dark(
      primary: AppColors.darkPrimary,
      onPrimary: AppColors.darkOnPrimary,
      primaryContainer: AppColors.darkPrimaryContainer,
      onPrimaryContainer: AppColors.darkOnPrimaryContainer,
      secondary: AppColors.darkPrimary,
      onSecondary: AppColors.darkOnPrimary,
      secondaryContainer: AppColors.darkPrimaryContainer,
      onSecondaryContainer: AppColors.darkOnPrimaryContainer,
      surface: AppColors.darkSurface,
      onSurface: AppColors.darkOnSurface,
      onSurfaceVariant: AppColors.darkOnSurfaceVariant,
      surfaceContainerLowest: AppColors.darkBackground,
      surfaceContainerLow: AppColors.darkBackground,
      surfaceContainer: AppColors.darkSurfaceContainer,
      surfaceContainerHigh: AppColors.darkSurfaceContainerHigh,
      surfaceContainerHighest: AppColors.darkSurfaceContainerHigh,
      outline: AppColors.darkOutline,
      outlineVariant: AppColors.darkOutlineVariant,
      error: AppColors.darkError,
      onError: AppColors.darkOnError,
      errorContainer: AppColors.darkErrorContainer,
      onErrorContainer: AppColors.darkOnErrorContainer,
    ),
    background: AppColors.darkBackground,
    statuses: StatusPalette.dark,
  );

  static ThemeData _build({
    required Brightness brightness,
    required ColorScheme scheme,
    required Color background,
    required StatusPalette statuses,
  }) {
    final TextTheme text = AppTypography.textTheme(
      scheme.onSurface,
      scheme.onSurfaceVariant,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      canvasColor: background,
      fontFamily: AppTypography.fontFamily,
      fontFamilyFallback: AppTypography.fontFamilyFallback,
      textTheme: text,
      extensions: <ThemeExtension<dynamic>>[statuses],

      // Structure comes from borders and surface steps, not from shadows (§10).
      // This also survives dark mode, where a shadow is close to invisible and
      // a shadow-based hierarchy silently collapses.
      cardTheme: CardThemeData(
        color: scheme.surface,
        elevation: AppElevation.none,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(
            color: scheme.outlineVariant,
            width: AppBorders.hairline,
          ),
        ),
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: scheme.onSurface,
        elevation: AppElevation.none,
        scrolledUnderElevation: AppElevation.none,
        centerTitle: false,
        titleTextStyle: AppTypography.pageTitle.copyWith(
          color: scheme.onSurface,
          fontFamily: AppTypography.fontFamily,
        ),
      ),

      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: AppBorders.hairline,
        space: AppBorders.hairline,
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, AppLayout.minTouchTarget),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: AppTypography.bodyStrong.copyWith(
            fontFamily: AppTypography.fontFamily,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, AppLayout.minTouchTarget),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          side: BorderSide(color: scheme.outline, width: AppBorders.hairline),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: AppTypography.bodyStrong.copyWith(
            fontFamily: AppTypography.fontFamily,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(0, AppLayout.minTouchTarget),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          textStyle: AppTypography.bodyStrong.copyWith(
            fontFamily: AppTypography.fontFamily,
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerLow,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(
            color: scheme.outline,
            width: AppBorders.hairline,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(
            color: scheme.outline,
            width: AppBorders.hairline,
          ),
        ),
        // The accent earns its keep here: a focus ring is exactly the kind of
        // momentary, meaningful emphasis one accent colour is for.
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(
            color: scheme.primary,
            width: AppBorders.emphasis,
          ),
        ),
        labelStyle: AppTypography.body.copyWith(
          color: scheme.onSurfaceVariant,
          fontFamily: AppTypography.fontFamily,
        ),
        hintStyle: AppTypography.body.copyWith(
          color: scheme.onSurfaceVariant,
          fontFamily: AppTypography.fontFamily,
        ),
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        indicatorColor: scheme.primaryContainer,
        elevation: AppElevation.none,
        height: 68,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return AppTypography.label.copyWith(
            fontFamily: AppTypography.fontFamily,
            color: selected ? scheme.onSurface : scheme.onSurfaceVariant,
            fontWeight: selected ? FontWeight.w500 : FontWeight.w400,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            size: AppIconSize.lg,
            color: selected
                ? scheme.onPrimaryContainer
                : scheme.onSurfaceVariant,
          );
        }),
      ),

      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: scheme.surface,
        indicatorColor: scheme.primaryContainer,
        elevation: AppElevation.none,
        selectedLabelTextStyle: AppTypography.bodyStrong.copyWith(
          fontFamily: AppTypography.fontFamily,
          color: scheme.onSurface,
        ),
        unselectedLabelTextStyle: AppTypography.body.copyWith(
          fontFamily: AppTypography.fontFamily,
          color: scheme.onSurfaceVariant,
        ),
        selectedIconTheme: IconThemeData(
          size: AppIconSize.lg,
          color: scheme.onPrimaryContainer,
        ),
        unselectedIconTheme: IconThemeData(
          size: AppIconSize.lg,
          color: scheme.onSurfaceVariant,
        ),
      ),

      iconTheme: IconThemeData(
        size: AppIconSize.lg,
        color: scheme.onSurfaceVariant,
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        elevation: AppElevation.overlay,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        titleTextStyle: AppTypography.sectionTitle.copyWith(
          color: scheme.onSurface,
          fontFamily: AppTypography.fontFamily,
        ),
        contentTextStyle: AppTypography.body.copyWith(
          color: scheme.onSurfaceVariant,
          fontFamily: AppTypography.fontFamily,
        ),
      ),

      dataTableTheme: DataTableThemeData(
        headingRowColor: WidgetStatePropertyAll<Color>(
          scheme.surfaceContainerLow,
        ),
        headingTextStyle: AppTypography.label.copyWith(
          color: scheme.onSurfaceVariant,
          fontFamily: AppTypography.fontFamily,
        ),
        dataTextStyle: AppTypography.body.copyWith(
          color: scheme.onSurface,
          fontFamily: AppTypography.fontFamily,
        ),
        dividerThickness: AppBorders.hairline,
        horizontalMargin: AppSpacing.lg,
        columnSpacing: AppSpacing.xl,
      ),

      chipTheme: ChipThemeData(
        backgroundColor: scheme.surfaceContainer,
        labelStyle: AppTypography.label.copyWith(
          fontFamily: AppTypography.fontFamily,
        ),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
      ),

      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),

      splashFactory: InkSparkle.splashFactory,
      visualDensity: VisualDensity.standard,
    );
  }
}
