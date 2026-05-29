import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tracelet/application/bottle_draw_notifier.dart';
import 'package:tracelet/application/pressure_input_providers.dart';
import 'package:tracelet/application/trace_canvas_notifier.dart';
import 'package:tracelet/application/trace_canvas_state.dart';
import 'package:tracelet/domain/models/app_mode.dart';

/// Pointer input layer — routes touch events to canvas notifiers.
class TraceCanvasInput extends ConsumerStatefulWidget {
  const TraceCanvasInput({
    super.key,
    required this.child,
    required this.drawingAllowed,
    required this.bottleDrawingAllowed,
    required this.mode,
  });

  final Widget child;
  final bool drawingAllowed;
  final bool bottleDrawingAllowed;
  final AppMode mode;

  @override
  ConsumerState<TraceCanvasInput> createState() => _TraceCanvasInputState();
}

class _TraceCanvasInputState extends ConsumerState<TraceCanvasInput> {
  int? _drawPointerId;

  void _handleDrawStart(Offset position, double hardwarePressure) {
    if (widget.mode == AppMode.bottleMail) {
      if (!widget.bottleDrawingAllowed) return;
      ref.read(bottleDrawSessionProvider).panStart(
            position,
            hardwarePressure: hardwarePressure,
          );
      return;
    }

    ref.read(traceCanvasProvider.notifier).addDrawInput(
          position,
          hardwarePressure: hardwarePressure,
        );
  }

  void _handleDrawMove(Offset position, double hardwarePressure) {
    if (widget.mode == AppMode.bottleMail) {
      if (!widget.bottleDrawingAllowed) return;
      ref.read(bottleDrawSessionProvider).panMove(
            position,
            hardwarePressure: hardwarePressure,
          );
      return;
    }

    ref.read(traceCanvasProvider.notifier).addDrawInput(
          position,
          hardwarePressure: hardwarePressure,
        );
  }

  void _handleDrawEnd() {
    if (widget.mode == AppMode.bottleMail) {
      if (widget.bottleDrawingAllowed) {
        ref.read(bottleDrawSessionProvider).panEnd();
      }
      return;
    }

    ref.read(traceCanvasProvider.notifier).endStroke();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (event) {
        ref.read(pressureInputDetectorProvider.notifier).observe(event.pressure);

        if (widget.mode == AppMode.bottleMail) {
          ref.read(bottleDrawSessionProvider).pointerDown();
        }
        if (!widget.drawingAllowed) return;
        if (widget.mode == AppMode.bottleMail && !widget.bottleDrawingAllowed) {
          return;
        }
        if (_drawPointerId != null) return;

        _drawPointerId = event.pointer;
        _handleDrawStart(event.localPosition, event.pressure);
      },
      onPointerMove: (event) {
        if (event.pointer != _drawPointerId) return;
        ref.read(pressureInputDetectorProvider.notifier).observe(event.pressure);
        _handleDrawMove(event.localPosition, event.pressure);
      },
      onPointerUp: (event) {
        if (widget.mode == AppMode.bottleMail) {
          ref.read(bottleDrawSessionProvider).pointerUp();
        }
        if (event.pointer != _drawPointerId) return;
        _handleDrawEnd();
        _drawPointerId = null;
      },
      onPointerCancel: (event) {
        if (widget.mode == AppMode.bottleMail) {
          ref.read(bottleDrawSessionProvider).pointerUp();
        }
        if (event.pointer != _drawPointerId) return;
        _handleDrawEnd();
        _drawPointerId = null;
      },
      child: widget.child,
    );
  }
}

bool traceCanvasDrawingAllowed(AppMode mode, TraceCanvasState canvas) =>
    !canvas.isPlaying &&
    (mode == AppMode.nameTraceRegistration || mode.isPrimaryMode);

bool traceCanvasBottleDrawingAllowed(WidgetRef ref, AppMode mode) {
  if (mode != AppMode.bottleMail) return true;
  return !ref.read(bottleDrawSessionProvider).isDrawingBlocked;
}
