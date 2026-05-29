import 'package:flutter/material.dart';
import 'package:tracelet/presentation/theme/tracelet_colors.dart';

/// App-specific tokens exposed through [ThemeExtension].
@immutable
class TraceletVisualTokens extends ThemeExtension<TraceletVisualTokens> {
  const TraceletVisualTokens({
    this.canvasBackground = TraceletColors.canvas,
    this.surfaceBackground = TraceletColors.surface,
    this.surfaceGroup = TraceletColors.surfaceGroup,
    this.surfaceElevated = TraceletColors.surfaceElevated,
    this.buttonA = TraceletColors.buttonA,
    this.buttonB = TraceletColors.buttonB,
    this.textPrimary = TraceletColors.textPrimary,
    this.textSecondary = TraceletColors.textSecondary,
    this.textMuted = TraceletColors.textMuted,
    this.textSubtle = TraceletColors.textSubtle,
    this.error = TraceletColors.error,
    this.overlayMuted = TraceletColors.overlayMuted,
    this.traceGlowBlur = 3.5,
    this.cueRippleBlur = 6.0,
    this.cueGlowBlur = 20.0,
    this.hardwareIdleAlpha = 0.2,
    this.hardwarePressedAlpha = 0.5,
  });

  final Color canvasBackground;
  final Color surfaceBackground;
  final Color surfaceGroup;
  final Color surfaceElevated;
  final Color buttonA;
  final Color buttonB;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color textSubtle;
  final Color error;
  final Color overlayMuted;
  final double traceGlowBlur;
  final double cueRippleBlur;
  final double cueGlowBlur;
  final double hardwareIdleAlpha;
  final double hardwarePressedAlpha;

  static TraceletVisualTokens of(BuildContext context) {
    return Theme.of(context).extension<TraceletVisualTokens>() ??
        const TraceletVisualTokens();
  }

  @override
  TraceletVisualTokens copyWith({
    Color? canvasBackground,
    Color? surfaceBackground,
    Color? surfaceGroup,
    Color? surfaceElevated,
    Color? buttonA,
    Color? buttonB,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? textSubtle,
    Color? error,
    Color? overlayMuted,
    double? traceGlowBlur,
    double? cueRippleBlur,
    double? cueGlowBlur,
    double? hardwareIdleAlpha,
    double? hardwarePressedAlpha,
  }) {
    return TraceletVisualTokens(
      canvasBackground: canvasBackground ?? this.canvasBackground,
      surfaceBackground: surfaceBackground ?? this.surfaceBackground,
      surfaceGroup: surfaceGroup ?? this.surfaceGroup,
      surfaceElevated: surfaceElevated ?? this.surfaceElevated,
      buttonA: buttonA ?? this.buttonA,
      buttonB: buttonB ?? this.buttonB,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      textSubtle: textSubtle ?? this.textSubtle,
      error: error ?? this.error,
      overlayMuted: overlayMuted ?? this.overlayMuted,
      traceGlowBlur: traceGlowBlur ?? this.traceGlowBlur,
      cueRippleBlur: cueRippleBlur ?? this.cueRippleBlur,
      cueGlowBlur: cueGlowBlur ?? this.cueGlowBlur,
      hardwareIdleAlpha: hardwareIdleAlpha ?? this.hardwareIdleAlpha,
      hardwarePressedAlpha: hardwarePressedAlpha ?? this.hardwarePressedAlpha,
    );
  }

  @override
  TraceletVisualTokens lerp(
    covariant TraceletVisualTokens? other,
    double t,
  ) {
    if (other == null) return this;
    return TraceletVisualTokens(
      canvasBackground: Color.lerp(canvasBackground, other.canvasBackground, t)!,
      surfaceBackground:
          Color.lerp(surfaceBackground, other.surfaceBackground, t)!,
      surfaceGroup: Color.lerp(surfaceGroup, other.surfaceGroup, t)!,
      surfaceElevated: Color.lerp(surfaceElevated, other.surfaceElevated, t)!,
      buttonA: Color.lerp(buttonA, other.buttonA, t)!,
      buttonB: Color.lerp(buttonB, other.buttonB, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      textSubtle: Color.lerp(textSubtle, other.textSubtle, t)!,
      error: Color.lerp(error, other.error, t)!,
      overlayMuted: Color.lerp(overlayMuted, other.overlayMuted, t)!,
      traceGlowBlur: traceGlowBlur + (other.traceGlowBlur - traceGlowBlur) * t,
      cueRippleBlur: cueRippleBlur + (other.cueRippleBlur - cueRippleBlur) * t,
      cueGlowBlur: cueGlowBlur + (other.cueGlowBlur - cueGlowBlur) * t,
      hardwareIdleAlpha:
          hardwareIdleAlpha + (other.hardwareIdleAlpha - hardwareIdleAlpha) * t,
      hardwarePressedAlpha: hardwarePressedAlpha +
          (other.hardwarePressedAlpha - hardwarePressedAlpha) * t,
    );
  }
}
