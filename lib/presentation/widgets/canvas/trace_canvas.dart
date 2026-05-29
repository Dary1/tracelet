import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tracelet/application/app_state_notifier.dart';
import 'package:tracelet/application/trace_canvas_notifier.dart';
import 'package:tracelet/application/trace_canvas_state.dart';
import 'package:tracelet/presentation/widgets/canvas/trace_canvas_input.dart';
import 'package:tracelet/presentation/widgets/canvas/trace_canvas_layers.dart';

class TraceCanvas extends ConsumerStatefulWidget {
  const TraceCanvas({super.key});

  @override
  ConsumerState<TraceCanvas> createState() => _TraceCanvasState();
}

class _TraceCanvasState extends ConsumerState<TraceCanvas>
    with SingleTickerProviderStateMixin {
  Ticker? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((_) {
      ref.read(traceCanvasProvider.notifier).onFrame();
    });
  }

  @override
  void dispose() {
    _ticker?.dispose();
    super.dispose();
  }

  void _syncTicker(TraceCanvasState canvasState) {
    final ticker = _ticker;
    if (ticker == null) return;

    if (canvasState.needsAnimation && !ticker.isActive) {
      ticker.start();
    } else if (!canvasState.needsAnimation && ticker.isActive) {
      ticker.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final canvasState = ref.watch(traceCanvasProvider);
    final mode = ref.watch(appStateProvider.select((state) => state.mode));
    final drawingAllowed = traceCanvasDrawingAllowed(mode, canvasState);
    final bottleDrawingAllowed =
        drawingAllowed && traceCanvasBottleDrawingAllowed(ref, mode);

    _syncTicker(canvasState);

    return RepaintBoundary(
      child: TraceCanvasInput(
        mode: mode,
        drawingAllowed: drawingAllowed,
        bottleDrawingAllowed: bottleDrawingAllowed,
        child: TraceCanvasLayers(
          points: canvasState.points,
          repaintTick: canvasState.repaintTick,
          fadeDuration: canvasState.fadeDuration,
          pressureProfile: canvasState.pressureProfile,
          particles: canvasState.particles,
          particleStyle: canvasState.particleStyle,
        ),
      ),
    );
  }
}
