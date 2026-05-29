/// Visual constants for particle effect rendering.
class ParticlePaintStyle {
  const ParticlePaintStyle({
    this.glowBlurMultiplier = 1.15,
    this.glowCoreScale = 0.85,
    this.glowHaloScale = 1.35,
    this.glowHaloAlpha = 0.35,
    this.sparkleArmMultiplier = 1.5,
    this.sparkleStrokeWidth = 1.2,
    this.emberCoreScale = 1.0,
    this.driftCoreScale = 0.95,
  });

  final double glowBlurMultiplier;
  final double glowCoreScale;
  final double glowHaloScale;
  final double glowHaloAlpha;
  final double sparkleArmMultiplier;
  final double sparkleStrokeWidth;
  final double emberCoreScale;
  final double driftCoreScale;

  static const standard = ParticlePaintStyle();
}
