import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tracelet/application/app_state_notifier.dart';
import 'package:tracelet/application/screen_size.dart';
import 'package:tracelet/presentation/screens/settings_screen.dart';
import 'package:tracelet/presentation/widgets/canvas/trace_canvas.dart';
import 'package:tracelet/presentation/widgets/common/tracelet_scaffold.dart';
import 'package:tracelet/presentation/widgets/feedback/visual_cue_overlay.dart';
import 'package:tracelet/presentation/widgets/hardware/virtual_hardware_controls.dart';

class TraceCanvasScreen extends ConsumerWidget {
  const TraceCanvasScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(bootstrapProvider);

    ref.listen<bool>(openSettingsProvider, (previous, next) {
      if (!next) return;
      ref.read(openSettingsProvider.notifier).state = false;
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
      );
    });

    return TraceletCanvasScaffold(
      body: _ScreenSizeScope(
        child: VirtualHardwareControls(
          child: const Stack(
            fit: StackFit.expand,
            children: [
              TraceCanvas(),
              VisualCueOverlay(),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScreenSizeScope extends ConsumerStatefulWidget {
  const _ScreenSizeScope({required this.child});

  final Widget child;

  @override
  ConsumerState<_ScreenSizeScope> createState() => _ScreenSizeScopeState();
}

class _ScreenSizeScopeState extends ConsumerState<_ScreenSizeScope> {
  Size? _pendingSize;

  void _scheduleSizeUpdate(Size size) {
    if (_pendingSize == size) return;
    _pendingSize = size;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _pendingSize != size) return;
      final current = ref.read(screenSizeProvider);
      if (current != size) {
        ref.read(screenSizeProvider.notifier).state = size;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _scheduleSizeUpdate(constraints.biggest);
        return widget.child;
      },
    );
  }
}
