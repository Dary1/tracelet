import 'package:tracelet/domain/models/trace_playback_profile.dart';
import 'package:tracelet/domain/models/trace_point.dart';
import 'package:tracelet/domain/models/user.dart';

/// A haptic trace message received from another user.
///
/// [playbackProfile] is the sender's playback snapshot embedded in the payload
/// header at send time. Playback must use this profile, not the receiver's settings.
class TraceMessage {
  const TraceMessage({
    required this.id,
    required this.sender,
    required this.points,
    required this.receivedAt,
    this.playbackProfile = const TracePlaybackProfile(
      captureWidth: 1,
      captureHeight: 1,
    ),
    this.isLegacyPayload = true,
    this.played = false,
  });

  final String id;
  final TraceUser sender;
  final List<TracePoint> points;
  final TracePlaybackProfile playbackProfile;
  final bool isLegacyPayload;
  final DateTime receivedAt;
  final bool played;

  TraceMessage copyWith({
    String? id,
    TraceUser? sender,
    List<TracePoint>? points,
    TracePlaybackProfile? playbackProfile,
    bool? isLegacyPayload,
    DateTime? receivedAt,
    bool? played,
  }) {
    return TraceMessage(
      id: id ?? this.id,
      sender: sender ?? this.sender,
      points: points ?? this.points,
      playbackProfile: playbackProfile ?? this.playbackProfile,
      isLegacyPayload: isLegacyPayload ?? this.isLegacyPayload,
      receivedAt: receivedAt ?? this.receivedAt,
      played: played ?? this.played,
    );
  }
}
