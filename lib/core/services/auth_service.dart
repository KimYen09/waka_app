import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
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
    // Không có serverClientId thì Google vẫn cho chọn tài khoản nhưng trả về
    // idToken = null, nên báo ngay ở đây thay vì để lỗi mơ hồ ở bước sau.
    if (!kIsWeb && _googleServerClientId.isEmpty) {
      throw const RestApiException(
        'Google Sign-In chưa được cấu hình. Hãy chạy Flutter với '
        '--dart-define=GOOGLE_SERVER_CLIENT_ID=<OAuth Web Client ID>. '
        'Giá trị này phải trùng GOOGLE_CLIENT_ID của backend.',
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
  ///
  /// Trả về `null` khi người dùng tự huỷ; ném [RestApiException] kèm mô tả
  /// tiếng Việt cho các lỗi cấu hình để màn hình gọi chỉ việc hiển thị.
  Future<AuthResult?> signInWithGoogle() async {
    final client = _configuredGoogleSignIn();

    String? idToken;
    try {
      final account = await client.signIn();
      if (account == null) return null;
      idToken = (await account.authentication).idToken;
    } on PlatformException catch (error) {
      if (_isGoogleCancellation(error)) return null;
      throw RestApiException(_describeGoogleError(error));
    }

    if (idToken == null || idToken.isEmpty) {
      throw const RestApiException(
        'Google không trả về ID token. Kiểm tra GOOGLE_SERVER_CLIENT_ID truyền '
        'vào Flutter có đúng là Web client ID (không phải Android client ID).',
      );
    }
    return _authApi.loginWithGoogle(idToken);
  }

  /// Người dùng bấm back hoặc đóng cửa sổ chọn tài khoản.
  bool _isGoogleCancellation(PlatformException error) {
    final detail = '${error.code}: ${error.message ?? ''}';
    return error.code == 'sign_in_canceled' ||
        error.code == 'popup_closed' ||
        error.code == 'popup_closed_by_user' ||
        detail.contains('ApiException: 12501');
  }

  /// Đổi mã lỗi thô của Google Play Services thành hướng dẫn xử lý cụ thể.
  String _describeGoogleError(PlatformException error) {
    final detail = '${error.code}: ${error.message ?? ''}';

    if (detail.contains('ApiException: 10')) {
      return 'Google báo DEVELOPER_ERROR (mã 10) — cấu hình OAuth chưa khớp:\n'
          '• SHA-1 của keystore đang build chưa được thêm vào Firebase '
          '(Project settings › Your apps › Android).\n'
          '• Hoặc package name không phải com.example.waka_demo.\n'
          '• Sau khi thêm SHA-1 phải tải lại google-services.json rồi build lại.';
    }
    if (detail.contains('ApiException: 12500')) {
      return 'Thiết bị chưa đăng nhập được Google Play Services. Hãy thêm một '
          'tài khoản Google vào máy/emulator (Settings › Accounts) rồi thử lại.';
    }
    if (detail.contains('ApiException: 12502')) {
      return 'Đang có một phiên đăng nhập Google khác chạy dở. Vui lòng đợi '
          'vài giây rồi thử lại.';
    }
    if (error.code == 'network_error' || detail.contains('ApiException: 7')) {
      return 'Không kết nối được tới Google. Kiểm tra mạng của máy/emulator '
          'rồi thử lại.';
    }
    if (error.code == 'popup_blocked') {
      return 'Trình duyệt đã chặn cửa sổ đăng nhập Google. Hãy cho phép popup '
          'cho localhost rồi thử lại.';
    }
    return 'Không đăng nhập được bằng Google ($detail).';
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
