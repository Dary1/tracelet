import 'package:flutter/material.dart';

/// Semantic palette for Tracelet UI and canvas accents.
abstract final class TraceletColors {
  static const canvas = Color(0xFF000000);
  static const surface = Color(0xFF0C0C0E);
  static const surfaceGroup = Color(0xFF141416);
  static const surfaceElevated = Color(0xFF1C1C1E);
  static const appBar = Color(0xFF000000);

  static const buttonA = Color(0xFF0A84FF);
  static const buttonB = Color(0xFF30D158);

  /// @deprecated Use [buttonA] — kept for gradual migration.
  static const sfBlue = buttonA;

  /// @deprecated Use [buttonB] — kept for gradual migration.
  static const sfGreen = buttonB;

  static const error = Color(0xFFFF453A);

  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xB3FFFFFF);
  static const textMuted = Color(0x8AFFFFFF);
  static const textSubtle = Color(0x61FFFFFF);

  static const divider = Color(0x1FFFFFFF);
  static const iconMuted = Color(0x99FFFFFF);

  static const buttonFilled = Color(0x24FFFFFF);
  static const buttonFilledHover = Color(0x33FFFFFF);
  static const buttonFilledDisabled = Color(0x14FFFFFF);
  static const buttonForegroundDisabled = Color(0x61FFFFFF);

  static const traceDefault = Color(0xFFFFFFFF);
  static const overlayMuted = Color(0x2EFFFFFF);
  static const overlayStrong = Color(0x52FFFFFF);
}
