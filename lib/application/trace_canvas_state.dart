import 'package:tracelet/domain/models/particle_effect_profile.dart';
import 'package:tracelet/domain/models/trace_point.dart';
import 'package:tracelet/domain/models/trace_pressure_profile.dart';
import 'package:tracelet/domain/traces/particle_emitter.dart';

class TraceCanvasState {
  const TraceCanvasState({
    this.points = const [],
    this.isPlaying = false,
    this.repaintTick = 0,
    this.fadeDuration = fadeDurationDefault,
    this.particles = const [],
    this.particleStyle = ParticleEffectStyle.off,
    this.pressureProfile = const TracePressureProfile(),
  });

  /// Canvas trails fade to invisible over this duration (user drawing).
  /// 75% of the original 1500 ms default.
  static const fadeDurationScale = 0.75;
  static const fadeDurationDefault = Duration(milliseconds: 1125);
  static const playbackStep = Duration(milliseconds: 12);

  /// Applies the global canvas fade scale (e.g. system-trace asset durations).
  static Duration scaledFade(Duration duration) => Duration(
        milliseconds: (duration.inMilliseconds * fadeDurationScale)
            .round()
            .clamp(1, 30000),
      );

  final List<TracePoint> points;
  final bool isPlaying;
  final int repaintTick;
  final Duration fadeDuration;
  final List<TraceParticle> particles;
  final ParticleEffectStyle particleStyle;
  final TracePressureProfile pressureProfile;

  bool get needsFadeAnimation =>
      points.any((point) => !point.isBreak);

  bool get needsAnimation => needsFadeAnimation || particles.isNotEmpty;
}
