import '../constants/api_endpoints.dart';
import 'rest_api_client.dart';

class AuthUser {
  const AuthUser({
    required this.id,
    required this.identifier,
    this.displayName,
  });

  final int id;
  final String identifier;
  final String? displayName;
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
}

class AuthApiService {
  const AuthApiService({this.client = const RestApiClient()});

  final RestApiClient client;

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
      ),
      token: token,
    );
    AuthSession.current = result;
    return result;
  }
}
