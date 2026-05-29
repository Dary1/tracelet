import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:tracelet/data/api/trace_payload_codec.dart';
import 'package:tracelet/data/local/local_app_store.dart';
import 'package:tracelet/domain/models/trace_playback_profile.dart';
import 'package:tracelet/domain/models/trace_point.dart';
import 'package:tracelet/domain/models/trace_pressure_profile.dart';
import 'package:tracelet/domain/models/trace_profile.dart';
import 'package:tracelet/domain/models/trace_profile_preset.dart';

void main() {
  test('encodePayload embeds slim playback header without duplicates', () {
    const captureSize = Size(390, 844);
    final playback = TraceProfilePresets.prettified
        .toPlaybackProfile(captureSize)
        .copyWith(
          pressure: const TracePressureProfile(minWidthPx: 3, maxWidthPx: 9),
        );
    final payload = TracePayloadCodec.encodePayload(
      points: [
        TracePoint(
          position: const Offset(0.5, 0.5),
          timestamp: DateTime.fromMillisecondsSinceEpoch(100),
        ),
      ],
      playback: playback,
    );

    expect(payload['profileVersion'], TracePlaybackProfile.currentVersion);
    expect(payload['playback'], isA<Map<String, dynamic>>());
    expect(payload.containsKey('profile'), isFalse);
    expect(payload.containsKey('captureSize'), isFalse);
    expect(payload.containsKey('preset'), isFalse);
    expect(payload.containsKey('coordinateSpace'), isFalse);

    final decoded = TracePayloadCodec.decodePayload(payload);
    expect(decoded.playbackProfile.preset, TraceProfilePreset.prettified);
    expect(decoded.playbackProfile.captureWidth, 390);
    expect(decoded.playbackProfile.pressure.maxWidthPx, 9);
    expect(decoded.playbackProfile.isNormalized, isTrue);
    expect(decoded.isLegacy, isFalse);
  });

  test('inbox decode uses playback header from payload only', () {
    const headerProfile = TracePressureProfile(minWidthPx: 1, maxWidthPx: 11);
    const captureSize = Size(390, 844);

    final message = LocalAppStore.decodeStoredMessage({
      'id': 'm1',
      'senderId': 'alice',
      'senderDisplayName': 'Alice',
      'receivedAt': '2026-01-01T00:00:00.000Z',
      'played': false,
      'isLegacyPayload': false,
      'payload': TracePayloadCodec.encodePayload(
        points: [
          TracePoint(
            position: const Offset(0.25, 0.5),
            timestamp: DateTime.fromMillisecondsSinceEpoch(0),
          ),
        ],
        playback: TraceProfilePresets.prettified
            .toPlaybackProfile(captureSize)
            .copyWith(pressure: headerProfile),
      ),
    });

    expect(message, isNotNull);
    expect(message!.playbackProfile.preset, TraceProfilePreset.prettified);
    expect(message.playbackProfile.pressure.maxWidthPx, 11);
  });
}
