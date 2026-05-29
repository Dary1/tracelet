import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tracelet/application/auth_providers.dart';
import 'package:tracelet/presentation/screens/trace_canvas_screen.dart';
import 'package:tracelet/presentation/widgets/common/startup_screen.dart';

class AppBootstrap extends ConsumerWidget {
  const AppBootstrap({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authNotifierProvider);

    return auth.when(
      loading: () => const StartupScreen(),
      error: (error, _) => StartupScreen(message: error.toString()),
      data: (_) => const TraceCanvasScreen(),
    );
  }
}
