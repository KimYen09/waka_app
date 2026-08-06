import '../constants/api_endpoints.dart';
import 'rest_api_client.dart';

class AuthUser {
  const AuthUser({
    required this.id,
    required this.identifier,
    this.displayName,
    this.role = 'reader',
    this.accountStatus = 'active',
  });

  final int id;
  final String identifier;
  final String? displayName;
  final String role;
  final String accountStatus;

  bool get isAdmin => role == 'admin' && accountStatus == 'active';
}

class AuthResult {
  const AuthResult({required this.user, required this.token});

  final AuthUser user;
  final String token;
}

abstract final class AuthSession {
  static AuthResult? current;

  static bool get isSignedIn => current != null;

  static void clear() => current = null;

  static Future<AuthResult> ensureSession() async {
    if (current != null) return current!;
    try {
      final guestResult = await const AuthApiService().guestLogin();
      current = guestResult;
      return guestResult;
    } catch (_) {
      const fallbackUser = AuthUser(
        id: 1,
        identifier: 'guest_user',
        displayName: 'Tài khoản Khách',
      );
      const fallback = AuthResult(
        user: fallbackUser,
        token: 'guest_fallback_token',
      );
      current = fallback;
      return fallback;
    }
  }
}

class AuthApiService {
  const AuthApiService({this.client = const RestApiClient()});

  final RestApiClient client;

  Future<AuthResult> guestLogin() async {
    final response = await client.postJson(
      Uri.parse(ApiEndpoints.apiGuestLogin),
      {'guestId': 'demo_guest'},
    );
    return _readAuthResult(response);
  }

  Future<AuthResult> login({
    required String identifier,
    required String password,
  }) async {
    final response = await client.postJson(Uri.parse(ApiEndpoints.apiLogin), {
      'identifier': identifier.trim(),
      'password': password,
    });
    return _readAuthResult(response);
  }

  Future<AuthResult> register({
    required String identifier,
    required String password,
  }) async {
    final response = await client.postJson(
      Uri.parse(ApiEndpoints.apiRegister),
      {'identifier': identifier.trim(), 'password': password},
    );
    return _readAuthResult(response);
  }

  Future<AuthResult> loginWithGoogle(
    String idToken, {
    String? email,
    String? displayName,
    String? googleId,
  }) async {
    final response = await client.postJson(
      Uri.parse(ApiEndpoints.apiGoogleLogin),
      {
        'idToken': idToken,
        if (email != null && email.isNotEmpty) 'email': email,
        if (displayName != null && displayName.isNotEmpty)
          'displayName': displayName,
        if (googleId != null && googleId.isNotEmpty) 'googleId': googleId,
      },
    );
    return _readAuthResult(response);
  }

  Future<AuthResult> loginWithFacebook(String accessToken) async {
    final response = await client.postJson(
      Uri.parse(ApiEndpoints.apiFacebookLogin),
      {'accessToken': accessToken},
    );
    return _readAuthResult(response);
  }

  /// Đổi mật khẩu của tài khoản đang đăng nhập. Backend tự kiểm tra mật khẩu
  /// cũ nên lỗi sai mật khẩu sẽ ném [RestApiException].
  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    final token = AuthSession.current?.token;
    if (token == null || token.isEmpty) {
      throw const RestApiException('Vui lòng đăng nhập lại để đổi mật khẩu.');
    }
    await client.postJson(
      Uri.parse(ApiEndpoints.apiChangePassword),
      {'oldPassword': oldPassword, 'newPassword': newPassword},
      bearerToken: token,
    );
  }

  AuthResult _readAuthResult(Map<String, Object?> response) {
    final data = response['data'];
    if (data is! Map<String, Object?>) {
      throw const RestApiException('Phản hồi đăng nhập không đúng định dạng.');
    }
    final userData = data['user'];
    final token = data['token'];
    if (userData is! Map<String, Object?> || token is! String) {
      throw const RestApiException('Phản hồi đăng nhập thiếu thông tin.');
    }

    final result = AuthResult(
      user: AuthUser(
        id: (userData['id'] as num?)?.toInt() ?? 0,
        identifier: userData['identifier'] as String? ?? '',
        displayName: userData['displayName'] as String?,
        role: userData['role'] as String? ?? 'reader',
        accountStatus: userData['accountStatus'] as String? ?? 'active',
      ),
      token: token,
    );
    AuthSession.current = result;
    return result;
  }
}
