import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'dart:ui';

void main() {
  runApp(const TraceletApp());
}

class TraceletApp extends StatelessWidget {
  const TraceletApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.black, // 純黒のキャンバス
      ),
      home: const TraceCanvasScreen(),
    );
  }
}

/// 軌跡の1点を管理するデータクラス
class TracePoint {
  final Offset position;
  final DateTime timestamp;

  TracePoint({required this.position, required this.timestamp});
}

/// 画面全体を覆うタッチ領域と描画ループを管理するクラス
class TraceCanvasScreen extends StatefulWidget {
  const TraceCanvasScreen({super.key});

  @override
  State<TraceCanvasScreen> createState() => _TraceCanvasScreenState();
}

class _TraceCanvasScreenState extends State<TraceCanvasScreen> with SingleTickerProviderStateMixin {
  List<TracePoint> _points = [];
  late Ticker _ticker;
  final Duration _fadeDuration = const Duration(milliseconds: 1500); // 軌跡が消えるまでの時間

  @override
  void initState() {
    super.initState();
    // UnityのUpdate()のように、毎フレーム再描画を要求する
    _ticker = createTicker((elapsed) {
      setState(() {
        // 古いポイント（フェード時間を過ぎたもの）をメモリから削除
        final now = DateTime.now();
        _points.removeWhere((p) => now.difference(p.timestamp) > _fadeDuration);
      });
    });
    _ticker.start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _addPoint(DragUpdateDetails details) {
    setState(() {
      _points.add(TracePoint(
        position: details.localPosition,
        timestamp: DateTime.now(),
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // SafeAreaを無視して画面の端から端まで黒くする
      body: GestureDetector(
        // タッチイベントの取得
        onPanStart: (details) => _points.add(TracePoint(position: details.localPosition, timestamp: DateTime.now())),
        onPanUpdate: _addPoint,
        onPanEnd: (details) => _points.add(TracePoint(position: Offset.infinite, timestamp: DateTime.now())), // 線の区切り
        child: CustomPaint(
          size: Size.infinite,
          painter: TracePainter(points: _points, fadeDuration: _fadeDuration),
        ),
      ),
    );
  }
}

/// 実際の描画ロジックを担当するクラス
class TracePainter extends CustomPainter {
  final List<TracePoint> points;
  final Duration fadeDuration;

  TracePainter({required this.points, required this.fadeDuration});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final now = DateTime.now();

    for (int i = 0; i < points.length - 1; i++) {
      final p1 = points[i];
      final p2 = points[i + 1];

      // 区切りポイント（指を離した場所）の場合は線を引かない
      if (p1.position == Offset.infinite || p2.position == Offset.infinite) continue;

      // 経過時間から透明度（0.0 〜 1.0）を計算
      final age = now.difference(p1.timestamp).inMilliseconds;
      final lifeRatio = 1.0 - (age / fadeDuration.inMilliseconds);
      
      if (lifeRatio <= 0) continue;

      // 線のスタイル定義（ぼんやり光る表現）
      final paint = Paint()
        ..color = Colors.white.withOpacity(lifeRatio.clamp(0.0, 1.0))
        ..strokeWidth = 4.0 // 線の太さ
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0); // 蛍の光のようなにじみ

      canvas.drawLine(p1.position, p2.position, paint);
    }
  }

  @override
  bool shouldRepaint(covariant TracePainter oldDelegate) => true; // 毎フレーム再描画
}