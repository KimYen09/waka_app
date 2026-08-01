import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

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

  final http.Client? client;

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

  Future<Map<String, Object?>> patchJson(
    Uri uri,
    Map<String, Object?> body, {
    String? bearerToken,
  }) {
    return _send('PATCH', uri, body: body, bearerToken: bearerToken);
  }

  Future<Map<String, Object?>> deleteJson(Uri uri, {String? bearerToken}) {
    return _send('DELETE', uri, bearerToken: bearerToken);
  }

  Future<Map<String, Object?>> _send(
    String method,
    Uri uri, {
    Map<String, Object?>? body,
    String? bearerToken,
  }) async {
    final httpClient = client ?? http.Client();
    try {
      final request = http.Request(method, uri)
        ..headers['Accept'] = 'application/json'
        ..headers['Content-Type'] = 'application/json';
      if (bearerToken != null && bearerToken.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $bearerToken';
      }
      if (body != null) request.body = jsonEncode(body);

      final streamedResponse = await httpClient
          .send(request)
          .timeout(ApiConfig.requestTimeout);
      final response = await http.Response.fromStream(
        streamedResponse,
      ).timeout(ApiConfig.requestTimeout);
      final rawBody = utf8.decode(response.bodyBytes);
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
    } on http.ClientException {
      throw const RestApiException('Không thể kết nối tới máy chủ API.');
    } on FormatException {
      throw const RestApiException('API trả về dữ liệu JSON không hợp lệ.');
    } finally {
      if (client == null) httpClient.close();
    }
  }
}
