import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tracelet/application/pressure_input_providers.dart';
import 'package:tracelet/application/auth_providers.dart';
import 'package:tracelet/application/app_state_notifier.dart';
import 'package:tracelet/application/device_feedback.dart';
import 'package:tracelet/application/repository_providers.dart';
import 'package:tracelet/application/screen_size.dart';
import 'package:tracelet/application/trace_canvas_notifier.dart';
import 'package:tracelet/application/trace_profile_resolver.dart';
import 'package:tracelet/domain/input/pressure_capture.dart';
import 'package:tracelet/domain/bottle/bottle_send_feedback.dart';
import 'package:tracelet/domain/bottle/bottle_send_pipeline.dart';
import 'package:tracelet/domain/input/bottle_draw_session.dart';

class BottleDrawNotifier extends Notifier<BottleDrawSession> {
  @override
  BottleDrawSession build() {
    ref.listen(appStateProvider.select((state) => state.mode), (previous, next) {
      state.reset();
    });

    final canvas = ref.read(traceCanvasProvider.notifier);
    final feedback = DeviceBottleSendFeedback(
      playTrace: (id, {clearFirst = true}) =>
          ref.read(deviceFeedbackProvider).trace(id, clearFirst: clearFirst),
    );

    final pipeline = BottleSendPipeline(
      deposit: (points, {required profile, required captureSize}) =>
          ref.read(messageRepositoryProvider).depositBottle(
                points,
                profile: profile,
                captureSize: captureSize,
              ),
      resolveProfile: () =>
          resolveTraceProfile(ref.read(appStateProvider).settings),
      captureSize: () => ref.read(screenSizeProvider),
      feedback: feedback,
      clearCanvas: canvas.clear,
      onAuthRequired: () =>
          ref.read(authNotifierProvider.notifier).revertToGuest(),
    );

    return BottleDrawSession(
      pipeline: pipeline,
      pressureCapture: PressureCapture(
        detector: ref.read(pressureInputDetectorProvider),
        profile: () =>
            resolveTraceProfile(ref.read(appStateProvider).settings).pressure,
      ),
      onPointDrawn: (point) => canvas.addRecordedPoint(point),
      onStrokeEnded: (_) => canvas.endStroke(),
      onClearCanvas: canvas.clear,
    );
  }
}

final bottleDrawSessionProvider =
    NotifierProvider<BottleDrawNotifier, BottleDrawSession>(
  BottleDrawNotifier.new,
);
