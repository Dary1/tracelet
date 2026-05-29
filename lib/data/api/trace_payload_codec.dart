import 'dart:ui';

import 'package:tracelet/domain/models/trace_coordinate_space.dart';
import 'package:tracelet/domain/models/trace_message.dart';
import 'package:tracelet/domain/models/trace_payload.dart';
import 'package:tracelet/domain/models/trace_playback_profile.dart';
import 'package:tracelet/domain/models/trace_point.dart';
import 'package:tracelet/domain/models/trace_profile.dart';
import 'package:tracelet/domain/models/trace_profile_preset.dart';
import 'package:tracelet/domain/models/user.dart';

abstract final class TracePayloadCodec {
  /// Encodes normalized points plus a slim playback snapshot (v2).
  static Map<String, dynamic> encodePayload({
    required List<TracePoint> points,
    required TracePlaybackProfile playback,
  }) {
    return {
      'profileVersion': TracePlaybackProfile.currentVersion,
      'playback': playback.toJson(),
      'points': _encodePointList(points),
    };
  }

  static Map<String, dynamic> encodePoints(List<TracePoint> points) {
    return {'points': _encodePointList(points)};
  }

  static TracePayload decodePayload(Object? raw) {
    if (raw is! Map<String, dynamic>) {
      return TracePayload(
        points: const [],
        playbackProfile: TracePlaybackProfile.fromJson(null),
        isLegacy: true,
      );
    }

    final version = (raw['profileVersion'] as num?)?.toInt();
    if (version == TracePlaybackProfile.currentVersion &&
        raw['playback'] is Map<String, dynamic>) {
      return TracePayload(
        points: decodePoints(raw),
        playbackProfile: TracePlaybackProfile.fromJson(
          raw['playback'] as Map<String, dynamic>,
          profileVersion: TracePlaybackProfile.currentVersion,
        ),
        isLegacy: false,
      );
    }

    final hasLegacyHeader = raw.containsKey('profile') ||
        raw.containsKey('profileVersion') ||
        raw.containsKey('coordinateSpace');

    if (!hasLegacyHeader && raw['points'] == null) {
      return TracePayload(
        points: const [],
        playbackProfile: TracePlaybackProfile.fromJson(null),
        isLegacy: true,
      );
    }

    if (!hasLegacyHeader) {
      return TracePayload(
        points: decodePoints(raw),
        playbackProfile: TracePlaybackProfile.fromJson(null),
        isLegacy: true,
      );
    }

    final legacyProfile = _decodeLegacyTraceProfile(raw);
    final capture = raw['captureSize'] as Map<String, dynamic>?;
    final profileCapture =
        legacyProfileJsonCapture(raw['profile'] as Map<String, dynamic>?);
    final captureW =
        (capture?['w'] as num?)?.toDouble() ?? profileCapture?.$1 ?? 1.0;
    final captureH =
        (capture?['h'] as num?)?.toDouble() ?? profileCapture?.$2 ?? 1.0;
    final coordinateSpace = raw['coordinateSpace'] == 'normalized' ||
            _legacyCoordinateSpace(raw['profile'] as Map<String, dynamic>?) ==
                TraceCoordinateSpace.normalized
        ? TraceCoordinateSpace.normalized
        : TraceCoordinateSpace.absolute;

    return TracePayload(
      points: decodePoints(raw),
      playbackProfile: TracePlaybackProfile.fromLegacyPayload(
        preset: legacyProfile.preset,
        captureWidth: captureW,
        captureHeight: captureH,
        coordinateSpace: coordinateSpace,
        particles: legacyProfile.particles,
        pressure: legacyProfile.pressure,
      ),
      isLegacy: true,
    );
  }

  static TraceProfile _decodeLegacyTraceProfile(Map<String, dynamic> raw) {
    final profileJson = raw['profile'] as Map<String, dynamic>?;
    var profile = TraceProfile.fromJson(profileJson);
    if (profileJson == null) {
      profile = profile.copyWith(
        preset: TraceProfilePreset.fromJson(raw['preset']?.toString()),
      );
    }
    return profile;
  }

  static (double, double)? legacyProfileJsonCapture(Map<String, dynamic>? json) {
    if (json == null) return null;
    final capture = json['captureSize'] as Map<String, dynamic>?;
    if (capture == null) return null;
    return (
      (capture['w'] as num?)?.toDouble() ?? 1.0,
      (capture['h'] as num?)?.toDouble() ?? 1.0,
    );
  }

  static TraceCoordinateSpace _legacyCoordinateSpace(Map<String, dynamic>? json) {
    if (json == null) return TraceCoordinateSpace.absolute;
    final spatial = json['spatial'] as Map<String, dynamic>?;
    final raw = spatial?['coordinateSpace']?.toString() ?? json['coordinateSpace']?.toString();
    return raw == 'normalized'
        ? TraceCoordinateSpace.normalized
        : TraceCoordinateSpace.absolute;
  }

  static List<TracePoint> decodePoints(Object? payload) {
    if (payload is! Map<String, dynamic>) return const [];
    final rawPoints = payload['points'];
    if (rawPoints is! List) return const [];

    final points = <TracePoint>[];
    for (final entry in rawPoints) {
      if (entry is! Map) continue;
      final isBreak = entry['break'] == true;
      final timestamp = DateTime.fromMillisecondsSinceEpoch(
        (entry['t'] as num?)?.toInt() ?? 0,
      );
      if (isBreak) {
        points.add(
          TracePoint(
            position: TracePoint.strokeBreak,
            timestamp: timestamp,
            isStrokeBreak: true,
          ),
        );
        continue;
      }

      points.add(
        TracePoint(
          position: Offset(
            (entry['x'] as num?)?.toDouble() ?? 0,
            (entry['y'] as num?)?.toDouble() ?? 0,
          ),
          timestamp: timestamp,
          color: _parseColor(entry['color']?.toString()),
          pressure: (entry['p'] as num?)?.toDouble(),
        ),
      );
    }
    return points;
  }

  static TraceMessage messageFromBottle({
    required Map<String, dynamic> body,
    required DateTime receivedAt,
  }) {
    final senderId = body['senderUserId']?.toString() ?? 'unknown';
    final payloadRaw = body['payload'];
    final decoded = decodePayload(
      payloadRaw is Map<String, dynamic> ? payloadRaw : null,
    );

    return TraceMessage(
      id: 'bottle-${receivedAt.millisecondsSinceEpoch}',
      sender: TraceUser(
        id: senderId,
        displayName: body['senderDisplayName']?.toString() ?? senderId,
      ),
      points: decoded.points,
      playbackProfile: decoded.playbackProfile,
      isLegacyPayload: decoded.isLegacy,
      receivedAt: receivedAt,
    );
  }

  static List<Map<String, dynamic>> _encodePointList(List<TracePoint> points) {
    return points.map((point) {
      if (point.isBreak) {
        return {'break': true, 't': point.timestamp.millisecondsSinceEpoch};
      }
      return {
        'x': point.position.dx,
        'y': point.position.dy,
        't': point.timestamp.millisecondsSinceEpoch,
        if (point.color != null)
          'color':
              '#${(point.color!.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}',
        if (point.pressure != null) 'p': point.pressure,
      };
    }).toList();
  }

  static List<({double dx, double dy, int msSinceStart})> decodeNameTrace(
    Object? raw,
  ) {
    if (raw is! List) return const [];
    final samples = <({double dx, double dy, int msSinceStart})>[];
    for (final entry in raw) {
      if (entry is! Map) continue;
      samples.add((
        dx: (entry['dx'] as num?)?.toDouble() ?? 0,
        dy: (entry['dy'] as num?)?.toDouble() ?? 0,
        msSinceStart: (entry['msSinceStart'] as num?)?.toInt() ?? 0,
      ));
    }
    return samples;
  }

  static List<Map<String, dynamic>> encodeNameTrace(
    List<({double dx, double dy, int msSinceStart})> samples,
  ) {
    return samples
        .map(
          (sample) => {
            'dx': sample.dx,
            'dy': sample.dy,
            'msSinceStart': sample.msSinceStart,
          },
        )
        .toList();
  }

  static Color? _parseColor(String? hex) {
    if (hex == null || hex.isEmpty) return null;
    final normalized = hex.replaceFirst('#', '');
    if (normalized.length != 6) return null;
    final value = int.tryParse(normalized, radix: 16);
    if (value == null) return null;
    return Color(0xFF000000 | value);
  }
}
