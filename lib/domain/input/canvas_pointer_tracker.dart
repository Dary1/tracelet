/// Tracks how many pointers are active on the canvas.
class CanvasPointerTracker {
  int _activePointers = 0;

  int get activePointers => _activePointers;

  bool get isMultiTouch => _activePointers > 1;

  void pointerDown() => _activePointers++;

  void pointerUp() {
    _activePointers = (_activePointers - 1).clamp(0, 999);
  }

  void reset() => _activePointers = 0;
}
