import 'dart:convert';
import 'dart:ui';

import 'package:tracelet/data/api/trace_payload_codec.dart';
import 'package:tracelet/domain/gateways/bottle_ocean_gateway.dart';
import 'package:tracelet/domain/models/trace_message.dart';
import 'package:tracelet/domain/models/trace_point.dart';
import 'package:tracelet/domain/models/trace_profile.dart';
import 'package:tracelet/domain/repositories/message_inbox.dart';
import 'package:tracelet/domain/traces/trace_processor.dart';

class BottleMailException implements Exception {
  BottleMailException(this.message);

  final String message;

  @override
  String toString() => 'BottleMailException: $message';
}

/// Thrown when the ocean is empty or only contains the receiver's own bottles.
class NoBottleAvailableException implements Exception {
  @override
  String toString() => 'NoBottleAvailableException: No bottles available';
}

/// Domain service for depositing and receiving bottle traces (no UI).
class BottleMailService {
  BottleMailService({
    required BottleOceanGateway ocean,
    required MessageInbox inbox,
    required String userId,
  })  : _ocean = ocean,
        _inbox = inbox,
        _userId = userId;

  static const _maxPullAttempts = 32;

  final BottleOceanGateway _ocean;
  final MessageInbox _inbox;
  final String _userId;

  String get userId => _userId;

  Future<void> sendTrace(
    List<TracePoint> points, {
    required TraceProfile profile,
    required Size captureSize,
  }) async {
    final drawable = points.where((point) => !point.isBreak).toList();
    if (drawable.isEmpty) {
      throw BottleMailException('Cannot send an empty trace');
    }

    final processed = TraceProcessor.process(
      raw: points,
      profile: profile,
      captureSize: captureSize,
    );
    final snapshot = profile.toPlaybackProfile(captureSize);

    await _ocean.deposit(
      senderUserId: _userId,
      payload: TracePayloadCodec.encodePayload(
        points: processed,
        playback: snapshot,
      ),
    );
  }

  Future<TraceMessage> receive() async {
    final repostedFingerprints = <String>{};

    for (var attempt = 0; attempt < _maxPullAttempts; attempt++) {
      final body = await _ocean.pull();
      if (body == null) {
        throw NoBottleAvailableException();
      }

      final fingerprint = _fingerprint(body);
      final senderId = body['senderUserId']?.toString() ?? '';

      if (repostedFingerprints.contains(fingerprint)) {
        // Pulled our own reposted bottle again — leave it in the ocean for others.
        await _repost(body);
        throw NoBottleAvailableException();
      }

      if (senderId == _userId) {
        repostedFingerprints.add(fingerprint);
        await _repost(body);
        continue;
      }

      final message = TracePayloadCodec.messageFromBottle(
        body: body,
        receivedAt: DateTime.now(),
      );
      final messages = List<TraceMessage>.from(await _inbox.readAll())
        ..add(message);
      await _inbox.writeAll(messages);
      return message;
    }

    throw NoBottleAvailableException();
  }

  Future<void> _repost(Map<String, dynamic> body) async {
    final payload = body['payload'];
    await _ocean.deposit(
      senderUserId: body['senderUserId']?.toString() ?? _userId,
      payload: payload is Map<String, dynamic> ? payload : const {},
    );
  }

  static String _fingerprint(Map<String, dynamic> body) {
    return '${body['senderUserId']}|${jsonEncode(body['payload'])}';
  }
}
