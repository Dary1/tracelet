import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:tracelet/domain/hardware/button_input.dart';
import 'package:tracelet/presentation/painting/hardware/hardware_button_ripple_painter.dart';
import 'package:tracelet/presentation/painting/hardware/hardware_button_style.dart';
import 'package:tracelet/presentation/theme/tracelet_visual_tokens.dart';

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

  _ResolvedStyle _resolveStyle(BuildContext context) {
    final tokens = TraceletVisualTokens.of(context);
    final useTokens = identical(widget.style, HardwareButtonStyle.standard);

    return _ResolvedStyle(
      fillAlpha: widget.pressed
          ? (useTokens ? tokens.hardwarePressedAlpha : widget.style.pressedAlpha)
          : (useTokens ? tokens.hardwareIdleAlpha : widget.style.idleAlpha),
      borderAlpha: widget.pressed
          ? widget.style.pressedBorderAlpha
          : widget.style.idleBorderAlpha,
      highlightAlpha: widget.pressed
          ? (useTokens
              ? tokens.hardwareHighlightPressedAlpha
              : widget.style.pressedHighlightAlpha)
          : (useTokens
              ? tokens.hardwareHighlightIdleAlpha
              : widget.style.idleHighlightAlpha),
      borderWidth: widget.pressed
          ? widget.style.pressedBorderWidth
          : widget.style.idleBorderWidth,
    );
  }

  @override
  Widget build(BuildContext context) {
    final resolved = _resolveStyle(context);
    final fromCorner = widget.button == VirtualButton.a
        ? Alignment.bottomLeft
        : Alignment.bottomRight;
    final toCorner = widget.button == VirtualButton.a
        ? Alignment.topRight
        : Alignment.topLeft;

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
                begin: fromCorner,
                end: toCorner,
                colors: [
                  widget.color.withValues(alpha: resolved.fillAlpha),
                  widget.color.withValues(alpha: resolved.fillAlpha * 0.55),
                  widget.color.withValues(alpha: resolved.fillAlpha * 0.35),
                ],
                stops: const [0, 0.55, 1],
              ),
              border: Border.all(
                color: widget.color.withValues(alpha: resolved.borderAlpha),
                width: resolved.borderWidth,
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
                    Colors.white.withValues(alpha: resolved.highlightAlpha),
                    Colors.transparent,
                  ],
                  stops: const [0, 0.5],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: widget.borderRadius,
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(
                      alpha: widget.pressed ? 0.18 : 0.08,
                    ),
                    Colors.transparent,
                  ],
                  stops: const [0, 0.35],
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

class _ResolvedStyle {
  const _ResolvedStyle({
    required this.fillAlpha,
    required this.borderAlpha,
    required this.highlightAlpha,
    required this.borderWidth,
  });

  final double fillAlpha;
  final double borderAlpha;
  final double highlightAlpha;
  final double borderWidth;
}
