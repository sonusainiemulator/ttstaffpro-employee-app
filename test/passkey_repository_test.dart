import 'package:flutter_test/flutter_test.dart';
import 'package:open_core_hr/api/dio_api/repositories/passkey_repository.dart';

void main() {
  group('PasskeyLoginOptions.fromJson', () {
    test('parses the backend snake_case payload', () {
      final options = PasskeyLoginOptions.fromJson({
        'challenge': 'abc123',
        'rp_id': 'ttstaffpro.in',
        'timeout': 180000,
        'user_verification': 'preferred',
        'allow_credentials': [
          {'id': 'cred-1', 'type': 'public-key'},
        ],
      });

      expect(options.challenge, 'abc123');
      expect(options.rpId, 'ttstaffpro.in');
      expect(options.timeout, 180000);
      expect(options.userVerification, 'preferred');
      expect(options.allowCredentials, [
        {'id': 'cred-1', 'type': 'public-key'},
      ]);
    });

    test('parses camelCase keys and an empty allowCredentials list', () {
      final options = PasskeyLoginOptions.fromJson({
        'challenge': 'xyz',
        'rpId': 'ttstaffpro.in',
        'timeout': 60000,
        'userVerification': 'required',
        'allowCredentials': [],
      });

      expect(options.challenge, 'xyz');
      expect(options.rpId, 'ttstaffpro.in');
      expect(options.allowCredentials, isEmpty);
    });
  });

  group('PasskeyRegisterOptions.fromJson', () {
    test('parses rp/user nested objects (camelCase)', () {
      final options = PasskeyRegisterOptions.fromJson({
        'challenge': 'chal',
        'rp': {'id': 'ttstaffpro.in', 'name': 'TT Staff Pro'},
        'user': {
          'id': 'dXNlci1pZA',
          'name': 'user@ttstaffpro.in',
          'displayName': 'User Name',
        },
        'pubKeyCredParams': [
          {'type': 'public-key', 'alg': -7},
        ],
        'timeout': 180000,
      });

      expect(options.challenge, 'chal');
      expect(options.rpId, 'ttstaffpro.in');
      expect(options.rpName, 'TT Staff Pro');
      expect(options.userId, 'dXNlci1pZA');
      expect(options.userName, 'user@ttstaffpro.in');
      expect(options.userDisplayName, 'User Name');
      expect(options.pubKeyCredParams, [
        {'type': 'public-key', 'alg': -7},
      ]);
      expect(options.timeout, 180000);
    });

    test('falls back to name when displayName is missing', () {
      final options = PasskeyRegisterOptions.fromJson({
        'challenge': 'chal',
        'rp': {'id': 'ttstaffpro.in', 'name': 'TT Staff Pro'},
        'user': {'id': 'id1', 'name': 'user@ttstaffpro.in'},
      });

      expect(options.userDisplayName, 'user@ttstaffpro.in');
      expect(options.pubKeyCredParams, isEmpty);
    });
  });
}
