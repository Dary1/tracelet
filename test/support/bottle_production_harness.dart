import 'dart:async';
import 'dart:ui';

import 'package:tracelet/domain/bottle/bottle_send_feedback.dart';
import 'package:tracelet/domain/bottle/bottle_send_pipeline.dart';
import 'package:tracelet/domain/input/bottle_draw_session.dart';
import 'package:tracelet/domain/models/app_mode.dart';
import 'package:tracelet/domain/models/trace_profile.dart';
import 'package:tracelet/domain/services/bottle_send_coordinator.dart';

import 'fake_trace_canvas.dart';

/// Mirrors [TraceCanvas] pointer/pan event order for production-flow tests.
class BottleProductionHarness {
  BottleProductionHarness({
    required this.session,
    required this.canvas,
    required this.repository,
    required this.feedback,
    required this.elapse,
    required this.flushMicrotasks,
    this.mode = AppMode.bottleMail,
  });

  final BottleDrawSession session;
  final FakeTraceCanvas canvas;
  final dynamic repository;
  final BottleSendFeedback feedback;
  final void Function(Duration duration) elapse;
  final void Function() flushMicrotasks;
  AppMode mode;

  bool get _isBottleMail => mode == AppMode.bottleMail;

  bool get _bottleDrawingAllowed =>
      _isBottleMail && !session.isDrawingBlocked;

  /// Same sequence as TraceCanvas Listener → GestureDetector.
  void pointerDownOnCanvas() {
    if (_isBottleMail) {
      session.pointerDown();
    }
  }

  void pointerUpOnCanvas() {
    if (_isBottleMail) {
      session.pointerUp();
    }
  }

  void panStart(Offset position) {
    if (_isBottleMail) {
      if (!_bottleDrawingAllowed) return;
      session.panStart(position);
      return;
    }
    canvas.addPoint(position);
  }

  void panUpdate(Offset position) {
    if (_isBottleMail) {
      if (!_bottleDrawingAllowed) return;
      session.panMove(position);
      return;
    }
    canvas.addPoint(position);
  }

  void panEnd() {
    if (_isBottleMail) {
      if (_bottleDrawingAllowed) {
        session.panEnd();
      }
      return;
    }
    canvas.endStroke();
  }

  void drawStroke({
    Offset start = const Offset(120, 200),
    Offset? moveTo,
  }) {
    pointerDownOnCanvas();
    panStart(start);
    if (moveTo != null) {
      panUpdate(moveTo);
    }
    panEnd();
    pointerUpOnCanvas();
  }

  void waitForSendIdle() {
    elapse(bottleSendIdleDuration);
    flushMicrotasks();
  }

  factory BottleProductionHarness.create({
    required void Function(Duration duration) elapse,
    required void Function() flushMicrotasks,
    required dynamic repository,
    BottleSendSurface surface = BottleSendSurface.device,
    DateTime Function()? clock,
  }) {
    final canvas = FakeTraceCanvas();
    late BottleSendFeedback feedback;
    late BottleSendPipeline pipeline;
    late BottleDrawSession session;

    if (surface == BottleSendSurface.virtual) {
      feedback = VirtualBottleSendFeedback();
    } else {
      feedback = RecordingDeviceFeedback();
    }

    pipeline = BottleSendPipeline(
      surface: surface,
      deposit: (points, {required profile, required captureSize}) =>
          repository.depositBottle(
            points,
            profile: profile,
            captureSize: captureSize,
          ),
      resolveProfile: () => TraceProfilePresets.pureFinger,
      captureSize: () => const Size(400, 800),
      feedback: feedback,
      clearCanvas: canvas.clear,
    );

    session = BottleDrawSession(
      clock: clock ?? DateTime.now,
      createTimer: (duration, callback) => Timer(duration, callback),
      pipeline: pipeline,
      onPointDrawn: (point) => canvas.addPoint(point.position),
      onStrokeEnded: (_) => canvas.endStroke(),
      onClearCanvas: canvas.clear,
    );

    return BottleProductionHarness(
      session: session,
      canvas: canvas,
      repository: repository,
      feedback: feedback,
      elapse: elapse,
      flushMicrotasks: flushMicrotasks,
    );
  }
}

class RecordingDeviceFeedback implements BottleSendFeedback {
  int sentCount = 0;
  int discardCount = 0;
  int errorCount = 0;
  Object? lastError;

  @override
  Future<void> onSent() async => sentCount++;

  @override
  Future<void> onDiscarded() async => discardCount++;

  @override
  Future<void> onError(Object error) async {
    errorCount++;
    lastError = error;
  }
}
