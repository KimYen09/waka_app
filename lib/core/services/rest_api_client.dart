import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../constants/api_endpoints.dart';

class RestApiException implements Exception {
  const RestApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class RestApiClient {
  const RestApiClient({this.client});

  final HttpClient? client;

  Future<Map<String, Object?>> getJson(Uri uri, {String? bearerToken}) {
    return _send('GET', uri, bearerToken: bearerToken);
  }

  Future<Map<String, Object?>> postJson(
    Uri uri,
    Map<String, Object?> body, {
    String? bearerToken,
  }) {
    return _send('POST', uri, body: body, bearerToken: bearerToken);
  }

  Future<Map<String, Object?>> _send(
    String method,
    Uri uri, {
    Map<String, Object?>? body,
    String? bearerToken,
  }) async {
    final httpClient = client ?? HttpClient();
    try {
      final request = await httpClient
          .openUrl(method, uri)
          .timeout(ApiConfig.requestTimeout);
      request.headers.contentType = ContentType.json;
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      if (bearerToken != null && bearerToken.isNotEmpty) {
        request.headers.set(
          HttpHeaders.authorizationHeader,
          'Bearer $bearerToken',
        );
      }
      if (body != null) request.write(jsonEncode(body));

      final response = await request.close().timeout(ApiConfig.requestTimeout);
      final rawBody = await response.transform(utf8.decoder).join();
      final decoded = rawBody.isEmpty
          ? <String, Object?>{}
          : jsonDecode(rawBody);
      if (decoded is! Map<String, Object?>) {
        throw const RestApiException('Phản hồi API không đúng định dạng.');
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw RestApiException(
          decoded['message'] as String? ?? 'Không thể xử lý yêu cầu.',
          statusCode: response.statusCode,
        );
      }
      return decoded;
    } on TimeoutException {
      throw const RestApiException('Kết nối API bị quá thời gian.');
    } on SocketException {
      throw const RestApiException('Không thể kết nối tới máy chủ API.');
    } on FormatException {
      throw const RestApiException('API trả về dữ liệu JSON không hợp lệ.');
    } finally {
      if (client == null) httpClient.close(force: true);
    }
  }
}
