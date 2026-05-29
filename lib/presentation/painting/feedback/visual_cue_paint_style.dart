import 'package:flutter/material.dart';
import 'package:tracelet/presentation/theme/tracelet_colors.dart';
import 'package:tracelet/presentation/theme/tracelet_shapes.dart';
import 'package:tracelet/presentation/theme/tracelet_visual_tokens.dart';

/// Visual constants for short-lived overlay feedback cues.
class VisualCuePaintStyle {
  const VisualCuePaintStyle({
    this.buttonA = TraceletColors.buttonA,
    this.buttonB = TraceletColors.buttonB,
    this.overlay = TraceletColors.traceDefault,
    this.rippleStrokeWidth = 2.5,
    this.rippleBlur = 6.0,
    this.glowBlur = 20.0,
    this.lineBlur = 3.5,
    this.lineStrokeWidth = 2.5,
    this.sweepStrokeWidth = 3.0,
    this.sweepBlur = 4.5,
    this.settingsFrameRadius = TraceletShapes.settingsFrameRadius,
    this.settingsFrameStrokeWidth = 2.0,
    this.settingsFrameAlpha = 0.2,
    this.alertBlur = 26.0,
    this.alertAlpha = 0.22,
    this.dotRadius = 6.0,
    this.meetPointRadius = 8.0,
  });

  final Color buttonA;
  final Color buttonB;
  final Color overlay;
  final double rippleStrokeWidth;
  final double rippleBlur;
  final double glowBlur;
  final double lineBlur;
  final double lineStrokeWidth;
  final double sweepStrokeWidth;
  final double sweepBlur;
  final double settingsFrameRadius;
  final double settingsFrameStrokeWidth;
  final double settingsFrameAlpha;
  final double alertBlur;
  final double alertAlpha;
  final double dotRadius;
  final double meetPointRadius;

  static const standard = VisualCuePaintStyle();

  factory VisualCuePaintStyle.fromTokens(TraceletVisualTokens tokens) {
    return VisualCuePaintStyle(
      buttonA: tokens.buttonA,
      buttonB: tokens.buttonB,
      rippleBlur: tokens.cueRippleBlur,
      glowBlur: tokens.cueGlowBlur,
    );
  }
}
