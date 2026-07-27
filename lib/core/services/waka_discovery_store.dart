import 'dart:convert';

import 'package:flutter/services.dart';

import '../constants/api_endpoints.dart';
import 'rest_api_client.dart';

class WakaDiscoveryBook {
  const WakaDiscoveryBook({
    required this.id,
    required this.title,
    required this.author,
    required this.imageUrl,
    required this.url,
    required this.section,
    required this.price,
    required this.discountPercent,
  });

  final int id;
  final String title;
  final String author;
  final String imageUrl;
  final String url;
  final String section;
  final int price;
  final int discountPercent;

  factory WakaDiscoveryBook.fromApi(Map<String, Object?> json) {
    final category = json['category'];
    final categoryName = category is Map<String, Object?>
        ? category['name'] as String? ?? ''
        : '';
    return WakaDiscoveryBook(
      id: _asInt(json['id']),
      title: json['title'] as String? ?? '',
      author: json['author'] as String? ?? '',
      imageUrl: json['imageUrl'] as String? ?? '',
      url: json['sourceUrl'] as String? ?? '',
      section: categoryName,
      price: _asInt(json['price']),
      discountPercent: _asInt(json['discountPercent']),
    );
  }

  factory WakaDiscoveryBook.fromLocal(Map<String, Object?> json) {
    return WakaDiscoveryBook(
      id: 0,
      title: json['title'] as String? ?? '',
      author: '',
      imageUrl: json['imageUrl'] as String? ?? '',
      url: json['url'] as String? ?? '',
      section: json['section'] as String? ?? '',
      price: _asInt(json['price']),
      discountPercent: _asInt(json['discountPercent']),
    );
  }
}

class WakaRankingEntry {
  const WakaRankingEntry({
    required this.rank,
    required this.score,
    required this.period,
    required this.contentType,
    required this.book,
  });

  final int rank;
  final int score;
  final String period;
  final String contentType;
  final WakaDiscoveryBook book;
}

class WakaRecommendationEntry {
  const WakaRecommendationEntry({
    required this.position,
    required this.reason,
    required this.contentType,
    required this.book,
  });

  final int position;
  final String reason;
  final String contentType;
  final WakaDiscoveryBook book;
}

class WakaDiscoveryStore {
  WakaDiscoveryStore({
    RestApiClient? client,
    this.remoteEnabled = true,
    this.localAssetPath = 'assets/data/discovery.json',
  }) : _client = client ?? const RestApiClient();

  final RestApiClient _client;
  final bool remoteEnabled;
  final String localAssetPath;
  Map<String, Object?>? _localCache;

  Future<List<WakaRankingEntry>> getRankings({
    String period = 'week',
    String contentType = 'ebook',
    int limit = 20,
  }) async {
    if (remoteEnabled) {
      try {
        final uri = Uri.parse(ApiEndpoints.apiRankings).replace(
          queryParameters: {
            'period': period,
            'contentType': contentType,
            'limit': '$limit',
          },
        );
        final response = await _client.getJson(uri);
        final data = response['data'];
        if (data is List<Object?>) {
          final entries = data
              .whereType<Map<String, Object?>>()
              .map(_rankingFromApi)
              .where((entry) => entry.book.title.isNotEmpty)
              .toList(growable: false);
          if (entries.isNotEmpty) return entries;
        }
      } on Object {
        // Continue to the bundled snapshot when the project API is offline.
      }
    }
    return _localRankings(
      period: period,
      contentType: contentType,
      limit: limit,
    );
  }

  Future<List<WakaRecommendationEntry>> getRecommendations({
    String contentType = 'ebook',
    int limit = 20,
  }) async {
    if (remoteEnabled) {
      try {
        final uri = Uri.parse(ApiEndpoints.apiRecommendations).replace(
          queryParameters: {'contentType': contentType, 'limit': '$limit'},
        );
        final response = await _client.getJson(uri);
        final data = response['data'];
        if (data is List<Object?>) {
          final entries = data
              .whereType<Map<String, Object?>>()
              .map(_recommendationFromApi)
              .where((entry) => entry.book.title.isNotEmpty)
              .toList(growable: false);
          if (entries.isNotEmpty) return entries;
        }
      } on Object {
        // Continue to the bundled snapshot when the project API is offline.
      }
    }
    return _localRecommendations(contentType: contentType, limit: limit);
  }

  WakaRankingEntry _rankingFromApi(Map<String, Object?> json) {
    final bookJson = json['book'];
    return WakaRankingEntry(
      rank: _asInt(json['rank']),
      score: _asInt(json['score']),
      period: json['period'] as String? ?? 'week',
      contentType: json['contentType'] as String? ?? 'ebook',
      book: bookJson is Map<String, Object?>
          ? WakaDiscoveryBook.fromApi(bookJson)
          : const WakaDiscoveryBook(
              id: 0,
              title: '',
              author: '',
              imageUrl: '',
              url: '',
              section: '',
              price: 0,
              discountPercent: 0,
            ),
    );
  }

  WakaRecommendationEntry _recommendationFromApi(Map<String, Object?> json) {
    final bookJson = json['book'];
    return WakaRecommendationEntry(
      position: _asInt(json['position']),
      reason: json['reason'] as String? ?? '',
      contentType: json['contentType'] as String? ?? 'ebook',
      book: bookJson is Map<String, Object?>
          ? WakaDiscoveryBook.fromApi(bookJson)
          : const WakaDiscoveryBook(
              id: 0,
              title: '',
              author: '',
              imageUrl: '',
              url: '',
              section: '',
              price: 0,
              discountPercent: 0,
            ),
    );
  }

  Future<List<WakaRankingEntry>> _localRankings({
    required String period,
    required String contentType,
    required int limit,
  }) async {
    final data = await _loadLocal();
    final rawEntries = data['rankings'];
    if (rawEntries is! List<Object?>) return const [];
    return rawEntries
        .whereType<Map<String, Object?>>()
        .where(
          (json) =>
              (json['period'] as String? ?? 'week') == period &&
              (json['contentType'] as String? ?? 'ebook') == contentType,
        )
        .map(
          (json) => WakaRankingEntry(
            rank: _asInt(json['rank']),
            score: _asInt(json['score']),
            period: json['period'] as String? ?? 'week',
            contentType: json['contentType'] as String? ?? 'ebook',
            book: WakaDiscoveryBook.fromLocal(json),
          ),
        )
        .take(limit)
        .toList(growable: false);
  }

  Future<List<WakaRecommendationEntry>> _localRecommendations({
    required String contentType,
    required int limit,
  }) async {
    final data = await _loadLocal();
    final rawEntries = data['recommendations'];
    if (rawEntries is! List<Object?>) return const [];
    return rawEntries
        .whereType<Map<String, Object?>>()
        .where(
          (json) => (json['contentType'] as String? ?? 'ebook') == contentType,
        )
        .map(
          (json) => WakaRecommendationEntry(
            position: _asInt(json['position']),
            reason: json['reason'] as String? ?? '',
            contentType: json['contentType'] as String? ?? 'ebook',
            book: WakaDiscoveryBook.fromLocal(json),
          ),
        )
        .take(limit)
        .toList(growable: false);
  }

  Future<Map<String, Object?>> _loadLocal() async {
    final cached = _localCache;
    if (cached != null) return cached;
    final rawJson = await rootBundle.loadString(localAssetPath);
    final decoded = jsonDecode(rawJson);
    if (decoded is! Map<String, Object?>) return const {};
    _localCache = decoded;
    return decoded;
  }
}

int _asInt(Object? value) {
  if (value is num) return value.round();
  return double.tryParse('$value')?.round() ?? 0;
}
