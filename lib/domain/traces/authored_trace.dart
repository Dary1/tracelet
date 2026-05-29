import 'package:tracelet/domain/models/system_trace.dart';
import 'package:tracelet/domain/models/trace_playback_profile.dart';
import 'package:tracelet/domain/models/trace_point.dart';

/// Common supertype for stored trace geometry played back on the canvas.
sealed class AuthoredTrace {
  List<TracePoint> get points;
}

/// User bottle message: normalized points + sender playback snapshot.
final class MessageAuthoredTrace extends AuthoredTrace {
  MessageAuthoredTrace({
    required this.points,
    required this.playbackProfile,
  });

  @override
  final List<TracePoint> points;
  final TracePlaybackProfile playbackProfile;
}

/// Built-in system trace asset: normalized points, user profile at play time.
final class SystemAuthoredTrace extends AuthoredTrace {
  SystemAuthoredTrace({
    required this.document,
    required this.points,
  });

  final SystemTraceDocument document;
  @override
  final List<TracePoint> points;
}
