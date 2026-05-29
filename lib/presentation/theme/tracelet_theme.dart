import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:tracelet/presentation/theme/tracelet_colors.dart';
import 'package:tracelet/presentation/theme/tracelet_shapes.dart';
import 'package:tracelet/presentation/theme/tracelet_visual_tokens.dart';

ThemeData buildTraceletTheme() {
  const tokens = TraceletVisualTokens();

  const colorScheme = ColorScheme.dark(
    surface: TraceletColors.surface,
    onSurface: TraceletColors.textPrimary,
    onSurfaceVariant: TraceletColors.textSecondary,
    error: TraceletColors.error,
    onError: TraceletColors.textPrimary,
    primary: TraceletColors.buttonA,
    onPrimary: TraceletColors.textPrimary,
    secondary: TraceletColors.buttonB,
    onSecondary: TraceletColors.textPrimary,
  );

  final textTheme = TextTheme(
    titleLarge: const TextStyle(
      color: TraceletColors.textPrimary,
      fontSize: 20,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.2,
      height: 1.25,
    ),
    titleSmall: const TextStyle(
      color: TraceletColors.textMuted,
      fontSize: 13,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.4,
      height: 1.3,
    ),
    bodyMedium: const TextStyle(
      color: TraceletColors.textSecondary,
      fontSize: 16,
      fontWeight: FontWeight.w400,
      height: 1.35,
    ),
    bodySmall: const TextStyle(
      color: TraceletColors.textSubtle,
      fontSize: 13,
      fontWeight: FontWeight.w400,
      height: 1.35,
    ),
    labelLarge: const TextStyle(
      color: TraceletColors.textPrimary,
      fontSize: 16,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.1,
    ),
  );

  return ThemeData(
    brightness: Brightness.dark,
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: TraceletColors.surface,
    textTheme: textTheme,
    iconTheme: const IconThemeData(
      color: TraceletColors.iconMuted,
      size: 22,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: TraceletColors.appBar,
      foregroundColor: TraceletColors.textPrimary,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      toolbarHeight: 52,
      titleSpacing: 0,
      leadingWidth: 56,
      titleTextStyle: textTheme.titleLarge,
      iconTheme: const IconThemeData(color: TraceletColors.textSecondary),
      actionsIconTheme: const IconThemeData(color: TraceletColors.textSecondary),
    ),
    dividerTheme: const DividerThemeData(
      color: TraceletColors.divider,
      thickness: 1,
      space: 1,
    ),
    listTileTheme: const ListTileThemeData(
      iconColor: TraceletColors.iconMuted,
      textColor: TraceletColors.textSecondary,
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      minVerticalPadding: 0,
      horizontalTitleGap: 16,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(
          Radius.circular(TraceletShapes.listTileRadiusValue),
        ),
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return TraceletColors.textPrimary;
        }
        return TraceletColors.textSubtle;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return TraceletColors.buttonA.withValues(alpha: 0.55);
        }
        return TraceletColors.buttonFilledDisabled;
      }),
      trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
    ),
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return TraceletColors.textPrimary;
        }
        return TraceletColors.textMuted;
      }),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        backgroundColor: TraceletColors.buttonFilled,
        foregroundColor: TraceletColors.textPrimary,
        disabledBackgroundColor: TraceletColors.buttonFilledDisabled,
        disabledForegroundColor: TraceletColors.buttonForegroundDisabled,
        shape: RoundedRectangleBorder(
          borderRadius: TraceletShapes.buttonRadius,
        ),
        textStyle: textTheme.labelLarge,
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: TraceletColors.surfaceElevated,
      contentTextStyle: textTheme.bodyMedium,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: TraceletShapes.snackBarRadius,
      ),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: TraceletColors.textMuted,
      linearMinHeight: 2,
    ),
    cardTheme: CardThemeData(
      color: TraceletColors.surfaceGroup,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: TraceletShapes.surfaceGroupRadius,
      ),
    ),
    splashColor: TraceletColors.overlayMuted,
    highlightColor: TraceletColors.overlayMuted.withValues(alpha: 0.5),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: TraceletColors.textSecondary,
        highlightColor: TraceletColors.overlayMuted,
      ),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
      },
    ),
    extensions: const [tokens],
  );
}
