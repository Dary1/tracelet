import 'dart:ui';

import 'package:tracelet/data/gateways/aws_bottle_ocean_gateway.dart';
import 'package:tracelet/data/local/local_app_store.dart';
import 'package:tracelet/domain/models/trace_message.dart';
import 'package:tracelet/domain/models/trace_point.dart';
import 'package:tracelet/domain/models/trace_profile.dart';
import 'package:tracelet/domain/repositories/message_repository.dart';
import 'package:tracelet/domain/services/bottle_mail_service.dart';

class AwsMessageRepository implements MessageRepository {
  AwsMessageRepository({
    required String userId,
    required LocalAppStore inbox,
    required AwsBottleOceanGateway ocean,
  })  : _inbox = inbox,
        _bottleMail = BottleMailService(
          ocean: ocean,
          inbox: inbox,
          userId: userId,
        );

  final LocalAppStore _inbox;
  final BottleMailService _bottleMail;

  List<TraceMessage>? _cache;

  Future<List<TraceMessage>> _messages() async {
    _cache ??= await _inbox.readAll();
    return _cache!;
  }

  Future<void> _persist(List<TraceMessage> messages) async {
    _cache = List.of(messages);
    await _inbox.writeAll(messages);
  }

  @override
  Future<List<TraceMessage>> getReceivedMessages() async =>
      List.unmodifiable(await _messages());

  @override
  Future<TraceMessage?> getNextUnplayedMessage() async {
    for (final message in await _messages()) {
      if (!message.played) return message;
    }
    return null;
  }

  @override
  Future<TraceMessage?> getRandomMessage() async {
    final messages = await _messages();
    if (messages.isEmpty) return null;
    return messages[DateTime.now().millisecond % messages.length];
  }

  @override
  Future<TraceMessage?> getLastReceivedMessage() async {
    final messages = await _messages();
    if (messages.isEmpty) return null;
    return messages.reduce(
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
    _cache = await _inbox.readAll();
    return message;
  }

  @override
  Future<void> markAsPlayed(String messageId) async {
    final messages = await _messages();
    final index = messages.indexWhere((message) => message.id == messageId);
    if (index < 0) return;
    messages[index] = messages[index].copyWith(played: true);
    await _persist(messages);
  }
}
