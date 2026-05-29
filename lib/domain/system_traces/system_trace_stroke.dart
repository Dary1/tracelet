import 'dart:ui';

import 'package:flutter/material.dart';

/// One stroke segment in a system trace, using normalized canvas coordinates.
class SystemTraceStroke {
  const SystemTraceStroke({
    required this.points,
    this.color,
  });

  final List<Offset> points;
  final Color? color;
}
