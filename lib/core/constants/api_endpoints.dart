abstract final class ApiEndpoints {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:3000/api',
  );
  static const String apiBooks = '$apiBaseUrl/books';
  static const String apiCategories = '$apiBaseUrl/categories';
  static const String apiOffers = '$apiBaseUrl/offers';
  static const String apiRankings = '$apiBaseUrl/rankings';
  static const String apiRecommendations = '$apiBaseUrl/recommendations';
  static const String apiLogin = '$apiBaseUrl/auth/login';
  static const String apiRegister = '$apiBaseUrl/auth/register';
  static const String apiMe = '$apiBaseUrl/auth/me';

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
