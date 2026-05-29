import 'package:flutter/material.dart';
import 'package:tracelet/application/visual_cue_notifier.dart';
import 'package:tracelet/presentation/feedback/visual_cue_type.dart';
import 'package:tracelet/presentation/painting/feedback/cues/button_action_cues.dart';
import 'package:tracelet/presentation/painting/feedback/cues/corner_pulse_cue.dart';
import 'package:tracelet/presentation/painting/feedback/cues/message_cues.dart';
import 'package:tracelet/presentation/painting/feedback/cues/name_trace_cues.dart';
import 'package:tracelet/presentation/painting/feedback/cues/overlay_cues.dart';
import 'package:tracelet/presentation/painting/feedback/visual_cue_paint_style.dart';

class VisualCuePainter extends CustomPainter {
  VisualCuePainter({
    required this.state,
    required this.nowMs,
    this.style = VisualCuePaintStyle.standard,
  });

  final VisualCueState state;
  final int nowMs;
  final VisualCuePaintStyle style;

  @override
  void paint(Canvas canvas, Size size) {
    if (!state.isActive || state.cue == null) return;

    final progress = state.progress(nowMs);
    if (progress >= 1) return;

    switch (state.cue!) {
      case VisualCueType.buttonBAction:
        ButtonActionCues.paintButtonB(canvas, size, progress, style);
      case VisualCueType.modeChange:
        ButtonActionCues.paintModeChange(
          canvas,
          size,
          progress,
          style,
          ripples: state.cue!.rippleCount(mode: state.mode),
          enabled: state.enabled,
        );
      case VisualCueType.toggleNotifications:
        CornerPulseCue.paint(
          canvas,
          size,
          progress,
          style.buttonA,
          state.enabled,
          style,
        );
      case VisualCueType.toggleAutoPlay:
      case VisualCueType.toggleAutoContinuous:
        CornerPulseCue.paint(
          canvas,
          size,
          progress,
          style.buttonB,
          state.enabled,
          style,
          right: true,
        );
      case VisualCueType.messagePlayStart:
        MessageCues.paintMessageStart(canvas, size, progress, style);
      case VisualCueType.friendConnected:
        MessageCues.paintFriendConnected(canvas, size, progress, style);
      case VisualCueType.senderRemoved:
        MessageCues.paintSenderRemoved(canvas, size, progress, style);
      case VisualCueType.destinationSwitch:
        MessageCues.paintDestinationSwitch(canvas, size, progress, style);
      case VisualCueType.nameTraceRegistration:
        NameTraceCues.paintRegistration(canvas, size, progress, style);
      case VisualCueType.nameTraceSaved:
        NameTraceCues.paintSaved(canvas, size, progress, style);
      case VisualCueType.settingsTransition:
        OverlayCues.paintSettingsTransition(canvas, size, progress, style);
      case VisualCueType.alert:
        OverlayCues.paintAlert(canvas, size, progress, style);
    }
  }

  @override
  bool shouldRepaint(covariant VisualCuePainter oldDelegate) =>
      oldDelegate.state != state ||
      oldDelegate.nowMs != nowMs ||
      oldDelegate.style != style;
}
