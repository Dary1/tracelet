import 'dart:async';

/// Wait after the last stroke point before depositing a bottle message.
const bottleSendIdleDuration = Duration(milliseconds: 1500);

/// Debounced bottle send: commit after idle, discard after multi-touch + idle.
class BottleSendCoordinator {
  BottleSendCoordinator({
    required this.onCommitSend,
    required this.onDiscard,
    this.idleDuration = bottleSendIdleDuration,
    Timer Function(Duration duration, void Function() callback)? createTimer,
  }) : _createTimer = createTimer ?? _defaultCreateTimer;

  final Duration idleDuration;
  final Future<void> Function() onCommitSend;
  final Future<void> Function() onDiscard;
  final Timer Function(Duration duration, void Function() callback) _createTimer;

  Timer? _idleTimer;
  bool _multiTouchDetected = false;
  bool _running = false;

  bool get isDrawingBlocked => _multiTouchDetected;

  void notifyPointAdded() {
    if (_multiTouchDetected) return;
    _scheduleCommit();
  }

  void notifyPointerReleased() {
    if (_multiTouchDetected) return;
    _scheduleCommit();
  }

  void notifyMultiTouch() {
    if (_multiTouchDetected) return;
    _multiTouchDetected = true;
    _idleTimer?.cancel();
    _idleTimer = _createTimer(idleDuration, _handleDiscardTimeout);
  }

  void reset() {
    _idleTimer?.cancel();
    _idleTimer = null;
    _multiTouchDetected = false;
    _running = false;
  }

  void dispose() => reset();

  void _scheduleCommit() {
    _idleTimer?.cancel();
    _idleTimer = _createTimer(idleDuration, _handleCommitTimeout);
  }

  Future<void> _handleCommitTimeout() async {
    if (_multiTouchDetected || _running) return;
    _running = true;
    try {
      await onCommitSend();
    } finally {
      reset();
    }
  }

  Future<void> _handleDiscardTimeout() async {
    if (!_multiTouchDetected || _running) return;
    _running = true;
    try {
      await onDiscard();
    } finally {
      reset();
    }
  }

  static Timer _defaultCreateTimer(Duration duration, void Function() callback) {
    return Timer(duration, callback);
  }
}
