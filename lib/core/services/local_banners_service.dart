import 'dart:convert';

import 'package:flutter/services.dart';

class WakaHomeBanner {
  const WakaHomeBanner({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.webImageUrl,
    required this.targetUrl,
  });

  final String id;
  final String title;
  final String imageUrl;
  final String webImageUrl;
  final String targetUrl;
}

class LocalBannersService {
  const LocalBannersService({this.assetPath = 'assets/data/home_banners.json'});

  final String assetPath;

  Future<List<WakaHomeBanner>> loadHomeBanners() async {
    final rawJson = await rootBundle.loadString(assetPath);
    final data = jsonDecode(rawJson) as Map<String, Object?>;
    final banners = data['banners'] as List<Object?>? ?? const [];

    return banners
        .whereType<Map<String, Object?>>()
        .map(
          (banner) => WakaHomeBanner(
            id: banner['id'] as String? ?? '',
            title: banner['title'] as String? ?? '',
            imageUrl: banner['imageUrl'] as String? ?? '',
            webImageUrl: banner['webImageUrl'] as String? ?? '',
            targetUrl: banner['targetUrl'] as String? ?? '',
          ),
        )
        .where((banner) => banner.imageUrl.isNotEmpty)
        .toList(growable: false);
  }
}
