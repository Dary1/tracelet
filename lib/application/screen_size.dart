import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';

final screenSizeProvider = StateProvider<Size>(
  (ref) => const Size(390, 844),
);
