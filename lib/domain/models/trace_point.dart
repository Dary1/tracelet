import 'dart:ui';

import 'package:flutter/material.dart';

/// A single point on the trace canvas with a timestamp for fade logic.
class TracePoint {
  const TracePoint({
    required this.position,
    required this.timestamp,
    this.isStrokeBreak = false,
    this.color,
    this.pressure,
  });

  /// Sentinel position marking the end of a stroke segment.
  static const Offset strokeBreak = Offset(double.infinity, double.infinity);

  final Offset position;
  final DateTime timestamp;
  final bool isStrokeBreak;
  final Color? color;

  /// Normalized stroke intensity 0–1 (hardware or speed-derived).
  final double? pressure;

  bool get isBreak => isStrokeBreak || position == strokeBreak;

  double get effectivePressure => pressure ?? 1.0;

  TracePoint copyWith({
    Offset? position,
    DateTime? timestamp,
    bool? isStrokeBreak,
    Color? color,
    double? pressure,
  }) {
    return TracePoint(
      position: position ?? this.position,
      timestamp: timestamp ?? this.timestamp,
      isStrokeBreak: isStrokeBreak ?? this.isStrokeBreak,
      color: color ?? this.color,
      pressure: pressure ?? this.pressure,
    );
  }
}
