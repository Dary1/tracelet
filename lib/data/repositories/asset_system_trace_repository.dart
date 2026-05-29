import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tracelet/domain/models/app_mode.dart';
import 'package:tracelet/domain/models/system_trace.dart';
import 'package:tracelet/domain/repositories/system_trace_repository.dart';
import 'package:tracelet/domain/system_traces/system_trace_id.dart';
import 'package:tracelet/domain/system_traces/system_trace_paths.dart';
import 'package:tracelet/domain/system_traces/system_trace_stroke.dart';
import 'package:tracelet/domain/system_traces/system_trace_theme_id.dart';
import 'package:tracelet/domain/system_traces/system_trace_validator.dart';

class AssetSystemTraceRepository implements SystemTraceRepository {
  AssetSystemTraceRepository({
    AssetBundle? bundle,
    SystemTraceThemeId themeId = SystemTraceThemeId.active,
  })  : _bundle = bundle ?? rootBundle,
        _themeId = themeId;

  final AssetBundle _bundle;
  final SystemTraceThemeId _themeId;
  final Map<SystemTraceId, SystemTraceDocument> _documents = {};
  var _loaded = false;

  @override
  bool get isLoaded => _loaded;

  @override
  Future<void> loadAll() async {
    if (_loaded) return;

    for (final id in SystemTraceId.values) {
      final fileName = '${id.name}.json';
      final assetPath = SystemTracePaths.assetPath(_themeId, id);
      final raw = await _bundle.loadString(assetPath);
      final Object? json;
      try {
        json = jsonDecode(raw);
      } on FormatException catch (error) {
        throw SystemTraceValidationException(
          fileName,
          ['Invalid JSON syntax: ${error.message}'],
        );
      }

      SystemTraceValidator.validate(
        fileName: fileName,
        expectedId: id.name,
        json: json,
      );

      _documents[id] = SystemTraceDocument.fromJson(
        json as Map<String, dynamic>,
      );
    }

    _loaded = true;
  }

  @override
  SystemTraceDocument? documentFor(SystemTraceId id) => _documents[id];

  @override
  List<SystemTraceStroke> strokesFor(SystemTraceId id) {
    return documentFor(id)?.toStrokes() ?? const [];
  }

  @override
  Duration fadeDurationFor(SystemTraceId id) {
    return documentFor(id)?.fadeDuration ?? const Duration(milliseconds: 2200);
  }

  @override
  SystemTraceId modeTrace(AppMode mode) {
    switch (mode) {
      case AppMode.messageReceive:
        return SystemTraceId.modeMessageReceive;
      case AppMode.bottleMail:
        return SystemTraceId.modeBottleMail;
      case AppMode.specificUserSend:
      case AppMode.nameTraceRegistration:
        return SystemTraceId.modeSpecificUserSend;
    }
  }
}

final systemTraceRepositoryProvider = Provider<SystemTraceRepository>(
  (ref) => AssetSystemTraceRepository(themeId: SystemTraceThemeId.active),
);
