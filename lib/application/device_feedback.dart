import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tracelet/application/screen_size.dart';
import 'package:tracelet/application/trace_canvas_notifier.dart';
import 'package:tracelet/application/visual_cue_notifier.dart';
import 'package:tracelet/core/haptics.dart';
import 'package:tracelet/domain/hardware/button_input.dart';
import 'package:tracelet/domain/models/app_mode.dart';
import 'package:tracelet/domain/models/trace_message.dart';
import 'package:tracelet/domain/system_traces/system_trace_id.dart';
import 'package:tracelet/presentation/feedback/visual_cue_type.dart';

/// Coordinates haptics, overlay cues, and canvas system traces.
class DeviceFeedback {
  DeviceFeedback(this._ref);

  final Ref _ref;

  Future<void> buttonA({required ButtonGesture gesture}) async {
    switch (gesture) {
      case ButtonGesture.tap:
        await TraceletHaptics.buttonPress();
      case ButtonGesture.longPress:
        await TraceletHaptics.buttonLongPress();
      case ButtonGesture.simultaneousTap:
      case ButtonGesture.simultaneousLongPress:
        await TraceletHaptics.simultaneousPress();
    }
  }

  Future<void> buttonB({required ButtonGesture gesture}) async {
    await buttonA(gesture: gesture);
    if (gesture == ButtonGesture.tap || gesture == ButtonGesture.longPress) {
      overlay(VisualCueType.buttonBAction);
    }
  }

  void overlay(VisualCueType cue, {AppMode? mode, bool enabled = true}) {
    _ref.read(visualCueProvider.notifier).play(cue, mode: mode, enabled: enabled);
  }

  Future<void> trace(
    SystemTraceId id, {
    bool enabled = true,
    AppMode? mode,
    bool clearFirst = true,
  }) async {
    await _ref.read(traceCanvasProvider.notifier).playSystemTrace(
          id,
          _ref.read(screenSizeProvider),
          clearFirst: clearFirst,
        );
  }

  Future<void> toggle({
    required bool enabled,
    required VisualCueType overlayCue,
    required SystemTraceId onTrace,
    required SystemTraceId offTrace,
  }) async {
    overlay(overlayCue, enabled: enabled);
    await trace(enabled ? onTrace : offTrace, enabled: enabled);
  }

  Future<void> alert() async {
    overlay(VisualCueType.alert);
    await trace(SystemTraceId.alert);
  }

  Future<void> playReceivedMessage(
    TraceMessage message, {
    SystemTraceId? intro,
  }) async {
    overlay(VisualCueType.messagePlayStart);
    if (intro != null) {
      await trace(intro);
    }
    await TraceletHaptics.messagePlayback();
    await _ref.read(traceCanvasProvider.notifier).playTrace(
          message.points,
          playbackProfile: message.playbackProfile,
          clearFirst: intro != null,
        );
  }

  Future<void> noMessageFound() async {
    overlay(VisualCueType.alert);
    await trace(SystemTraceId.noMessageFound);
  }
}

final deviceFeedbackProvider = Provider<DeviceFeedback>(
  (ref) => DeviceFeedback(ref),
);
