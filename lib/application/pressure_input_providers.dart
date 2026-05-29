import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tracelet/domain/input/pressure_input_detector.dart';

class PressureInputDetectorNotifier extends Notifier<PressureInputDetector> {
  @override
  PressureInputDetector build() => PressureInputDetector();

  void observe(double hardwarePressure) {
    state.observe(hardwarePressure);
  }
}

final pressureInputDetectorProvider =
    NotifierProvider<PressureInputDetectorNotifier, PressureInputDetector>(
  PressureInputDetectorNotifier.new,
);
