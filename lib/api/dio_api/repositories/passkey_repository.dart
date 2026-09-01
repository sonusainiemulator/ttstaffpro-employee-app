import '../../../models/user_model.dart';
import '../base_repository.dart';

/// Parsed login options returned by `POST passkey/login/options`.
class PasskeyLoginOptions {
  final String challenge;
  final String rpId;
  final int timeout;
  final String userVerification;
  final List<Map<String, dynamic>> allowCredentials;

  PasskeyLoginOptions({
    required this.challenge,
    required this.rpId,
    required this.timeout,
    required this.userVerification,
    required this.allowCredentials,
  });

  /// The backend wraps the payload in `data` and snake_cases keys
  /// (`rp_id`, `user_verification`, `allow_credentials`); tolerate camelCase too.
  factory PasskeyLoginOptions.fromJson(Map<String, dynamic> json) {
    String s(dynamic v) => v == null ? '' : v.toString();
    int i(dynamic v) => int.tryParse(s(v)) ?? 0;

    final allow = json['allowCredentials'] ?? json['allow_credentials'] ?? const [];
    return PasskeyLoginOptions(
      challenge: s(json['challenge']),
      rpId: s(json['rpId'] ?? json['rp_id'] ?? (json['rp'] is Map ? json['rp']['id'] : null)),
      timeout: i(json['timeout']),
      userVerification: s(json['userVerification'] ?? json['user_verification']),
      allowCredentials: allow is List
          ? allow.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
          : const [],
    );
  }
}

/// Parsed registration options returned by `POST passkey/register/options`.
class PasskeyRegisterOptions {
  final String challenge;
  final String rpId;
  final String rpName;
  final String userId;
  final String userName;
  final String userDisplayName;
  final List<Map<String, dynamic>> pubKeyCredParams;
  final int timeout;

  PasskeyRegisterOptions({
    required this.challenge,
    required this.rpId,
    required this.rpName,
    required this.userId,
    required this.userName,
    required this.userDisplayName,
    required this.pubKeyCredParams,
    required this.timeout,
  });

  factory PasskeyRegisterOptions.fromJson(Map<String, dynamic> json) {
    String s(dynamic v) => v == null ? '' : v.toString();
    int i(dynamic v) => int.tryParse(s(v)) ?? 0;

    final rp = json['rp'] is Map ? Map<String, dynamic>.from(json['rp'] as Map) : <String, dynamic>{};
    final user = json['user'] is Map ? Map<String, dynamic>.from(json['user'] as Map) : <String, dynamic>{};
    final params = json['pubKeyCredParams'] ?? json['pub_key_cred_params'] ?? const [];

    return PasskeyRegisterOptions(
      challenge: s(json['challenge']),
      rpId: s(rp['id'] ?? rp['name']),
      rpName: s(rp['name']),
      userId: s(user['id']),
      userName: s(user['name']),
      userDisplayName: s(user['displayName'] ?? user['display_name'] ?? user['name']),
      pubKeyCredParams: params is List
          ? params.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
          : const [],
      timeout: i(json['timeout']),
    );
  }
}

/// Client for the mobile passkey (WebAuthn / biometric) endpoints.
///
/// Endpoints:
///   POST passkey/login/options    (public)
///   POST passkey/login/verify     (public)  → issues a JWT
///   POST passkey/register/options (auth)
///   POST passkey/register/verify  (auth)
class PasskeyRepository extends BaseRepository {
  /// Step 1 of passkey login: fetch the WebAuthn challenge.
  Future<PasskeyLoginOptions> getLoginOptions() {
    return safeApiCall(
      () => dioClient.post('passkey/login/options'),
      parser: (data) {
        final map = Map<String, dynamic>.from(data as Map);
        final body = map['data'] is Map ? Map<String, dynamic>.from(map['data'] as Map) : map;
        return PasskeyLoginOptions.fromJson(body);
      },
      showError: false,
    );
  }

  /// Step 2 of passkey login: verify the assertion and receive the session JWT.
  Future<UserModel> verifyLogin({
    required String id,
    required String challenge,
    required String clientDataJSON,
    required String authenticatorData,
    required String signature,
    String? userHandle,
  }) {
    return safeApiCall(
      () => dioClient.post('passkey/login/verify', data: {
        'id': id,
        'challenge': challenge,
        'rememberMe': false,
        'response': {
          'clientDataJSON': clientDataJSON,
          'authenticatorData': authenticatorData,
          'signature': signature,
          'userHandle': userHandle,
        },
      }),
      parser: (data) {
        final map = Map<String, dynamic>.from(data as Map);
        final body = map['data'] is Map ? Map<String, dynamic>.from(map['data'] as Map) : map;
        return UserModel.fromJSON(body);
      },
      showError: false,
    );
  }

  /// Step 1 of passkey registration (user already authenticated).
  Future<PasskeyRegisterOptions> getRegisterOptions() {
    return safeApiCall(
      () => dioClient.post('passkey/register/options'),
      parser: (data) {
        final map = Map<String, dynamic>.from(data as Map);
        final body = map['data'] is Map ? Map<String, dynamic>.from(map['data'] as Map) : map;
        return PasskeyRegisterOptions.fromJson(body);
      },
      showError: false,
    );
  }

  /// Step 2 of passkey registration: store the new credential.
  Future<bool> verifyRegister({
    required String id,
    required String challenge,
    String? name,
    required String clientDataJSON,
    required String attestationObject,
    List<String>? transports,
  }) {
    return safeApiCall(
      () => dioClient.post('passkey/register/verify', data: {
        'id': id,
        'challenge': challenge,
        if (name != null && name.isNotEmpty) 'name': name,
        'response': {
          'clientDataJSON': clientDataJSON,
          'attestationObject': attestationObject,
          'transports': transports,
        },
      }),
      parser: (_) => true,
      showError: false,
    );
  }
}
