import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tracelet/application/app_state_notifier.dart';
import 'package:tracelet/domain/hardware/button_input.dart';
import 'package:tracelet/presentation/painting/hardware/hardware_button_layout.dart';
import 'package:tracelet/presentation/theme/tracelet_shapes.dart';
import 'package:tracelet/presentation/theme/tracelet_visual_tokens.dart';
import 'package:tracelet/presentation/widgets/hardware/hardware_button_zone.dart';

/// Bottom-corner touch zones simulating physical buttons A (blue) and B (green).
class VirtualHardwareControls extends ConsumerStatefulWidget {
  const VirtualHardwareControls({
    super.key,
    required this.child,
  });

  final Widget child;

  static const longPressDuration = Duration(milliseconds: 500);

  @override
  ConsumerState<VirtualHardwareControls> createState() =>
      _VirtualHardwareControlsState();
}

class _VirtualHardwareControlsState
    extends ConsumerState<VirtualHardwareControls> {
  int _aActivePointers = 0;
  int _bActivePointers = 0;
  DateTime? _bothActiveSince;
  bool _aLongFired = false;
  bool _bLongFired = false;
  bool _bothLongFired = false;
  Timer? _aLongTimer;
  Timer? _bLongTimer;
  Timer? _bothLongTimer;

  bool get _bothActive => _aActivePointers > 0 && _bActivePointers > 0;
  bool get _aPressed => _aActivePointers > 0;
  bool get _bPressed => _bActivePointers > 0;

  @override
  void dispose() {
    _cancelAllTimers();
    super.dispose();
  }

  void _cancelAllTimers() {
    _aLongTimer?.cancel();
    _bLongTimer?.cancel();
    _bothLongTimer?.cancel();
    _aLongTimer = null;
    _bLongTimer = null;
    _bothLongTimer = null;
  }

  void _onZoneDown(VirtualButton button) {
    setState(() {
      if (button == VirtualButton.a) {
        _aActivePointers++;
      } else {
        _bActivePointers++;
      }
    });

    if (button == VirtualButton.a) {
      if (_bothActive) {
        _enterBothActiveMode();
      } else if (_bActivePointers == 0) {
        _startSoloLongTimer(VirtualButton.a);
      }
    } else {
      if (_bothActive) {
        _enterBothActiveMode();
      } else if (_aActivePointers == 0) {
        _startSoloLongTimer(VirtualButton.b);
      }
    }
  }

  void _onZoneUp(VirtualButton button) {
    if (button == VirtualButton.a) {
      _aActivePointers = (_aActivePointers - 1).clamp(0, 999);
    } else {
      _bActivePointers = (_bActivePointers - 1).clamp(0, 999);
    }
    setState(() {});

    if (_bothActiveSince != null && !_bothActive) {
      _resolveBothRelease();
      return;
    }

    if (button == VirtualButton.a && _aActivePointers == 0) {
      _aLongTimer?.cancel();
      if (!_aLongFired && _bActivePointers == 0) {
        _dispatch(VirtualButton.a, ButtonGesture.tap);
      }
      _aLongFired = false;
    }

    if (button == VirtualButton.b && _bActivePointers == 0) {
      _bLongTimer?.cancel();
      if (!_bLongFired && _aActivePointers == 0) {
        _dispatch(VirtualButton.b, ButtonGesture.tap);
      }
      _bLongFired = false;
    }
  }

  void _enterBothActiveMode() {
    _bothActiveSince ??= DateTime.now();
    _aLongTimer?.cancel();
    _bLongTimer?.cancel();
    _bothLongTimer ??= Timer(VirtualHardwareControls.longPressDuration, () {
      if (_bothActive && !_bothLongFired) {
        _bothLongFired = true;
        _dispatch(VirtualButton.a, ButtonGesture.simultaneousLongPress);
      }
    });
  }

  void _resolveBothRelease() {
    _bothLongTimer?.cancel();
    _bothLongTimer = null;

    if (!_bothLongFired) {
      final held = DateTime.now().difference(_bothActiveSince!);
      if (held < VirtualHardwareControls.longPressDuration) {
        _dispatch(VirtualButton.a, ButtonGesture.simultaneousTap);
      }
    }

    _bothActiveSince = null;
    _bothLongFired = false;
    _aLongFired = false;
    _bLongFired = false;
  }

  void _startSoloLongTimer(VirtualButton button) {
    final timer = Timer(VirtualHardwareControls.longPressDuration, () {
      if (_bothActive) return;

      if (button == VirtualButton.a && _aActivePointers > 0) {
        _aLongFired = true;
        _dispatch(VirtualButton.a, ButtonGesture.longPress);
      } else if (button == VirtualButton.b && _bActivePointers > 0) {
        _bLongFired = true;
        _dispatch(VirtualButton.b, ButtonGesture.longPress);
      }
    });

    if (button == VirtualButton.a) {
      _aLongTimer = timer;
    } else {
      _bLongTimer = timer;
    }
  }

  void _dispatch(VirtualButton button, ButtonGesture gesture) {
    ref.read(appStateProvider.notifier).handleButtonAction(button, gesture);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = TraceletVisualTokens.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final zoneWidth =
            constraints.maxWidth * HardwareButtonLayout.zoneWidthFraction;
        final zoneHeight =
            constraints.maxHeight * HardwareButtonLayout.zoneHeightFraction;

        return Stack(
          fit: StackFit.expand,
          children: [
            widget.child,
            Positioned(
              left: 0,
              bottom: 0,
              width: zoneWidth,
              height: zoneHeight,
              child: HardwareButtonZone(
                color: tokens.buttonA,
                pressed: _aPressed,
                button: VirtualButton.a,
                borderRadius: TraceletShapes.hardwareButtonA,
                onDown: () => _onZoneDown(VirtualButton.a),
                onUp: () => _onZoneUp(VirtualButton.a),
              ),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              width: zoneWidth,
              height: zoneHeight,
              child: HardwareButtonZone(
                color: tokens.buttonB,
                pressed: _bPressed,
                button: VirtualButton.b,
                borderRadius: TraceletShapes.hardwareButtonB,
                onDown: () => _onZoneDown(VirtualButton.b),
                onUp: () => _onZoneUp(VirtualButton.b),
              ),
            ),
          ],
        );
      },
    );
  }
}
