import 'package:flutter_test/flutter_test.dart';
import 'package:tracelet/domain/input/pressure_input_detector.dart';

void main() {
  group('PressureInputDetector', () {
    test('locks to hardware when pressure varies', () {
      final detector = PressureInputDetector();
      detector.observe(0.2);
      detector.observe(0.5);
      detector.observe(0.8);

      expect(detector.mode, PressureInputMode.hardware);
      expect(detector.usesHardware, isTrue);
    });

    test('locks to software when pressure stays flat', () {
      final detector = PressureInputDetector();
      for (var i = 0; i < 12; i++) {
        detector.observe(1.0);
      }

      expect(detector.mode, PressureInputMode.software);
      expect(detector.usesSoftware, isTrue);
    });
  });
}
