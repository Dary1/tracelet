import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tracelet/application/auth_providers.dart';
import 'package:tracelet/domain/auth/auth_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('auth notifier starts as guest after SharedPreferences is ready', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final state = await container.read(authNotifierProvider.future);

    expect(state.isGuest, isTrue);
    expect(state.guestUserId, isNotEmpty);
    await expectLater(
      container.read(authNotifierProvider.notifier).revertToGuest(),
      completes,
    );
  });
}
