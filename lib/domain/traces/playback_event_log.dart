/// One step in a realtime trace replay (process, not final canvas).
sealed class PlaybackEvent {
  const PlaybackEvent(this.elapsedMs);

  final int elapsedMs;
}

final class PlaybackBegin extends PlaybackEvent {
  const PlaybackBegin(super.elapsedMs);
}

final class PlaybackWait extends PlaybackEvent {
  const PlaybackWait(super.elapsedMs, this.delayMs);

  final int delayMs;
}

final class PlaybackPoint extends PlaybackEvent {
  const PlaybackPoint(
    super.elapsedMs, {
    required this.x,
    required this.y,
    required this.pressure,
    required this.pointIndex,
  });

  final double x;
  final double y;
  final double pressure;
  final int pointIndex;
}

final class PlaybackBreak extends PlaybackEvent {
  const PlaybackBreak(super.elapsedMs);
}

final class PlaybackEnd extends PlaybackEvent {
  const PlaybackEnd(super.elapsedMs);
}

class PlaybackEventLog {
  PlaybackEventLog(this.events);

  final List<PlaybackEvent> events;

  /// Same replay process: event kinds, waits, and point geometry — not wall clock.
  bool sameProcessAs(PlaybackEventLog other) {
    if (events.length != other.events.length) return false;
    for (var i = 0; i < events.length; i++) {
      if (!_sameShape(events[i], other.events[i])) return false;
    }
    return true;
  }

  static bool _sameShape(PlaybackEvent a, PlaybackEvent b) {
    return switch (a) {
      PlaybackBegin() => b is PlaybackBegin,
      PlaybackEnd() => b is PlaybackEnd,
      PlaybackBreak() => b is PlaybackBreak,
      PlaybackWait() => b is PlaybackWait && a.delayMs == b.delayMs,
      PlaybackPoint() =>
        b is PlaybackPoint &&
            _near(a.x, b.x) &&
            _near(a.y, b.y) &&
            _near(a.pressure, b.pressure) &&
            a.pointIndex == b.pointIndex,
    };
  }

  @override
  bool operator ==(Object other) {
    if (other is! PlaybackEventLog || other.events.length != events.length) {
      return false;
    }
    for (var i = 0; i < events.length; i++) {
      if (events[i].runtimeType != other.events[i].runtimeType) return false;
      final a = events[i];
      final b = other.events[i];
      if (a.elapsedMs != b.elapsedMs) return false;
      if (!_sameShape(a, b)) return false;
    }
    return true;
  }

  static bool _near(double a, double b) => (a - b).abs() < 0.05;
}
