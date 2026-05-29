import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tracelet/application/pressure_input_providers.dart';
import 'package:tracelet/application/app_state_notifier.dart';
import 'package:tracelet/application/screen_size.dart';
import 'package:tracelet/application/trace_canvas_state.dart';
import 'package:tracelet/application/trace_profile_resolver.dart';
import 'package:tracelet/core/haptics.dart';
import 'package:tracelet/domain/models/particle_effect_profile.dart';
import 'package:tracelet/domain/models/trace_point.dart';
import 'package:tracelet/domain/input/pressure_capture.dart';
import 'package:tracelet/domain/models/trace_pressure_profile.dart';
import 'package:tracelet/domain/models/trace_playback_profile.dart';
import 'package:tracelet/domain/models/trace_profile.dart';
import 'package:tracelet/domain/models/user.dart';
import 'package:tracelet/data/repositories/asset_system_trace_repository.dart';
import 'package:tracelet/domain/repositories/system_trace_repository.dart';
import 'package:tracelet/domain/system_traces/system_trace_id.dart';
import 'package:tracelet/domain/system_traces/system_trace_playback.dart';
import 'package:tracelet/domain/traces/particle_emitter.dart';
import 'package:tracelet/domain/traces/playback_event_log.dart';
import 'package:tracelet/domain/traces/trace_point_player.dart';

class TraceCanvasNotifier extends Notifier<TraceCanvasState>
    implements TracePointPlaybackHost {
  final List<TracePoint> _points = [];
  final ParticleEmitter _particleEmitter = ParticleEmitter();
  int _repaintTick = 0;
  DateTime? _lastHapticAt;
  ParticleEffectStyle _particleStyle = ParticleEffectStyle.off;
  TracePressureProfile _pressureProfile = const TracePressureProfile();
  /// Sender profile from the trace payload header; pinned until fade completes.
  TracePlaybackProfile? _headerPlaybackProfile;

  DateTime? _playbackWallStart;
  DateTime? _playbackTraceEpoch;

  @visibleForTesting
  bool playbackTelemetryEnabled = false;

  List<PlaybackEvent>? _playbackTelemetryEvents;
  Stopwatch? _playbackTelemetryClock;
  var _playbackTelemetryPointIndex = 0;

  @visibleForTesting
  PlaybackEventLog? takePlaybackTelemetryLog() {
    final events = _playbackTelemetryEvents;
    _playbackTelemetryEvents = null;
    _playbackTelemetryClock = null;
    _playbackTelemetryPointIndex = 0;
    if (events == null) return null;
    return PlaybackEventLog(List.unmodifiable(events));
  }

  void _telemetryStart() {
    if (!playbackTelemetryEnabled) return;
    _playbackTelemetryEvents = [];
    _playbackTelemetryPointIndex = 0;
    _playbackTelemetryClock = Stopwatch()..start();
  }

  int _telemetryMs() => _playbackTelemetryClock?.elapsedMilliseconds ?? 0;

  void _telemetry(PlaybackEvent event) {
    _playbackTelemetryEvents?.add(event);
  }

  SystemTraceRepository get _traces => ref.read(systemTraceRepositoryProvider);

  PressureCapture get _pressureCapture => PressureCapture(
        detector: ref.read(pressureInputDetectorProvider),
        profile: () => resolveTraceProfile(ref.read(appStateProvider).settings).pressure,
      );

  @override
  TraceCanvasState build() {
    _repaintTick = 0;
    _points.clear();
    _particleEmitter.clear();
    _particleStyle = ParticleEffectStyle.off;
    _pressureProfile = const TracePressureProfile();
    _headerPlaybackProfile = null;
    _clearPlaybackSession();
    return const TraceCanvasState();
  }

  TraceCanvasState _emit({bool? isPlaying, Duration? fadeDuration}) {
    return TraceCanvasState(
      points: List.unmodifiable(_points),
      isPlaying: isPlaying ?? state.isPlaying,
      repaintTick: _repaintTick,
      fadeDuration: fadeDuration ?? state.fadeDuration,
      particles: _particleEmitter.snapshot(),
      particleStyle: _particleStyle,
      pressureProfile: _pressureProfile,
    );
  }

  void _repaint() => _repaintTick++;

  void _syncLivePressureProfile() {
    _pressureProfile =
        resolveTraceProfile(ref.read(appStateProvider).settings).pressure;
  }

  void _applyHeaderPlaybackProfile(TracePlaybackProfile profile) {
    _headerPlaybackProfile = profile;
    _configureParticles(profile.particles);
    _pressureProfile = profile.pressure;
  }

  void _releaseHeaderPlaybackProfile() {
    if (_headerPlaybackProfile == null) return;
    _headerPlaybackProfile = null;
    _particleEmitter.clear();
    _particleStyle = ParticleEffectStyle.off;
    _syncLivePressureProfile();
  }

  void _clearPlaybackSession() {
    _playbackWallStart = null;
    _playbackTraceEpoch = null;
  }

  DateTime _playbackDisplayTime(TracePoint storedPoint) {
    final wallStart = _playbackWallStart ??= DateTime.now();
    final traceEpoch = _playbackTraceEpoch ??= storedPoint.timestamp;
    return wallStart.add(storedPoint.timestamp.difference(traceEpoch));
  }

  void onFrame() {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    _particleEmitter.tick(nowMs);
    pruneExpiredPoints();
    if (state.needsAnimation) {
      _repaint();
      state = _emit();
    }
  }

  void pruneExpiredPoints() {
    if (state.isPlaying || _points.isEmpty) return;

    final now = DateTime.now();
    final before = _points.length;
    _points.removeWhere(
      (point) =>
          !point.isBreak &&
          now.difference(point.timestamp) > state.fadeDuration,
    );

    if (_points.length != before) {
      if (_points.isEmpty) {
        _releaseHeaderPlaybackProfile();
      }
      state = _emit();
    }
  }

  void addDrawInput(
    Offset position, {
    Color? color,
    double hardwarePressure = 1.0,
  }) {
    final previous = _lastDrawablePoint();
    final point = _pressureCapture.buildPoint(
      position: position,
      timestamp: DateTime.now(),
      hardwarePressure: hardwarePressure,
      previous: previous,
      color: color,
    );
    _appendLivePoint(point, spawnParticles: !state.isPlaying);
  }

  void addRecordedPoint(TracePoint point) {
    _appendLivePoint(point, spawnParticles: !state.isPlaying);
  }

  TracePoint? _lastDrawablePoint() {
    for (var i = _points.length - 1; i >= 0; i--) {
      if (!_points[i].isBreak) return _points[i];
    }
    return null;
  }

  void _appendLivePoint(TracePoint point, {bool spawnParticles = false}) {
    if (_headerPlaybackProfile != null) {
      _releaseHeaderPlaybackProfile();
    } else if (!state.isPlaying) {
      _syncLivePressureProfile();
    }
    _points.add(point);
    if (spawnParticles) {
      _spawnLiveParticle(point.position, point.color);
    }
    _repaint();
    state = _emit();
    _maybeHapticOnDraw();
  }

  void addPoint(Offset position, {Color? color}) {
    addDrawInput(position, color: color);
  }

  void _spawnLiveParticle(Offset position, Color? color) {
    final profile = resolveTraceProfile(ref.read(appStateProvider).settings);
    _configureParticles(profile.particles);
    if (!profile.particles.enabled) return;

    _particleEmitter.onStrokeHead(
      position: position,
      tangent: _lastDrawTangent(),
      strokeColor: color,
      nowMs: DateTime.now().millisecondsSinceEpoch,
    );
  }

  Offset? _lastDrawTangent() {
    if (_points.length < 2 || _points.last.isBreak) return null;

    for (var i = _points.length - 2; i >= 0; i--) {
      final point = _points[i];
      if (point.isBreak) return null;
      return _points.last.position - point.position;
    }
    return null;
  }

  void _configureParticles(ParticleEffectProfile profile) {
    _particleEmitter.configure(profile);
    _particleStyle = profile.style;
  }

  void endStroke() {
    _points.add(
      TracePoint(
        position: TracePoint.strokeBreak,
        timestamp: DateTime.now(),
        isStrokeBreak: true,
      ),
    );
    state = _emit();
  }

  void clear() {
    _points.clear();
    _particleEmitter.clear();
    _particleStyle = ParticleEffectStyle.off;
    _clearPlaybackSession();
    _releaseHeaderPlaybackProfile();
    _repaint();
    state = _emit(fadeDuration: TraceCanvasState.fadeDurationDefault);
  }

  List<TracePoint> captureStrokePoints() => List.unmodifiable(_points);

  Future<void> playSystemTrace(
    SystemTraceId id,
    Size size, {
    bool clearFirst = true,
  }) async {
    final document = _traces.documentFor(id);
    if (document == null || document.strokes.isEmpty) return;

    final points = SystemTracePlayback.pointsFor(document);
    if (points.isEmpty) return;

    final userProfile = resolveTraceProfile(ref.read(appStateProvider).settings);
    final playback = TracePlaybackProfile.forSystemTrace(
      canvasSize: size,
      preset: userProfile.preset,
      particles: userProfile.particles,
      pressure: userProfile.pressure,
    );

    await TracePointPlayer.playByPoints(
      host: this,
      storedPoints: points,
      playbackProfile: playback,
      canvasSize: size,
      clearFirst: clearFirst,
      fadeDuration: TraceCanvasState.scaledFade(document.fadeDuration),
    );
  }

  Future<void> playTrace(
    List<TracePoint> points, {
    required TracePlaybackProfile playbackProfile,
    bool clearFirst = true,
    Duration fadeDuration = TraceCanvasState.fadeDurationDefault,
  }) =>
      TracePointPlayer.playByPoints(
        host: this,
        storedPoints: points,
        playbackProfile: playbackProfile,
        canvasSize: ref.read(screenSizeProvider),
        clearFirst: clearFirst,
        fadeDuration: fadeDuration,
      );

  /// Receiver playback — realtime point-by-point replay via [TracePointPlayer].
  Future<void> playMessagePoints(
    List<TracePoint> points, {
    required TracePlaybackProfile playbackProfile,
  }) =>
      playTrace(points, playbackProfile: playbackProfile);

  @override
  Future<void> beginTracePlayback({
    required TracePlaybackProfile playbackProfile,
    required bool clearFirst,
    required Duration fadeDuration,
  }) async {
    _playbackWallStart = DateTime.now();
    _playbackTraceEpoch = null;
    _telemetryStart();
    _telemetry(PlaybackBegin(_telemetryMs()));

    if (clearFirst) {
      _points.clear();
      _particleEmitter.clear();
      _repaint();
    }
    _applyHeaderPlaybackProfile(playbackProfile);
    state = _emit(isPlaying: true, fadeDuration: fadeDuration);
  }

  TracePlaybackProfile get _activeHeaderProfile {
    final profile = _headerPlaybackProfile;
    assert(profile != null, 'header playback profile must be set');
    return profile!;
  }

  @override
  Future<void> renderTracePoint(
    TracePoint point, {
    TracePoint? previous,
  }) async {
    final profile = _activeHeaderProfile;
    _points.add(
      point.copyWith(timestamp: _playbackDisplayTime(point)),
    );
    if (_playbackTelemetryEvents != null) {
      _telemetry(
        PlaybackPoint(
          _telemetryMs(),
          x: point.position.dx,
          y: point.position.dy,
          pressure: point.effectivePressure,
          pointIndex: _playbackTelemetryPointIndex++,
        ),
      );
    }

    if (profile.particles.enabled) {
      final prevPos =
          previous != null && !previous.isBreak ? previous.position : null;
      _particleEmitter.onStrokeHead(
        position: point.position,
        tangent: prevPos != null ? point.position - prevPos : null,
        strokeColor: point.color,
        nowMs: DateTime.now().millisecondsSinceEpoch,
      );
    }

    _repaint();
    state = _emit();
  }

  @override
  Future<void> renderTraceStrokeBreak() async {
    if (_playbackTelemetryEvents != null) {
      _telemetry(PlaybackBreak(_telemetryMs()));
    }
    _points.add(
      TracePoint(
        position: TracePoint.strokeBreak,
        timestamp: DateTime.now(),
        isStrokeBreak: true,
      ),
    );
    _repaint();
    state = _emit();
  }

  @override
  Future<void> waitForTraceInterval(int delayMs) async {
    if (delayMs <= 0) return;
    if (_playbackTelemetryEvents != null) {
      _telemetry(PlaybackWait(_telemetryMs(), delayMs));
    }

    const stepMs = 16;
    var remaining = delayMs;
    while (remaining > 0) {
      final chunk = remaining > stepMs ? stepMs : remaining;
      await Future<void>.delayed(Duration(milliseconds: chunk));
      if (_activeHeaderProfile.particles.enabled) {
        _particleEmitter.tick(DateTime.now().millisecondsSinceEpoch);
      }
      _repaint();
      state = _emit();
      remaining -= chunk;
    }
  }

  @override
  Future<void> endTracePlayback() async {
    if (_playbackTelemetryEvents != null) {
      _telemetry(PlaybackEnd(_telemetryMs()));
    }
    _clearPlaybackSession();
    state = _emit(
      isPlaying: false,
      fadeDuration: TraceCanvasState.fadeDurationDefault,
    );
  }

  Future<void> playNameTrace(TraceUser user) async {
    final size = ref.read(screenSizeProvider);

    if (user.nameTracePoints.isEmpty) {
      await playSystemTrace(SystemTraceId.destinationSelected, size);
      return;
    }

    final epoch = DateTime.fromMillisecondsSinceEpoch(0);
    var elapsedMs = 0;
    final points = <TracePoint>[];
    Offset? previous;

    for (final sample in user.nameTracePoints) {
      final position = Offset(sample.dx, sample.dy);
      if (previous != null && (position - previous).distance > 80) {
        points.add(
          TracePoint(
            position: TracePoint.strokeBreak,
            timestamp: epoch.add(Duration(milliseconds: elapsedMs)),
            isStrokeBreak: true,
          ),
        );
      }

      if (points.isNotEmpty && !points.last.isBreak) {
        elapsedMs += SystemTracePlayback.stepDuration.inMilliseconds;
      }

      points.add(
        TracePoint(
          position: Offset(
            position.dx / size.width,
            position.dy / size.height,
          ),
          timestamp: epoch.add(Duration(milliseconds: elapsedMs)),
          pressure: 1.0,
        ),
      );
      previous = position;
    }

    await playTrace(
      points,
      playbackProfile: TraceProfilePresets.pureFinger.toPlaybackProfile(size),
    );
  }

  void _maybeHapticOnDraw() {
    if (state.isPlaying) return;
    final now = DateTime.now();
    if (_lastHapticAt != null &&
        now.difference(_lastHapticAt!) < const Duration(milliseconds: 80)) {
      return;
    }
    _lastHapticAt = now;
    TraceletHaptics.traceDraw();
  }
}

final traceCanvasProvider =
    NotifierProvider<TraceCanvasNotifier, TraceCanvasState>(
  TraceCanvasNotifier.new,
);
