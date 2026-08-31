import 'package:flutter_test/flutter_test.dart';
import 'package:nb_utils/nb_utils.dart';

import 'package:open_core_hr/utils/app_constants.dart';
import 'package:open_core_hr/utils/token_storage.dart';

/// In-memory fake of the platform secure-storage backend (the real plugin's
/// method channel is not available inside `flutter test`).
class _FakeBackend implements SecureTokenBackend {
  final Map<String, String> store = {};
  bool failWrites = false;

  @override
  Future<String?> read(String key) async => store[key];

  @override
  Future<void> write(String key, String value) async {
    if (failWrites) throw Exception('secure write failed');
    store[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    store.remove(key);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _FakeBackend backend;

  setUp(() async {
    // nb_utils' `initialize()` sets up the SharedPreferences global that
    // `setValue`/`getStringAsync` depend on (without it they throw a
    // LateInitializationError, exactly like the kiosk's startup white-screen).
    SharedPreferences.setMockInitialValues({});
    await initialize();
    TokenStorage.resetCacheForTesting();
    backend = _FakeBackend();
    TokenStorage.backend = backend;
  });

  test('write stores securely, updates memory and clears the plaintext copy',
      () async {
    await setValue(tokenPref, 'legacy');
    await TokenStorage.write('new-token');

    expect(backend.store[tokenPref], 'new-token');
    expect(TokenStorage.cached, 'new-token');
    // The plaintext SharedPreferences copy must be removed once secured.
    expect(getStringAsync(tokenPref), '');
  });

  test('restore migrates from secure storage and clears the prefs copy',
      () async {
    backend.store[tokenPref] = 'secured';
    await setValue(tokenPref, 'legacy');
    await TokenStorage.restore();

    expect(TokenStorage.cached, 'secured');
    expect(getStringAsync(tokenPref), '');
  });

  test('restore falls back to the legacy prefs token when secure storage empty',
      () async {
    await setValue(tokenPref, 'legacy-only');
    await TokenStorage.restore();

    expect(TokenStorage.cached, 'legacy-only');
  });

  test('cached falls back to prefs when the memory cache is empty', () async {
    await setValue(tokenPref, 'prefs-token');
    expect(TokenStorage.cached, 'prefs-token');
  });

  test('clear removes the token from secure storage, memory and prefs',
      () async {
    await TokenStorage.write('tok');
    await setValue(tokenPref, 'prefs-copy');
    await TokenStorage.clear();

    expect(backend.store.containsKey(tokenPref), isFalse);
    // The sync getter returns '' (never null) when no token is present.
    expect(TokenStorage.cached, isEmpty);
    expect(getStringAsync(tokenPref), '');
  });

  test('write falls back to prefs when secure storage fails (login never breaks)',
      () async {
    backend.failWrites = true;
    await TokenStorage.write('tok');

    expect(getStringAsync(tokenPref), 'tok');
    expect(TokenStorage.cached, 'tok');
  });
}
