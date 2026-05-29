import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tracelet/presentation/theme/tracelet_theme.dart';
import 'package:tracelet/presentation/widgets/app_bootstrap.dart';

class TraceletApp extends ConsumerWidget {
  const TraceletApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: buildTraceletTheme(),
      home: const AppBootstrap(),
    );
  }
}
