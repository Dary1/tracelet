import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:tracelet/domain/auth/auth_required_exception.dart';
import 'package:tracelet/domain/bottle/bottle_send_feedback.dart';
import 'package:tracelet/domain/bottle/bottle_send_pipeline.dart';
import 'package:tracelet/domain/models/trace_point.dart';
import 'package:tracelet/domain/models/trace_profile.dart';

class RecordingFeedback implements BottleSendFeedback {
  Object? lastError;
  bool sent = false;

  @override
  Future<void> onDiscarded() async {}

  @override
  Future<void> onError(Object error) async {
    lastError = error;
  }

  @override
  Future<void> onSent() async {
    sent = true;
  }
}

void main() {
  test('auth failure signs out instead of playing bottle error trace', () async {
    final feedback = RecordingFeedback();
    var signedOut = false;

    final pipeline = BottleSendPipeline(
      deposit: (_, {required profile, required captureSize}) =>
          throw AuthRequiredException(),
      resolveProfile: () => TraceProfilePresets.pureFinger,
      captureSize: () => const Size(400, 800),
      feedback: feedback,
      clearCanvas: () {},
      onAuthRequired: () async {
        signedOut = true;
      },
    );

    await pipeline.commit([
      TracePoint(
        position: const Offset(0.1, 0.1),
        timestamp: DateTime.fromMillisecondsSinceEpoch(0),
      ),
      TracePoint(
        position: const Offset(0.2, 0.2),
        timestamp: DateTime.fromMillisecondsSinceEpoch(100),
      ),
    ]);

    expect(signedOut, isTrue);
    expect(feedback.sent, isFalse);
    expect(feedback.lastError, isNull);
  });
}
