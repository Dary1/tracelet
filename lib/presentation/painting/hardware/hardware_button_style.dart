import 'package:tracelet/presentation/theme/tracelet_shapes.dart';

/// Visual constants for virtual hardware button zones.
class HardwareButtonStyle {
  const HardwareButtonStyle({
    this.idleAlpha = 0.16,
    this.pressedAlpha = 0.48,
    this.idleBorderAlpha = 0.38,
    this.pressedBorderAlpha = 0.88,
    this.idleBorderWidth = 1.0,
    this.pressedBorderWidth = 1.5,
    this.idleHighlightAlpha = 0.06,
    this.pressedHighlightAlpha = 0.14,
    this.cornerRadius = TraceletShapes.hardwareButtonRadius,
    this.rippleDurationMs = 600,
    this.rippleStrokeWidth = 2.0,
    this.rippleBlur = 6.0,
    this.rippleMaxAlpha = 0.45,
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
