import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:tracelet/domain/system_traces/system_trace_stroke.dart';

class SystemTracePoint {
  const SystemTracePoint({required this.x, required this.y, this.t = 0});

  final double x;
  final double y;
  final int t;

  factory SystemTracePoint.fromJson(Map<String, dynamic> json) {
    return SystemTracePoint(
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      t: (json['t'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {'x': x, 'y': y, if (t != 0) 't': t};

  Offset toOffset() => Offset(x, y);
}

class SystemTraceStrokeDefinition {
  const SystemTraceStrokeDefinition({
    required this.points,
    this.color,
    this.opacity = 1.0,
  });

  final List<SystemTracePoint> points;
  final Color? color;
  final double opacity;

  factory SystemTraceStrokeDefinition.fromJson(Map<String, dynamic> json) {
    return SystemTraceStrokeDefinition(
      color: _parseColor(json['color'] as String?),
      opacity: (json['opacity'] as num?)?.toDouble() ?? 1.0,
      points: (json['points'] as List<dynamic>)
          .map((point) => SystemTracePoint.fromJson(point as Map<String, dynamic>))
          .toList(growable: false),
    );
  }

  SystemTraceStroke toStroke() {
    final strokeColor = color?.withValues(alpha: opacity.clamp(0.0, 1.0));
    return SystemTraceStroke(
      color: strokeColor,
      points: points.map((point) => point.toOffset()).toList(growable: false),
    );
  }
}

class SystemTraceDocument {
  const SystemTraceDocument({
    required this.id,
    required this.kind,
    required this.coordinateSpace,
    required this.fadeDurationMs,
    required this.strokes,
  });

  final String id;
  final String kind;
  final String coordinateSpace;
  final int fadeDurationMs;
  final List<SystemTraceStrokeDefinition> strokes;

  Duration get fadeDuration => Duration(milliseconds: fadeDurationMs);

  bool get isNormalized => coordinateSpace == 'normalized';

  factory SystemTraceDocument.fromJson(Map<String, dynamic> json) {
    return SystemTraceDocument(
      id: json['id'] as String,
      kind: json['kind'] as String? ?? 'system',
      coordinateSpace: json['coordinateSpace'] as String? ?? 'normalized',
      fadeDurationMs: (json['fadeDurationMs'] as num?)?.toInt() ?? 2200,
      strokes: (json['strokes'] as List<dynamic>)
          .map(
            (stroke) => SystemTraceStrokeDefinition.fromJson(
              stroke as Map<String, dynamic>,
            ),
          )
          .toList(growable: false),
    );
  }

  List<SystemTraceStroke> toStrokes() =>
      strokes.map((stroke) => stroke.toStroke()).toList(growable: false);
}

Color? _parseColor(String? value) {
  if (value == null || value.isEmpty) return null;
  final hex = value.replaceFirst('#', '');
  if (hex.length == 6) {
    return Color(int.parse('FF$hex', radix: 16));
  }
  if (hex.length == 8) {
    return Color(int.parse(hex, radix: 16));
  }
  return null;
}
