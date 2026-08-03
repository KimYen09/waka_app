import '../constants/api_endpoints.dart';
import 'auth_api_service.dart';
import 'rest_api_client.dart';

class AuthorApplication {
  const AuthorApplication({
    required this.realName,
    required this.penName,
    required this.email,
    required this.phone,
    required this.bio,
    required this.identityDocumentUrl,
    required this.portfolioUrl,
    required this.status,
    required this.reviewNote,
    required this.createdAt,
  });

  final String realName;
  final String penName;
  final String email;
  final String phone;
  final String bio;
  final String identityDocumentUrl;
  final String portfolioUrl;
  final String status;
  final String reviewNote;
  final DateTime? createdAt;

  factory AuthorApplication.fromJson(Map<String, Object?> json) =>
      AuthorApplication(
        realName: _string(json['realName']),
        penName: _string(json['penName']),
        email: _string(json['email']),
        phone: _string(json['phone']),
        bio: _string(json['bio']),
        identityDocumentUrl: _string(json['identityDocumentUrl']),
        portfolioUrl: _string(json['portfolioUrl']),
        status: _string(json['status']),
        reviewNote: _string(json['reviewNote']),
        createdAt: DateTime.tryParse(_string(json['createdAt'])),
      );
}

class AuthorApplicationInput {
  const AuthorApplicationInput({
    required this.realName,
    required this.penName,
    required this.email,
    required this.phone,
    required this.bio,
    required this.identityDocumentUrl,
    required this.portfolioUrl,
  });

  final String realName;
  final String penName;
  final String email;
  final String phone;
  final String bio;
  final String identityDocumentUrl;
  final String portfolioUrl;

  Map<String, Object?> toJson() => {
    'realName': realName,
    'penName': penName,
    'email': email,
    'phone': phone,
    'bio': bio,
    'identityDocumentUrl': identityDocumentUrl,
    'portfolioUrl': portfolioUrl,
  };
}

class AuthorApplicationService {
  const AuthorApplicationService({this.client = const RestApiClient()});

  final RestApiClient client;

  String get _token {
    final value = AuthSession.current?.token;
    if (value == null) {
      throw const RestApiException('Bạn cần đăng nhập để đăng ký tác giả.');
    }
    return value;
  }

  Future<AuthorApplication?> getMine() async {
    final response = await client.getJson(
      Uri.parse('${ApiEndpoints.apiAuthorApplication}/me'),
      bearerToken: _token,
    );
    final data = response['data'];
    return data is Map
        ? AuthorApplication.fromJson(
            data.map((key, value) => MapEntry(key.toString(), value)),
          )
        : null;
  }

  Future<AuthorApplication> submit(AuthorApplicationInput input) async {
    final response = await client.postJson(
      Uri.parse(ApiEndpoints.apiAuthorApplication),
      input.toJson(),
      bearerToken: _token,
    );
    final data = response['data'];
    if (data is! Map) {
      throw const RestApiException('Không đọc được hồ sơ vừa gửi.');
    }
    return AuthorApplication.fromJson(
      data.map((key, value) => MapEntry(key.toString(), value)),
    );
  }
}

String _string(Object? value) => value?.toString() ?? '';
