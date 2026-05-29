import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tracelet/application/screen_size.dart';
import 'package:tracelet/application/trace_canvas_notifier.dart';
import 'package:tracelet/application/trace_canvas_state.dart';
import 'package:tracelet/data/fakes/in_memory_bottle_ocean.dart';
import 'package:tracelet/data/local/memory_message_inbox.dart';
import 'package:tracelet/domain/bottle/bottle_send_feedback.dart';
import 'package:tracelet/domain/bottle/bottle_send_pipeline.dart';
import 'package:tracelet/domain/input/bottle_draw_session.dart';
import 'package:tracelet/domain/input/pressure_capture.dart';
import 'package:tracelet/domain/input/pressure_input_detector.dart';
import 'package:tracelet/domain/models/trace_message.dart';
import 'package:tracelet/domain/models/trace_profile.dart';
import 'package:tracelet/domain/services/bottle_mail_service.dart';
import 'package:tracelet/domain/services/bottle_send_coordinator.dart';

import 'canvas_snapshot.dart';

/// Production-wired canvas + bottle input for sender/receiver parity tests.
///
/// Mirrors [BottleDrawNotifier] → [TraceCanvasNotifier] wiring without auth/API.
class TracePlaybackParityHarness {
  TracePlaybackParityHarness._({
    required this.container,
    required this.session,
    required this.profile,
    required this.canvasSize,
    required this.elapse,
    required this.flushMicrotasks,
  });

  final ProviderContainer container;
  final BottleDrawSession session;
  final TraceProfile profile;
  final Size canvasSize;
  final void Function(Duration duration) elapse;
  final void Function() flushMicrotasks;

  TraceCanvasNotifier get canvas => container.read(traceCanvasProvider.notifier);

  TraceCanvasState get canvasState => container.read(traceCanvasProvider);

  factory TracePlaybackParityHarness.create({
    required void Function(Duration duration) elapse,
    required void Function() flushMicrotasks,
    TraceProfile profile = TraceProfilePresets.littlePrettify,
    Size canvasSize = const Size(400, 800),
    DateTime? clockStart,
    BottleMailService? depositMail,
  }) {
    final container = ProviderContainer(
      overrides: [
        screenSizeProvider.overrideWith((ref) => canvasSize),
      ],
    );

    final canvas = container.read(traceCanvasProvider.notifier);
    final baseTime = clockStart ?? DateTime.utc(2026, 1, 1);
    var tick = 0;
    DateTime clock() => baseTime.add(Duration(milliseconds: tick++ * 16));

    final pressureCapture = PressureCapture(
      detector: PressureInputDetector(),
      profile: () => profile.pressure,
    );

    final pipeline = BottleSendPipeline(
      deposit: (points, {required profile, required captureSize}) async {
        if (depositMail == null) return;
        await depositMail.sendTrace(
          points,
          profile: profile,
          captureSize: captureSize,
        );
      },
      resolveProfile: () => profile,
      captureSize: () => canvasSize,
      feedback: _NoOpBottleFeedback(),
      clearCanvas: canvas.clear,
    );

    final session = BottleDrawSession(
      clock: clock,
      createTimer: (duration, callback) => Timer(duration, callback),
      pipeline: pipeline,
      pressureCapture: pressureCapture,
      onPointDrawn: canvas.addRecordedPoint,
      onStrokeEnded: (_) => canvas.endStroke(),
      onClearCanvas: canvas.clear,
    );

    return TracePlaybackParityHarness._(
      container: container,
      session: session,
      profile: profile,
      canvasSize: canvasSize,
      elapse: elapse,
      flushMicrotasks: flushMicrotasks,
    );
  }

  void dispose() => container.dispose();

  /// Same pointer order as [BottleProductionHarness.drawStroke].
  void drawSampleTrace({
    Offset start = const Offset(120, 200),
    List<Offset> through = const [
      Offset(160, 240),
      Offset(210, 260),
      Offset(260, 220),
      Offset(300, 280),
    ],
  }) {
    session.pointerDown();
    session.panStart(start);
    for (final point in through) {
      session.panMove(point);
    }
    session.panEnd();
    session.pointerUp();
  }

  /// Closed circle around [centre] — used for cross-device spatial intent tests.
  void drawCircle({
    required Offset centre,
    required double radius,
    int segments = 28,
  }) {
    session.pointerDown();
    session.panStart(centre + Offset(radius, 0));
    for (var i = 1; i <= segments; i++) {
      final theta = 2 * math.pi * i / segments;
      session.panMove(
        centre + Offset(math.cos(theta) * radius, math.sin(theta) * radius),
      );
    }
    session.panEnd();
    session.pointerUp();
  }

  CanvasSnapshot captureCanvas() => CanvasSnapshot.fromState(canvasState);

  Future<void> playReceivedMessage(TraceMessage message) {
    return canvas.playTrace(
      message.points,
      playbackProfile: message.playbackProfile,
    );
  }

  /// Realtime replay entry (same engine as [playReceivedMessage]).
  Future<void> playRealtimeTrace(TraceMessage message) {
    return playReceivedMessage(message);
  }

  /// Commits the stroke through the idle pipeline (mirrors production send).
  void waitForSendIdle() {
    elapse(bottleSendIdleDuration);
    flushMicrotasks();
  }

  static Future<TraceMessage> receiveFromOcean({
    required InMemoryBottleOcean ocean,
    String receiverId = 'device-receiver',
  }) {
    return BottleMailService(
      ocean: ocean,
      inbox: MemoryMessageInbox(),
      userId: receiverId,
    ).receive();
  }
}

class _NoOpBottleFeedback implements BottleSendFeedback {
  @override
  Future<void> onDiscarded() async {}

  @override
  Future<void> onError(Object error) async {}

  @override
  Future<void> onSent() async {}
}
