import 'dart:ui';

import 'package:tracelet/domain/models/trace_message.dart';
import 'package:tracelet/domain/models/trace_point.dart';
import 'package:tracelet/domain/models/trace_profile.dart';
import 'package:tracelet/domain/repositories/message_repository.dart';

/// Records [depositBottle] calls for production-flow tests.
class RecordingMessageRepository implements MessageRepository {
  RecordingMessageRepository({this.throwOnDeposit});

  final Object? throwOnDeposit;
  int depositCallCount = 0;
  List<TracePoint>? lastDepositedPoints;
  TraceProfile? lastProfile;
  Size? lastCaptureSize;

  @override
  Future<void> depositBottle(
    List<TracePoint> points, {
    required TraceProfile profile,
    required Size captureSize,
  }) async {
    depositCallCount++;
    lastDepositedPoints = List.of(points);
    lastProfile = profile;
    lastCaptureSize = captureSize;
    if (throwOnDeposit != null) {
      throw throwOnDeposit!;
    }
  }

  @override
  Future<List<TraceMessage>> getReceivedMessages() async => const [];

  @override
  Future<TraceMessage?> getNextUnplayedMessage() async => null;

  @override
  Future<TraceMessage?> getRandomMessage() async => null;

  @override
  Future<TraceMessage?> getLastReceivedMessage() async => null;

  @override
  Future<TraceMessage> receiveRandomMessage() async {
    throw UnimplementedError();
  }

  @override
  Future<void> markAsPlayed(String messageId) async {}
}
