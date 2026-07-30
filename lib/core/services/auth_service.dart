import 'package:flutter/foundation.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'auth_api_service.dart';
import 'rest_api_client.dart';

class AuthService {
  AuthService({AuthApiService? authApi})
    : _authApi = authApi ?? const AuthApiService();

  static const _googleWebClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
  );

  static const _googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
  );

  GoogleSignIn? _googleSignIn;
  final AuthApiService _authApi;

  GoogleSignIn _configuredGoogleSignIn() {
    if (kIsWeb && _googleWebClientId.isEmpty) {
      throw const RestApiException(
        'Google Sign-In Web chưa được cấu hình. Hãy chạy Flutter với '
        '--dart-define=GOOGLE_WEB_CLIENT_ID=<OAuth Web Client ID>.',
      );
    }

    return _googleSignIn ??= GoogleSignIn(
      scopes: const ['email', 'profile'],
      clientId: kIsWeb ? _googleWebClientId : null,
      // google_sign_in_web rejects serverClientId. Android uses this Web OAuth
      // client ID as the audience for the ID token sent to our backend.
      serverClientId: kIsWeb || _googleServerClientId.isEmpty
          ? null
          : _googleServerClientId,
    );
  }

  /// Opens the Google account picker and exchanges the verified ID token for
  /// the application's own JWT session.
  Future<AuthResult?> signInWithGoogle() async {
    final account = await _configuredGoogleSignIn().signIn();
    if (account == null) return null;
    final idToken = (await account.authentication).idToken;
    if (idToken == null || idToken.isEmpty) {
      throw const RestApiException(
        'Google chưa trả về ID token. Kiểm tra OAuth Web Client ID của Flutter '
        'và GOOGLE_CLIENT_ID của backend.',
      );
    }
    return _authApi.loginWithGoogle(idToken);
  }

  /// Requests a classic Facebook access token and exchanges it for the
  /// application's own JWT session after backend verification.
  Future<AuthResult?> signInWithFacebook() async {
    final result = await FacebookAuth.instance.login(
      permissions: const ['public_profile', 'email'],
      loginTracking: LoginTracking.enabled,
    );
    if (result.status == LoginStatus.cancelled) return null;
    final accessToken = result.accessToken;
    if (result.status != LoginStatus.success ||
        accessToken == null ||
        accessToken.type != AccessTokenType.classic) {
      throw const RestApiException(
        'Facebook không trả về access token có thể xác minh.',
      );
    }
    return _authApi.loginWithFacebook(accessToken.tokenString);
  }
}
