import 'dart:math' as math;
import 'dart:ui';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tracelet/data/fakes/in_memory_bottle_ocean.dart';
import 'package:tracelet/data/local/memory_message_inbox.dart';
import 'package:tracelet/domain/models/trace_message.dart';
import 'package:tracelet/domain/models/trace_profile.dart';
import 'package:tracelet/domain/models/trace_point.dart';
import 'package:tracelet/domain/models/trace_coordinate_space.dart';
import 'package:tracelet/domain/services/bottle_mail_service.dart';
import 'package:tracelet/domain/traces/trace_playback_mapper.dart';
import 'package:tracelet/domain/traces/trace_processor.dart';

import 'support/spatial_intent_geometry.dart';
import 'support/trace_playback_parity_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('TracePlaybackMapper spatial intent', () {
    const senderSize = Size(390, 844);
    final playback = TraceProfilePresets.pureFinger.toPlaybackProfile(senderSize);

    Offset norm(double x, double y) => Offset(x / senderSize.width, y / senderSize.height);

    test('centre point on small sender maps to centre on larger receiver', () {
      const receiverSize = Size(780, 1688);

      final mapped = TracePlaybackMapper.toCanvas(
        stored: norm(195, 422),
        playback: playback,
        canvasSize: receiverSize,
      );

      final relative = SpatialIntentGeometry.relativeCentre(
        [TracePoint(position: mapped, timestamp: DateTime(0))],
        receiverSize,
      );
      expect(relative.dx, closeTo(0.5, 0.02));
      expect(relative.dy, closeTo(0.5, 0.02));
    });

    test('centre point on sender maps to centre on smaller receiver', () {
      const receiverSize = Size(195, 422);

      final mapped = TracePlaybackMapper.toCanvas(
        stored: norm(195, 422),
        playback: playback,
        canvasSize: receiverSize,
      );

      final relative = SpatialIntentGeometry.relativeCentre(
        [TracePoint(position: mapped, timestamp: DateTime(0))],
        receiverSize,
      );
      expect(relative.dx, closeTo(0.5, 0.02));
      expect(relative.dy, closeTo(0.5, 0.02));
    });

    test('relative viewport position is preserved on larger receiver', () {
      const receiverSize = Size(780, 1688);
      final stored = norm(195 + 78, 422);

      final mapped = TracePlaybackMapper.toCanvas(
        stored: stored,
        playback: playback,
        canvasSize: receiverSize,
      );

      expect(mapped.dx / receiverSize.width, closeTo(0.7, 0.02));
      expect(mapped.dy / receiverSize.height, closeTo(0.5, 0.02));
    });

    test('circle stays round on larger receiver (uniform scale, no stretch)', () {
      const receiverSize = Size(780, 1688);
      const centre = Offset(195, 422);
      const radius = 48.0;

      final stored = SpatialIntentGeometry.circleTracePointsNormalized(
        centre: centre,
        canvas: senderSize,
        radius: radius,
      );
      final mapped = TracePlaybackMapper.mapPoints(
        points: stored,
        playback: playback,
        canvasSize: receiverSize,
      );

      final storedRatio = SpatialIntentGeometry.bboxAspectRatio(stored);
      final mappedRatio = SpatialIntentGeometry.bboxAspectRatio(mapped);

      // Normalized storage on a tall screen is elliptical in 0–1 space; playback
      // uniform scale restores a round stroke on the receiver canvas.
      expect(mappedRatio, closeTo(1.0, 0.08));
      expect(storedRatio, isNot(closeTo(1.0, 0.05)));

      final relativeCentre = SpatialIntentGeometry.relativeCentre(mapped, receiverSize);
      expect(relativeCentre.dx, closeTo(0.5, 0.02));
      expect(relativeCentre.dy, closeTo(0.5, 0.02));
    });

    test('square stays square on larger receiver (no horizontal/vertical pull)', () {
      const receiverSize = Size(780, 1688);
      final square = Rect.fromCenter(
        center: const Offset(195, 422),
        width: 80,
        height: 80,
      );

      final stored = SpatialIntentGeometry.squareTracePointsNormalized(
        bounds: square,
        canvas: senderSize,
      );
      final mapped = TracePlaybackMapper.mapPoints(
        points: stored,
        playback: playback,
        canvasSize: receiverSize,
      );

      final mappedBox = SpatialIntentGeometry.boundingBox(mapped);
      expect(mappedBox.width / mappedBox.height, closeTo(1.0, 0.05));

      final boxCentre = mappedBox.center;
      expect(boxCentre.dx / receiverSize.width, closeTo(0.5, 0.02));
      expect(boxCentre.dy / receiverSize.height, closeTo(0.5, 0.02));
    });

    test('all segment lengths scale uniformly on larger receiver', () {
      const receiverSize = Size(780, 1688);
      final stored = SpatialIntentGeometry.circleTracePointsNormalized(
        centre: const Offset(195, 422),
        canvas: senderSize,
        radius: 50,
      );
      final onSender = TracePlaybackMapper.mapPoints(
        points: stored,
        playback: playback,
        canvasSize: senderSize,
      );
      final onReceiver = TracePlaybackMapper.mapPoints(
        points: stored,
        playback: playback,
        canvasSize: receiverSize,
      );

      final senderPositions = SpatialIntentGeometry.drawablePoints(onSender)
          .map((p) => p.position)
          .toList();
      final receiverPositions = SpatialIntentGeometry.drawablePoints(onReceiver)
          .map((p) => p.position)
          .toList();

      final scaleFactors = SpatialIntentGeometry.pairwiseDistanceScaleFactors(
        sender: senderPositions,
        receiver: receiverPositions,
      );

      expect(scaleFactors, isNotEmpty);
      final expectedScale = scaleFactors.first;
      for (final factor in scaleFactors) {
        expect(
          factor,
          closeTo(expectedScale, expectedScale * 0.02 + 0.001),
          reason: 'non-uniform scale distorts shape: $scaleFactors',
        );
      }
      expect(expectedScale, closeTo(2.0, 0.05));
    });

    test('corner angles are preserved on larger receiver', () {
      const receiverSize = Size(780, 1688);

      final stored = [
        TracePoint(position: norm(195, 382), timestamp: DateTime(0)),
        TracePoint(position: norm(235, 422), timestamp: DateTime(1)),
        TracePoint(position: norm(195, 462), timestamp: DateTime(2)),
      ];
      final onSender = TracePlaybackMapper.mapPoints(
        points: stored,
        playback: playback,
        canvasSize: senderSize,
      );
      final mapped = TracePlaybackMapper.mapPoints(
        points: stored,
        playback: playback,
        canvasSize: receiverSize,
      );

      final senderDraw = SpatialIntentGeometry.drawablePoints(onSender);
      final mappedDraw = SpatialIntentGeometry.drawablePoints(mapped);
      final senderAngle = SpatialIntentGeometry.angleAt(
        senderDraw[0].position,
        senderDraw[1].position,
        senderDraw[2].position,
      );
      final mappedAngle = SpatialIntentGeometry.angleAt(
        mappedDraw[0].position,
        mappedDraw[1].position,
        mappedDraw[2].position,
      );

      expect(mappedAngle, closeTo(senderAngle, 0.02));
      expect(senderAngle, closeTo(math.pi / 2, 0.05));
    });

    test('same aspect ratio mismatch only scales uniformly (taller receiver)', () {
      const receiverSize = Size(780, 1200); // wider/taller mix, same sender aspect
      const top = Offset(195, 382);
      const corner = Offset(235, 422);
      const right = Offset(195, 462);

      final stored = SpatialIntentGeometry.circleTracePointsNormalized(
        centre: const Offset(195, 422),
        canvas: senderSize,
        radius: 40,
      );
      final onSender = TracePlaybackMapper.mapPoints(
        points: stored,
        playback: playback,
        canvasSize: senderSize,
      );
      final mapped = TracePlaybackMapper.mapPoints(
        points: stored,
        playback: playback,
        canvasSize: receiverSize,
      );

      final senderPositions = SpatialIntentGeometry.drawablePoints(onSender)
          .map((p) => p.position)
          .toList();
      final receiverPositions =
          SpatialIntentGeometry.drawablePoints(mapped).map((p) => p.position).toList();

      final scaleFactors = SpatialIntentGeometry.pairwiseDistanceScaleFactors(
        sender: senderPositions,
        receiver: receiverPositions,
      );

      expect(scaleFactors, isNotEmpty);
      final expectedScale = scaleFactors.first;
      for (final factor in scaleFactors) {
        expect(factor, closeTo(expectedScale, expectedScale * 0.02 + 0.001));
      }

      final relativeCentre = SpatialIntentGeometry.relativeCentre(mapped, receiverSize);
      expect(relativeCentre.dx, closeTo(0.5, 0.04));
      expect(relativeCentre.dy, closeTo(0.5, 0.04));
    });
  });

  group('Bottle mail spatial intent', () {
    test('circle sent from small device plays centred on large device', () {
      fakeAsync((async) {
        const senderCanvas = Size(390, 844);
        const receiverCanvas = Size(780, 1688);
        const centre = Offset(195, 422);
        const radius = 50.0;

        final ocean = InMemoryBottleOcean();
        final senderMail = BottleMailService(
          ocean: ocean,
          inbox: MemoryMessageInbox(),
          userId: 'device-a',
        );

        final sender = TracePlaybackParityHarness.create(
          elapse: async.elapse,
          flushMicrotasks: async.flushMicrotasks,
          profile: TraceProfilePresets.pureFinger,
          canvasSize: senderCanvas,
          depositMail: senderMail,
        );

        sender.drawCircle(centre: centre, radius: radius);
        sender.waitForSendIdle();

        TraceMessage? message;
        TracePlaybackParityHarness.receiveFromOcean(ocean: ocean).then((received) {
          message = received;
        });
        async.flushMicrotasks();
        expect(message, isNotNull);

        expect(message!.playbackProfile.captureWidth, senderCanvas.width);
        expect(message!.playbackProfile.captureHeight, senderCanvas.height);
        expect(message!.playbackProfile.isNormalized, isTrue);

        final mapped = TracePlaybackMapper.mapPoints(
          points: message!.points,
          playback: message!.playbackProfile,
          canvasSize: receiverCanvas,
        );

        final relativeCentre =
            SpatialIntentGeometry.relativeCentre(mapped, receiverCanvas);
        expect(relativeCentre.dx, closeTo(0.5, 0.06));
        expect(relativeCentre.dy, closeTo(0.5, 0.06));

        final mappedRatio = SpatialIntentGeometry.bboxAspectRatio(mapped);
        expect(mappedRatio, closeTo(1.0, 0.12));

        sender.dispose();
      });
    });

    test('processed bottle payload preserves uniform scale intent', () {
      const senderCanvas = Size(390, 844);
      const receiverCanvas = Size(780, 1688);
      const centre = Offset(195, 422);

      final raw = SpatialIntentGeometry.circleTracePoints(
        centre: centre,
        radius: 55,
        count: 40,
      );
      final processed = TraceProcessor.process(
        raw: raw,
        profile: TraceProfilePresets.littlePrettify,
        captureSize: senderCanvas,
      );
      final playback =
          TraceProfilePresets.littlePrettify.toPlaybackProfile(senderCanvas);

      final onSender = TracePlaybackMapper.mapPoints(
        points: processed,
        playback: playback,
        canvasSize: senderCanvas,
      );
      final mapped = TracePlaybackMapper.mapPoints(
        points: processed,
        playback: playback,
        canvasSize: receiverCanvas,
      );

      final senderPositions = SpatialIntentGeometry.drawablePoints(onSender)
          .map((point) => point.position)
          .toList();
      final receiverPositions = SpatialIntentGeometry.drawablePoints(mapped)
          .map((point) => point.position)
          .toList();

      final scaleFactors = SpatialIntentGeometry.pairwiseDistanceScaleFactors(
        sender: senderPositions,
        receiver: receiverPositions,
      );

      expect(scaleFactors, isNotEmpty);
      final expectedScale = scaleFactors.first;
      for (final factor in scaleFactors) {
        expect(
          factor,
          closeTo(expectedScale, expectedScale * 0.04 + 0.001),
          reason: 'processed trace must not be anisotropically stretched',
        );
      }
      expect(
        expectedScale,
        closeTo(2.0, 0.06),
        reason: 'larger receiver should scale geometry up uniformly',
      );
    });
  });
}
