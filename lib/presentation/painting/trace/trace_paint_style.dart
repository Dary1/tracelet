import 'package:flutter/material.dart';
import 'package:tracelet/presentation/theme/tracelet_colors.dart';
import 'package:tracelet/presentation/theme/tracelet_visual_tokens.dart';

/// Visual constants for trace stroke rendering.
class TracePaintStyle {
  const TracePaintStyle({
    this.defaultColor = TraceletColors.traceDefault,
    this.blurSigma = 3.5,
    this.strokeCap = StrokeCap.round,
    this.minLifeAlpha = 0.02,
  });

  final Color defaultColor;
  final double blurSigma;
  final StrokeCap strokeCap;
  final double minLifeAlpha;

  static const standard = TracePaintStyle();

  factory TracePaintStyle.fromTokens(TraceletVisualTokens tokens) {
    return TracePaintStyle(blurSigma: tokens.traceGlowBlur);
  }
}
