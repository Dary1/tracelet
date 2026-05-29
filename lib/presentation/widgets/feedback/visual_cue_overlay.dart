import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tracelet/application/visual_cue_notifier.dart';
import 'package:tracelet/presentation/painting/feedback/visual_cue_painter.dart';
import 'package:tracelet/presentation/painting/feedback/visual_cue_paint_style.dart';
import 'package:tracelet/presentation/theme/tracelet_visual_tokens.dart';

class VisualCueOverlay extends ConsumerStatefulWidget {
  const VisualCueOverlay({super.key});

  @override
  ConsumerState<VisualCueOverlay> createState() => _VisualCueOverlayState();
}

class _VisualCueOverlayState extends ConsumerState<VisualCueOverlay>
    with SingleTickerProviderStateMixin {
  Ticker? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((_) {
      ref.read(visualCueProvider.notifier).tick();
    });
  }

  @override
  void dispose() {
    _ticker?.dispose();
    super.dispose();
  }

  void _syncTicker(VisualCueState cueState) {
    final ticker = _ticker;
    if (ticker == null) return;

    if (cueState.isActive && !ticker.isActive) {
      ticker.start();
    } else if (!cueState.isActive && ticker.isActive) {
      ticker.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cueState = ref.watch(visualCueProvider);
    _syncTicker(cueState);

    if (!cueState.isActive) return const SizedBox.shrink();

    final tokens = TraceletVisualTokens.of(context);
    final style = VisualCuePaintStyle.fromTokens(tokens);

    return IgnorePointer(
      child: CustomPaint(
        painter: VisualCuePainter(
          state: cueState,
          nowMs: DateTime.now().millisecondsSinceEpoch,
          style: style,
        ),
        size: Size.infinite,
      ),
    );
  }
}
