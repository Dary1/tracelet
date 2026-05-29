import 'dart:ui';

import 'package:tracelet/data/fakes/in_memory_bottle_ocean.dart';
import 'package:tracelet/data/local/memory_message_inbox.dart';
import 'package:tracelet/domain/models/trace_message.dart';
import 'package:tracelet/domain/models/trace_point.dart';
import 'package:tracelet/domain/models/trace_profile.dart';
import 'package:tracelet/domain/models/user.dart';
import 'package:tracelet/domain/repositories/message_repository.dart';
import 'package:tracelet/domain/services/bottle_mail_service.dart';

/// In-memory mock backed by the same bottle-mail domain service as production.
class MockMessageRepository implements MessageRepository {
  MockMessageRepository({
    InMemoryBottleOcean? ocean,
    String userId = 'mock-user',
  })  : _bottleMail = BottleMailService(
          ocean: ocean ?? InMemoryBottleOcean(),
          inbox: MemoryMessageInbox(),
          userId: userId,
        ) {
    _messages.addAll(_seedMessages);
  }

  final BottleMailService _bottleMail;
  final List<TraceMessage> _messages = [];

  static final _seedMessages = [
    TraceMessage(
      id: 'msg-1',
      sender: const TraceUser(id: 'u-alice', displayName: 'Alice'),
      receivedAt: DateTime(2026, 1, 1),
      points: const [],
    ),
    TraceMessage(
      id: 'msg-2',
      sender: const TraceUser(id: 'u-bob', displayName: 'Bob'),
      receivedAt: DateTime(2026, 1, 2),
      points: const [],
    ),
    TraceMessage(
      id: 'msg-3',
      sender: const TraceUser(
        id: 'ai-luna',
        displayName: 'Luna',
        isAiPersona: true,
      ),
      receivedAt: DateTime(2026, 1, 3),
      points: const [],
    ),
  ];

  @override
  Future<List<TraceMessage>> getReceivedMessages() async =>
      List.unmodifiable(_messages);

  @override
  Future<TraceMessage?> getNextUnplayedMessage() async {
    for (final message in _messages) {
      if (!message.played) return message;
    }
    return null;
  }

  @override
  Future<TraceMessage?> getRandomMessage() async {
    if (_messages.isEmpty) return null;
    return _messages[DateTime.now().millisecond % _messages.length];
  }

  @override
  Future<TraceMessage?> getLastReceivedMessage() async {
    if (_messages.isEmpty) return null;
    return _messages.reduce(
      (a, b) => a.receivedAt.isAfter(b.receivedAt) ? a : b,
    );
  }

  @override
  Future<void> depositBottle(
    List<TracePoint> points, {
    required TraceProfile profile,
    required Size captureSize,
  }) =>
      _bottleMail.sendTrace(
        points,
        profile: profile,
        captureSize: captureSize,
      );

  @override
  Future<TraceMessage> receiveRandomMessage() async {
    final message = await _bottleMail.receive();
    _messages.add(message);
    return message;
  }

  @override
  Future<void> markAsPlayed(String messageId) async {
    final index = _messages.indexWhere((message) => message.id == messageId);
    if (index >= 0) {
      _messages[index] = _messages[index].copyWith(played: true);
    }
  }
}
