import 'dart:async';
import 'dart:ui';

import 'package:tracelet/domain/bottle/bottle_send_feedback.dart';
import 'package:tracelet/domain/bottle/bottle_send_pipeline.dart';
import 'package:tracelet/domain/input/bottle_draw_session.dart';
import 'package:tracelet/domain/models/trace_point.dart';
import 'package:tracelet/domain/models/trace_profile.dart';
import 'package:tracelet/domain/services/bottle_send_coordinator.dart';

/// Headless bottle input using the same pipeline/feedback split as production.
class VirtualBottleHandset {
  VirtualBottleHandset._({
    required this.session,
    required this.pipeline,
    required this.feedback,
    required this.elapse,
    required this.flushMicrotasks,
  });

  final BottleDrawSession session;
  final BottleSendPipeline pipeline;
  final VirtualBottleSendFeedback feedback;
  final void Function(Duration duration) elapse;
  final void Function() flushMicrotasks;

  factory VirtualBottleHandset({
    required BottleDepositFn deposit,
    required void Function(Duration duration) elapse,
    required void Function() flushMicrotasks,
    DateTime Function()? clock,
    TraceProfile Function()? resolveProfile,
    Size Function()? captureSize,
  }) {
    final feedback = VirtualBottleSendFeedback();
    final pipeline = BottleSendPipeline(
      surface: BottleSendSurface.virtual,
      deposit: deposit,
      resolveProfile: resolveProfile ?? () => TraceProfilePresets.pureFinger,
      captureSize: captureSize ?? () => const Size(400, 800),
      feedback: feedback,
      clearCanvas: () {},
    );
    final session = BottleDrawSession(
      clock: clock ?? DateTime.now,
      createTimer: (duration, callback) => Timer(duration, callback),
      pipeline: pipeline,
      onDiscard: () => pipeline.discard(),
    );
    return VirtualBottleHandset._(
      session: session,
      pipeline: pipeline,
      feedback: feedback,
      elapse: elapse,
      flushMicrotasks: flushMicrotasks,
    );
  }

  void fingerDown({Offset at = const Offset(120, 200)}) {
    session.pointerDown();
    session.panStart(at);
  }

  void fingerMove(Offset to) => session.panMove(to);

  void fingerUp() {
    session.panEnd();
    session.pointerUp();
  }

  void drawStroke({
    Offset start = const Offset(120, 200),
    Offset? moveTo,
  }) {
    fingerDown(at: start);
    if (moveTo != null) fingerMove(moveTo);
    fingerUp();
  }

  void secondFingerDown() => session.pointerDown();

  void wait(Duration duration) {
    elapse(duration);
    flushMicrotasks();
  }

  void waitForSendIdle() => wait(bottleSendIdleDuration);

  void waitForDiscardIdle() => wait(bottleSendIdleDuration);

  List<TracePoint> get drawnPoints => session.points;

  int get sentCount => feedback.sentCount;

  int get discardCount => feedback.discardCount;
}
