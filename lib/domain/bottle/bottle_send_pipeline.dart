import 'dart:ui';

import 'package:tracelet/domain/auth/auth_required_exception.dart';
import 'package:tracelet/domain/bottle/bottle_send_feedback.dart';
import 'package:tracelet/domain/models/trace_point.dart';
import 'package:tracelet/domain/models/trace_profile.dart';
import 'package:tracelet/domain/services/bottle_mail_service.dart';

typedef BottleDepositFn = Future<void> Function(
  List<TracePoint> points, {
  required TraceProfile profile,
  required Size captureSize,
});

/// Deposit + feedback for a bottle trace commit.
class BottleSendPipeline {
  BottleSendPipeline({
    required this.deposit,
    required this.feedback,
    required this.clearCanvas,
    required this.resolveProfile,
    required this.captureSize,
    this.surface = BottleSendSurface.device,
    this.onAuthRequired,
  });

  final BottleDepositFn deposit;
  final BottleSendFeedback feedback;
  final void Function() clearCanvas;
  final TraceProfile Function() resolveProfile;
  final Size Function() captureSize;
  final BottleSendSurface surface;
  final Future<void> Function()? onAuthRequired;

  Future<void> commit(List<TracePoint> points) async {
    final drawable = points.where((point) => !point.isBreak).toList();
    if (drawable.isEmpty) {
      final error = BottleMailException('Cannot send an empty trace');
      await feedback.onError(error);
      return;
    }

    try {
      await deposit(
        points,
        profile: resolveProfile(),
        captureSize: captureSize(),
      );
      clearCanvas();
      await feedback.onSent();
    } on AuthRequiredException {
      if (onAuthRequired != null) {
        await onAuthRequired!();
      } else {
        await feedback.onError(AuthRequiredException());
      }
    } catch (error) {
      await feedback.onError(error);
    }
  }

  Future<void> discard() => feedback.onDiscarded();
}
