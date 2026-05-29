import 'dart:async';

import 'dart:ui';



import 'package:tracelet/domain/bottle/bottle_send_pipeline.dart';

import 'package:tracelet/domain/input/canvas_pointer_tracker.dart';

import 'package:tracelet/domain/input/pressure_capture.dart';

import 'package:tracelet/domain/models/trace_point.dart';

import 'package:tracelet/domain/services/bottle_send_coordinator.dart';



/// Headless bottle-mode canvas input (mirrors [TraceCanvas] gesture rules).

class BottleDrawSession {

  BottleDrawSession({

    required BottleSendPipeline pipeline,

    PressureCapture? pressureCapture,

    void Function(TracePoint point)? onPointDrawn,

    void Function(List<TracePoint> sessionPoints)? onStrokeEnded,

    void Function()? onClearCanvas,

    Future<void> Function()? onDiscard,

    Duration idleDuration = bottleSendIdleDuration,

    Timer Function(Duration duration, void Function() callback)? createTimer,

    DateTime Function()? clock,

  })  : _pipeline = pipeline,

        _pressureCapture = pressureCapture,

        _onPointDrawn = onPointDrawn,

        _onStrokeEnded = onStrokeEnded,

        _onClearCanvas = onClearCanvas,

        _onDiscard = onDiscard,

        _clock = clock ?? DateTime.now {

    _coordinator = BottleSendCoordinator(

      idleDuration: idleDuration,

      createTimer: createTimer,

      onCommitSend: () async {

        final drawable =

            _points.where((point) => !point.isBreak).toList(growable: false);

        if (drawable.isEmpty) return;

        await _pipeline.commit(List.unmodifiable(_points));

        _points.clear();

      },

      onDiscard: () async {

        _points.clear();

        _onClearCanvas?.call();

        if (_onDiscard != null) {

          await _onDiscard!();

        } else {

          await _pipeline.discard();

        }

      },

    );

  }



  final BottleSendPipeline _pipeline;

  final PressureCapture? _pressureCapture;

  final void Function(TracePoint point)? _onPointDrawn;

  final void Function(List<TracePoint> sessionPoints)? _onStrokeEnded;

  final void Function()? _onClearCanvas;

  final Future<void> Function()? _onDiscard;

  final DateTime Function() _clock;

  late final BottleSendCoordinator _coordinator;

  final CanvasPointerTracker _pointers = CanvasPointerTracker();

  final List<TracePoint> _points = [];



  bool get isDrawingBlocked => _coordinator.isDrawingBlocked;



  int get activePointerCount => _pointers.activePointers;



  List<TracePoint> get points => List.unmodifiable(_points);



  void reset() {

    _coordinator.reset();

    _pointers.reset();

    _points.clear();

  }



  void dispose() => reset();



  void pointerDown() {

    _pointers.pointerDown();

    if (_pointers.isMultiTouch) {

      _coordinator.notifyMultiTouch();

    }

  }



  void pointerUp() => _pointers.pointerUp();



  void panStart(Offset position, {double hardwarePressure = 1.0}) {

    if (isDrawingBlocked) return;

    _recordPoint(position, hardwarePressure: hardwarePressure);

  }



  void panMove(Offset position, {double hardwarePressure = 1.0}) {

    if (isDrawingBlocked) return;

    _recordPoint(position, hardwarePressure: hardwarePressure);

  }



  void panEnd() {

    if (isDrawingBlocked) return;

    _points.add(

      TracePoint(

        position: TracePoint.strokeBreak,

        timestamp: _clock(),

        isStrokeBreak: true,

      ),

    );

    _onStrokeEnded?.call(List.unmodifiable(_points));

    _coordinator.notifyPointerReleased();

  }



  void _recordPoint(Offset position, {required double hardwarePressure}) {

    final timestamp = _clock();

    final previous = _lastDrawablePoint();

    final point = _pressureCapture?.buildPoint(

          position: position,

          timestamp: timestamp,

          hardwarePressure: hardwarePressure,

          previous: previous,

        ) ??

        TracePoint(position: position, timestamp: timestamp);

    _points.add(point);

    _onPointDrawn?.call(point);

    _coordinator.notifyPointAdded();

  }



  TracePoint? _lastDrawablePoint() {

    for (var i = _points.length - 1; i >= 0; i--) {

      if (!_points[i].isBreak) return _points[i];

    }

    return null;

  }

}


