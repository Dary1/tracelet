import 'dart:ui';

import 'package:tracelet/domain/models/trace_message.dart';
import 'package:tracelet/domain/models/trace_point.dart';
import 'package:tracelet/domain/models/trace_profile.dart';

/// Contract for message persistence and retrieval.
abstract interface class MessageRepository {
  Future<List<TraceMessage>> getReceivedMessages();

  Future<TraceMessage?> getNextUnplayedMessage();

  Future<TraceMessage?> getRandomMessage();

  Future<TraceMessage?> getLastReceivedMessage();

  Future<void> depositBottle(
    List<TracePoint> points, {
    required TraceProfile profile,
    required Size captureSize,
  });

  Future<TraceMessage> receiveRandomMessage();

  Future<void> markAsPlayed(String messageId);
}
