import 'package:tracelet/domain/system_traces/system_trace_id.dart';

/// How bottle send outcomes are surfaced (device traces vs test exceptions).
enum BottleSendSurface {
  /// Play system traces; swallow errors after feedback.
  device,

  /// Rethrow errors for unit tests — no trace playback.
  virtual,
}

/// Callbacks for bottle send lifecycle (sent / discarded / error).
abstract interface class BottleSendFeedback {
  Future<void> onSent();

  Future<void> onDiscarded();

  Future<void> onError(Object error);
}

class DeviceBottleSendFeedback implements BottleSendFeedback {
  DeviceBottleSendFeedback({
    required Future<void> Function(SystemTraceId id, {bool clearFirst})
        playTrace,
  }) : _playTrace = playTrace;

  final Future<void> Function(SystemTraceId id, {bool clearFirst}) _playTrace;

  @override
  Future<void> onSent() => _playTrace(SystemTraceId.bottleSent, clearFirst: false);

  @override
  Future<void> onDiscarded() =>
      _playTrace(SystemTraceId.bottleDiscarded, clearFirst: false);

  @override
  Future<void> onError(Object error) =>
      _playTrace(SystemTraceId.bottleError, clearFirst: false);
}

class VirtualBottleSendFeedback implements BottleSendFeedback {
  Object? lastError;
  int sentCount = 0;
  int discardCount = 0;

  @override
  Future<void> onSent() async {
    sentCount++;
  }

  @override
  Future<void> onDiscarded() async {
    discardCount++;
  }

  @override
  Future<void> onError(Object error) {
    lastError = error;
    Error.throwWithStackTrace(error, StackTrace.current);
  }
}
