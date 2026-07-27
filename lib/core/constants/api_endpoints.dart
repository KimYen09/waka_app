import 'package:flutter/foundation.dart';

abstract final class ApiEndpoints {
  static const String _configuredApiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
  );

  /// Android Emulator reaches the host computer through 10.0.2.2. Desktop,
  /// iOS Simulator and web can reach the local backend directly. Physical
  /// Android devices must provide the computer's LAN IP through API_BASE_URL.
  static final String apiBaseUrl = _configuredApiBaseUrl.isNotEmpty
      ? _configuredApiBaseUrl
      : kIsWeb || defaultTargetPlatform != TargetPlatform.android
      ? 'http://127.0.0.1:3000/api'
      : 'http://10.0.2.2:3000/api';

  static final String apiBooks = '$apiBaseUrl/books';
  static final String apiCategories = '$apiBaseUrl/categories';
  static final String apiOffers = '$apiBaseUrl/offers';
  static final String apiRankings = '$apiBaseUrl/rankings';
  static final String apiRecommendations = '$apiBaseUrl/recommendations';
  static final String apiLogin = '$apiBaseUrl/auth/login';
  static final String apiRegister = '$apiBaseUrl/auth/register';
  static final String apiMe = '$apiBaseUrl/auth/me';
  static final String apiCart = '$apiBaseUrl/cart';
  static final String apiOrders = '$apiBaseUrl/orders';
  static final String apiCheckout = '$apiBaseUrl/checkout';
  static final String apiMembershipPlans = '$apiBaseUrl/membership-plans';
  static final String apiMyMemberships = '$apiBaseUrl/memberships/me';
  static final String apiMembershipPurchase =
      '$apiBaseUrl/memberships/purchase';
  static final String apiPayments = '$apiBaseUrl/payments';

  // Các URL Waka chỉ còn dùng làm nguồn tham khảo/fallback trong dữ liệu cũ.
  static const String wakaBaseUrl = 'https://waka.vn';
  static const String wakaHome = '$wakaBaseUrl/';
  static const String wakaSearch = '$wakaBaseUrl/search?q=';
  static const String wakaPackagePlan = '$wakaBaseUrl/package-plan';

  static const Map<String, String> wakaCategories = {
    'ebook': '$wakaBaseUrl/ebook',
    'memberBooks': '$wakaBaseUrl/sach-hoi-vien',
    'hieuSoi': '$wakaBaseUrl/hieu-soi',
    'audiobook': '$wakaBaseUrl/sach-noi',
    'shop': '$wakaBaseUrl/shop',
    'comic': '$wakaBaseUrl/truyen-tranh',
    'freeBooks': '$wakaBaseUrl/chuyen-muc/sach-mien-phi-wx5',
    'summaryBooks': '$wakaBaseUrl/sach-tom-tat',
  };
}

abstract final class ApiConfig {
  static const Duration requestTimeout = Duration(seconds: 12);
  static const Duration cacheTimeToLive = Duration(minutes: 15);
  static const String userAgent = 'Mozilla/5.0 WakaDemoScraper/1.0';
}
