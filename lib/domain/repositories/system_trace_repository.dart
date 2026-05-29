import 'package:tracelet/domain/models/app_mode.dart';
import 'package:tracelet/domain/models/system_trace.dart';
import 'package:tracelet/domain/system_traces/system_trace_id.dart';
import 'package:tracelet/domain/system_traces/system_trace_stroke.dart';

abstract interface class SystemTraceRepository {
  Future<void> loadAll();

  bool get isLoaded;

  SystemTraceDocument? documentFor(SystemTraceId id);

  List<SystemTraceStroke> strokesFor(SystemTraceId id);

  Duration fadeDurationFor(SystemTraceId id);

  SystemTraceId modeTrace(AppMode mode);
}
