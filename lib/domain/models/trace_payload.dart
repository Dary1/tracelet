import 'package:tracelet/domain/models/trace_playback_profile.dart';
import 'package:tracelet/domain/models/trace_point.dart';

/// Decoded bottle trace payload header + points.
class TracePayload {
  const TracePayload({
    required this.points,
    required this.playbackProfile,
    this.isLegacy = false,
  });

  final List<TracePoint> points;
  final TracePlaybackProfile playbackProfile;
  final bool isLegacy;
}
