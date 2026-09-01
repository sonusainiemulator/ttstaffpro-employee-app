import 'package:open_core_hr/api/dio_api/repositories/passkey_repository.dart';
import 'package:open_core_hr/models/user_model.dart';
import 'package:passkeys/authenticator.dart';
import 'package:passkeys/types.dart';

/// Orchestrates the on-device passkey (WebAuthn / biometric) flow with the
/// backend passkey endpoints.
///
///   login():    options → platform biometric prompt → verify → JWT + user
///   register(): options → platform biometric prompt → verify (stores passkey)
class PasskeyService {
  final PasskeyRepository _repository = PasskeyRepository();

  /// Default public-key credential algorithms (ES256, RS256) — the plugin needs
  /// these when the server does not send `pubKeyCredParams`.
  static final List<PubKeyCredParamType> _defaultPubKeyCredParams = [
    PubKeyCredParamType(type: 'public-key', alg: -7), // ES256
    PubKeyCredParamType(type: 'public-key', alg: -257), // RS256
  ];

  /// Signs the user in with a passkey using the device biometric prompt
  /// (fingerprint / face). Returns the authenticated [UserModel] with a JWT.
  Future<UserModel> login() async {
    final options = await _repository.getLoginOptions();

    final authenticator = PasskeyAuthenticator();
    final response = await authenticator.authenticate(
      AuthenticateRequestType(
        relyingPartyId: options.rpId,
        challenge: options.challenge,
        mediation: MediationType.Optional,
        preferImmediatelyAvailableCredentials: false,
        timeout: options.timeout,
        userVerification: options.userVerification,
      ),
    );

    return _repository.verifyLogin(
      id: response.id,
      challenge: options.challenge,
      clientDataJSON: response.clientDataJSON,
      authenticatorData: response.authenticatorData,
      signature: response.signature,
      userHandle: response.userHandle,
    );
  }

  /// Registers a new passkey for the currently authenticated user so they can
  /// later sign in with biometrics instead of a password.
  Future<bool> register({String? name}) async {
    final options = await _repository.getRegisterOptions();

    final authenticator = PasskeyAuthenticator();
    final response = await authenticator.register(
      RegisterRequestType(
        challenge: options.challenge,
        relyingParty: RelyingPartyType(id: options.rpId, name: options.rpName),
        user: UserType(
          id: options.userId,
          name: options.userName,
          displayName: options.userDisplayName,
        ),
        excludeCredentials: const [],
        pubKeyCredParams: options.pubKeyCredParams.isEmpty
            ? _defaultPubKeyCredParams
            : options.pubKeyCredParams
                .map((p) => PubKeyCredParamType(
                      type: (p['type'] ?? 'public-key').toString(),
                      alg: int.tryParse('${p['alg']}') ?? -7,
                    ))
                .toList(),
        timeout: options.timeout,
        attestation: 'none',
      ),
    );

    return _repository.verifyRegister(
      id: response.id,
      challenge: options.challenge,
      name: name,
      clientDataJSON: response.clientDataJSON,
      attestationObject: response.attestationObject,
      transports: response.transports.whereType<String>().toList(),
    );
  }
}
