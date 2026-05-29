import 'package:tracelet/presentation/theme/tracelet_shapes.dart';

/// Visual constants for virtual hardware button zones.
class HardwareButtonStyle {
  const HardwareButtonStyle({
    this.idleAlpha = 0.18,
    this.pressedAlpha = 0.52,
    this.idleBorderAlpha = 0.42,
    this.pressedBorderAlpha = 0.92,
    this.idleBorderWidth = 1.0,
    this.pressedBorderWidth = 2.0,
    this.idleHighlightAlpha = 0.08,
    this.pressedHighlightAlpha = 0.16,
    this.cornerRadius = TraceletShapes.hardwareButtonRadius,
    this.rippleDurationMs = 650,
    this.rippleStrokeWidth = 2.5,
    this.rippleBlur = 5.5,
    this.rippleMaxAlpha = 0.5,
  });

  final double idleAlpha;
  final double pressedAlpha;
  final double idleBorderAlpha;
  final double pressedBorderAlpha;
  final double idleBorderWidth;
  final double pressedBorderWidth;
  final double idleHighlightAlpha;
  final double pressedHighlightAlpha;
  final double cornerRadius;
  final int rippleDurationMs;
  final double rippleStrokeWidth;
  final double rippleBlur;
  final double rippleMaxAlpha;

  static const standard = HardwareButtonStyle();
}
