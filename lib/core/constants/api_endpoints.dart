abstract final class ApiEndpoints {
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
