import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tracelet/domain/models/app_mode.dart';
import 'package:tracelet/presentation/feedback/visual_cue_type.dart';

class VisualCueState {
  const VisualCueState({
    this.cue,
    this.startedAtMs,
    this.mode,
    this.enabled = true,
    this.frame = 0,
  });

  final VisualCueType? cue;
  final int? startedAtMs;
  final AppMode? mode;
  final bool enabled;
  final int frame;

  bool get isActive => cue != null && startedAtMs != null;

  double progress(int nowMs) {
    if (!isActive) return 0;
    final elapsed = nowMs - startedAtMs!;
    final durationMs = cue!.duration.inMilliseconds;
    if (durationMs <= 0) return 1;
    return (elapsed / durationMs).clamp(0.0, 1.0);
  }

  bool isComplete(int nowMs) {
    if (!isActive) return true;
    return nowMs - startedAtMs! >= cue!.duration.inMilliseconds;
  }

  VisualCueState copyWith({int? frame, bool clear = false}) {
    if (clear) return const VisualCueState();
    return VisualCueState(
      cue: cue,
      startedAtMs: startedAtMs,
      mode: mode,
      enabled: enabled,
      frame: frame ?? this.frame,
    );
  }
}

class VisualCueNotifier extends Notifier<VisualCueState> {
  @override
  VisualCueState build() => const VisualCueState();

  void play(VisualCueType cue, {AppMode? mode, bool enabled = true}) {
    state = VisualCueState(
      cue: cue,
      startedAtMs: DateTime.now().millisecondsSinceEpoch,
      mode: mode,
      enabled: enabled,
    );
  }

  void tick() {
    if (!state.isActive) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (state.isComplete(now)) {
      state = const VisualCueState();
      return;
    }
    state = state.copyWith(frame: state.frame + 1);
  }
}

final visualCueProvider =
    NotifierProvider<VisualCueNotifier, VisualCueState>(VisualCueNotifier.new);
