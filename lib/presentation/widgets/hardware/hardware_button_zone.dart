import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:tracelet/domain/hardware/button_input.dart';
import 'package:tracelet/presentation/painting/hardware/hardware_button_layout.dart';
import 'package:tracelet/presentation/painting/hardware/hardware_button_ripple_painter.dart';
import 'package:tracelet/presentation/painting/hardware/hardware_button_style.dart';

/// Styled hit target for one virtual hardware button corner.
class HardwareButtonZone extends StatefulWidget {
  const HardwareButtonZone({
    super.key,
    required this.color,
    required this.pressed,
    required this.button,
    required this.borderRadius,
    required this.onDown,
    required this.onUp,
    this.style = HardwareButtonStyle.standard,
  });

  final Color color;
  final bool pressed;
  final VirtualButton button;
  final BorderRadius borderRadius;
  final VoidCallback onDown;
  final VoidCallback onUp;
  final HardwareButtonStyle style;

  @override
  State<HardwareButtonZone> createState() => _HardwareButtonZoneState();
}

class _HardwareButtonZoneState extends State<HardwareButtonZone>
    with SingleTickerProviderStateMixin {
  Ticker? _rippleTicker;
  double _rippleProgress = 0;

  @override
  void didUpdateWidget(covariant HardwareButtonZone oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.pressed && !oldWidget.pressed) {
      _startRipple();
    }
  }

  @override
  void dispose() {
    _rippleTicker?.dispose();
    super.dispose();
  }

  void _startRipple() {
    _rippleProgress = 0;
    _rippleTicker?.dispose();
    _rippleTicker = createTicker((elapsed) {
      final durationMs = widget.style.rippleDurationMs.toDouble();
      final progress = elapsed.inMilliseconds / durationMs;
      if (progress >= 1) {
        _rippleTicker?.stop();
        setState(() => _rippleProgress = 0);
        return;
      }
      setState(() => _rippleProgress = progress);
    })..start();
  }

  @override
  Widget build(BuildContext context) {
    final fillAlpha = widget.pressed
        ? widget.style.pressedAlpha
        : widget.style.idleAlpha;
    final borderAlpha = widget.pressed
        ? widget.style.pressedBorderAlpha
        : widget.style.idleBorderAlpha;
    final highlightAlpha = widget.pressed
        ? widget.style.pressedHighlightAlpha
        : widget.style.idleHighlightAlpha;

    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (_) => widget.onDown(),
      onPointerUp: (_) => widget.onUp(),
      onPointerCancel: (_) => widget.onUp(),
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: widget.borderRadius,
              gradient: LinearGradient(
                begin: widget.button == VirtualButton.a
                    ? Alignment.bottomLeft
                    : Alignment.bottomRight,
                end: widget.button == VirtualButton.a
                    ? Alignment.topRight
                    : Alignment.topLeft,
                colors: [
                  widget.color.withValues(alpha: fillAlpha),
                  widget.color.withValues(alpha: fillAlpha * 0.65),
                ],
              ),
              border: Border.all(
                color: widget.color.withValues(alpha: borderAlpha),
                width: widget.pressed
                    ? widget.style.pressedBorderWidth
                    : widget.style.idleBorderWidth,
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: widget.borderRadius,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: highlightAlpha),
                    Colors.transparent,
                  ],
                  stops: const [0, 0.45],
                ),
              ),
            ),
          ),
          if (_rippleProgress > 0)
            CustomPaint(
              painter: HardwareButtonRipplePainter(
                color: widget.color,
                progress: _rippleProgress,
                fromRight: widget.button == VirtualButton.b,
                style: widget.style,
              ),
            ),
        ],
      ),
    );
  }
}
