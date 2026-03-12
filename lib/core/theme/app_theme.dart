import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'app_tokens.dart';
import 'app_typography.dart';

enum AppThemeMode { light, dark }

class AppTheme {
  AppTheme._();

  static ThemeData light() {
    AppTypography.setDark(false);
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.lightBackground,
      colorScheme: ColorScheme.light(
        primary: AppColors.lightAccent,
        onPrimary: Colors.white,
        primaryContainer: AppColors.lightAccentLight,
        secondary: AppColors.lightBlue,
        onSecondary: Colors.white,
        surface: AppColors.lightSurface,
        onSurface: AppColors.lightTextPrimary,
        surfaceContainerHighest: AppColors.lightSurfaceVariant,
        error: AppColors.lightError,
        onError: Colors.white,
        outline: AppColors.lightDivider,
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: AppColors.lightSurface,
        foregroundColor: AppColors.lightTextPrimary,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: AppTypography.titleLarge.copyWith(
          color: AppColors.lightTextPrimary,
          fontWeight: FontWeight.w700,
        ),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.lightSurface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radius20),
        ),
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.lightAccent,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(
            horizontal: AppTokens.space24,
            vertical: AppTokens.space12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.radius14),
          ),
          textStyle: AppTypography.labelLarge,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.lightAccent,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          minimumSize: const Size(0, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.radius14),
          ),
          textStyle: AppTypography.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.lightBlue,
          side: const BorderSide(color: AppColors.lightBlue),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          minimumSize: const Size(0, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.radius14),
          ),
          textStyle: AppTypography.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.lightAccentDark,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          textStyle: AppTypography.labelLarge,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.lightSurfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radius14),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radius14),
          borderSide: const BorderSide(color: AppColors.lightDivider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radius14),
          borderSide: const BorderSide(color: AppColors.lightAccent, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radius14),
          borderSide: const BorderSide(color: AppColors.lightError),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        hintStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.lightTextTertiary,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: AppColors.lightTextPrimary,
          minimumSize: const Size(40, 40),
          padding: const EdgeInsets.all(AppTokens.space8),
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.lightAccent,
        unselectedLabelColor: AppColors.lightTextSecondary,
        indicatorColor: AppColors.lightAccent,
        dividerColor: Colors.transparent,
        labelStyle: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w700),
        unselectedLabelStyle: AppTypography.labelLarge,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.lightSurface,
        selectedItemColor: AppColors.lightAccent,
        unselectedItemColor: AppColors.lightTextTertiary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.lightDivider,
        thickness: 1,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.lightSurfaceVariant,
        selectedColor: AppColors.lightAccentLight.withValues(alpha: 0.35),
        labelStyle: AppTypography.labelMedium,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        showDragHandle: true,
        backgroundColor: AppColors.lightSurface,
        surfaceTintColor: Colors.transparent,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.lightSurface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radius24),
        ),
        titleTextStyle: AppTypography.headlineSmall.copyWith(color: AppColors.lightTextPrimary),
        contentTextStyle: AppTypography.bodyMedium.copyWith(color: AppColors.lightTextSecondary),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.lightCharcoal,
        contentTextStyle: AppTypography.bodyMedium.copyWith(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        titleTextStyle: AppTypography.bodyLarge.copyWith(color: AppColors.lightTextPrimary),
        subtitleTextStyle: AppTypography.bodyMedium.copyWith(color: AppColors.lightTextSecondary),
      ),
    );
  }

  static ThemeData dark() {
    AppTypography.setDark(true);
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.darkBackground,
      colorScheme: ColorScheme.dark(
        primary: AppColors.darkAccent,
        onPrimary: AppColors.darkBackground,
        primaryContainer: AppColors.darkAccentDim,
        secondary: AppColors.darkBlue,
        onSecondary: Colors.white,
        surface: AppColors.darkSurface,
        onSurface: AppColors.darkTextPrimary,
        surfaceContainerHighest: AppColors.darkSurfaceVariant,
        error: AppColors.darkError,
        onError: Colors.white,
        outline: AppColors.darkDivider,
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: AppColors.darkSurface,
        foregroundColor: AppColors.darkTextPrimary,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: AppTypography.titleLarge.copyWith(
          color: AppColors.darkTextPrimary,
          fontWeight: FontWeight.w700,
        ),
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.darkSurface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radius20),
        ),
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.darkAccent,
          foregroundColor: AppColors.darkBackground,
          elevation: 0,
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(
            horizontal: AppTokens.space24,
            vertical: AppTokens.space12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.radius14),
          ),
          textStyle: AppTypography.labelLarge,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.darkAccent,
          foregroundColor: AppColors.darkBackground,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          minimumSize: const Size(0, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.radius14),
          ),
          textStyle: AppTypography.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.darkAccent,
          side: const BorderSide(color: AppColors.darkAccent),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          minimumSize: const Size(0, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.radius14),
          ),
          textStyle: AppTypography.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.darkAccent,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          textStyle: AppTypography.labelLarge,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkSurfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radius14),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radius14),
          borderSide: const BorderSide(color: AppColors.darkDivider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radius14),
          borderSide: const BorderSide(color: AppColors.darkAccent, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radius14),
          borderSide: const BorderSide(color: AppColors.darkError),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        hintStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.darkTextTertiary,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: AppColors.darkTextPrimary,
          minimumSize: const Size(40, 40),
          padding: const EdgeInsets.all(AppTokens.space8),
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.darkAccent,
        unselectedLabelColor: AppColors.darkTextSecondary,
        indicatorColor: AppColors.darkAccent,
        dividerColor: Colors.transparent,
        labelStyle: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w700),
        unselectedLabelStyle: AppTypography.labelLarge,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.darkSurface,
        selectedItemColor: AppColors.darkAccent,
        unselectedItemColor: AppColors.darkTextTertiary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.darkDivider,
        thickness: 1,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.darkSurfaceVariant,
        selectedColor: AppColors.darkAccentDim.withValues(alpha: 0.35),
        labelStyle: AppTypography.labelMedium,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        showDragHandle: true,
        backgroundColor: AppColors.darkSurface,
        surfaceTintColor: Colors.transparent,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.darkSurface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radius24),
        ),
        titleTextStyle: AppTypography.headlineSmall.copyWith(color: AppColors.darkTextPrimary),
        contentTextStyle: AppTypography.bodyMedium.copyWith(color: AppColors.darkTextSecondary),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.darkSurfaceVariant,
        contentTextStyle: AppTypography.bodyMedium.copyWith(color: AppColors.darkTextPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        titleTextStyle: AppTypography.bodyLarge.copyWith(color: AppColors.darkTextPrimary),
        subtitleTextStyle: AppTypography.bodyMedium.copyWith(color: AppColors.darkTextSecondary),
      ),
    );
  }
}
