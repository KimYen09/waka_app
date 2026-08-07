import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

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
  static const _storage = FlutterSecureStorage();
  static const _storageKey = 'waka_auth_session_v1';

  static AuthResult? current;

  static bool get isSignedIn => current != null;

  static Future<void> clear() async {
    current = null;
    try {
      await _storage.delete(key: _storageKey);
    } on Object {
      // Đăng xuất trong RAM vẫn thành công nếu secure storage không khả dụng.
    }
  }

  static Future<AuthResult> ensureSession() async {
    if (current != null) return current!;
    final restored = await _restore();
    if (restored != null) {
      current = restored;
      return restored;
    }
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

  static Future<AuthResult?> _restore() async {
    try {
      final raw = await _storage.read(key: _storageKey);
      if (raw == null || raw.isEmpty) return null;
      final json = jsonDecode(raw);
      if (json is! Map<String, Object?>) return null;
      final token = json['token'];
      final userJson = json['user'];
      if (token is! String ||
          token.isEmpty ||
          userJson is! Map<String, Object?>) {
        return null;
      }
      final id = (userJson['id'] as num?)?.toInt() ?? 0;
      if (id <= 0) return null;
      return AuthResult(
        user: AuthUser(
          id: id,
          identifier: userJson['identifier'] as String? ?? '',
          displayName: userJson['displayName'] as String?,
          role: userJson['role'] as String? ?? 'reader',
          accountStatus: userJson['accountStatus'] as String? ?? 'active',
        ),
        token: token,
      );
    } on Object {
      return null;
    }
  }

  static Future<void> persist(AuthResult result) {
    return _storage.write(
      key: _storageKey,
      value: jsonEncode({
        'token': result.token,
        'user': {
          'id': result.user.id,
          'identifier': result.user.identifier,
          'displayName': result.user.displayName,
          'role': result.user.role,
          'accountStatus': result.user.accountStatus,
        },
      }),
    );
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

  Future<AuthResult> loginWithGoogle(String idToken) async {
    final response = await client.postJson(
      Uri.parse(ApiEndpoints.apiGoogleLogin),
      {'idToken': idToken},
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
    await client.postJson(Uri.parse(ApiEndpoints.apiChangePassword), {
      'oldPassword': oldPassword,
      'newPassword': newPassword,
    }, bearerToken: token);
  }

  Future<AuthResult> _readAuthResult(Map<String, Object?> response) async {
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
    await AuthSession.persist(result);
    return result;
  }
}
