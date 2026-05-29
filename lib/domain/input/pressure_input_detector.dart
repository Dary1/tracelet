/// Whether pointer pressure comes from hardware or must be emulated.
enum PressureInputMode {
  unknown,
  hardware,
  software,
}

/// Calibrates once per app session from early pointer samples.
class PressureInputDetector {
  PressureInputMode mode = PressureInputMode.unknown;

  double _minSample = 1.0;
  double _maxSample = 0.0;
  int _sampleCount = 0;

  static const _maxCalibrationSamples = 12;
  static const _variationThreshold = 0.06;

  void observe(double hardwarePressure) {
    if (mode != PressureInputMode.unknown) return;

    _sampleCount++;
    _minSample = _minSample < hardwarePressure ? _minSample : hardwarePressure;
    _maxSample = _maxSample > hardwarePressure ? _maxSample : hardwarePressure;

    if (_sampleCount >= 3 &&
        (_maxSample - _minSample) >= _variationThreshold) {
      mode = PressureInputMode.hardware;
      return;
    }

    if (_sampleCount >= _maxCalibrationSamples) {
      mode = PressureInputMode.software;
    }
  }

  bool get usesHardware => mode == PressureInputMode.hardware;

  bool get usesSoftware =>
      mode == PressureInputMode.software ||
      mode == PressureInputMode.unknown;
}
