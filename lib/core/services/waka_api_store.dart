import '../constants/api_endpoints.dart';
import 'local_books_service.dart';
import 'waka_scraper_service.dart';

class WakaApiStore {
  WakaApiStore({WakaScraperService? scraper, LocalBooksService? localBooks})
    : _scraper = scraper ?? const WakaScraperService(),
      _localBooks = localBooks ?? const LocalBooksService();

  final WakaScraperService _scraper;
  final LocalBooksService _localBooks;
  WakaScrapeResult? _homeCache;
  WakaScrapeResult? _allBooksCache;

  bool get hasHomeCache => _homeCache != null;

  bool get isHomeCacheFresh {
    final cached = _homeCache;
    if (cached == null) return false;

    return DateTime.now().difference(cached.scrapedAt) <
        ApiConfig.cacheTimeToLive;
  }

  WakaScrapeResult? get cachedHome => _homeCache;

  bool get hasAllBooksCache => _allBooksCache != null;

  bool get isAllBooksCacheFresh {
    final cached = _allBooksCache;
    if (cached == null) return false;

    return DateTime.now().difference(cached.scrapedAt) <
        ApiConfig.cacheTimeToLive;
  }

  WakaScrapeResult? get cachedAllBooks => _allBooksCache;

  Future<WakaScrapeResult> getHome({bool forceRefresh = false}) async {
    if (!forceRefresh && isHomeCacheFresh) {
      return _homeCache!;
    }

    final result = await _fetchHomeWithFallback();
    _homeCache = result;
    return result;
  }

  Future<List<WakaScrapedBook>> getHomeBooks({
    bool forceRefresh = false,
  }) async {
    final home = await getHome(forceRefresh: forceRefresh);
    return home.books;
  }

  Future<WakaScrapeResult> getAll({
    bool forceRefresh = false,
    int maxPagesPerCategory = 6,
  }) async {
    if (!forceRefresh && isAllBooksCacheFresh) {
      return _allBooksCache!;
    }

    final result = await _fetchAllBooksWithFallback(
      maxPagesPerCategory: maxPagesPerCategory,
    );
    _allBooksCache = result;
    return result;
  }

  Future<List<WakaScrapedBook>> getAllBooks({
    bool forceRefresh = false,
    int maxPagesPerCategory = 6,
  }) async {
    final all = await getAll(
      forceRefresh: forceRefresh,
      maxPagesPerCategory: maxPagesPerCategory,
    );
    return all.books;
  }

  Future<List<WakaScrapedCategory>> getHomeCategories({
    bool forceRefresh = false,
  }) async {
    final home = await getHome(forceRefresh: forceRefresh);
    return home.categories;
  }

  void clearHomeCache() {
    _homeCache = null;
  }

  void clearAllBooksCache() {
    _allBooksCache = null;
  }

  Future<WakaScrapeResult> _fetchHomeWithFallback() async {
    try {
      final result = await _scraper.scrapeHome();
      if (result.books.isNotEmpty) return result;
    } on Object {
      // Continue to local JSON when waka.vn is unavailable.
    }

    try {
      final result = await _localBooks.loadBooks();
      if (result.books.isNotEmpty) return result;
      return _fallbackHome();
    } on Object {
      return _fallbackHome();
    }
  }

  Future<WakaScrapeResult> _fetchAllBooksWithFallback({
    required int maxPagesPerCategory,
  }) async {
    try {
      final result = await _scraper.scrapeAllBooks(
        maxPagesPerCategory: maxPagesPerCategory,
      );
      if (result.books.isNotEmpty) return result;
    } on Object {
      // Continue to local JSON when waka.vn is unavailable.
    }

    try {
      final result = await _localBooks.loadBooks();
      if (result.books.isNotEmpty) return result;
      return _fallbackHome();
    } on Object {
      return _fallbackHome();
    }
  }

  WakaScrapeResult _fallbackHome() {
    return WakaScrapeResult(
      pageTitle: 'Waka Demo API',
      description: 'Dữ liệu dự phòng dùng khi không tải được waka.vn.',
      categories: const [
        WakaScrapedCategory(
          title: 'Sách điện tử',
          url: 'https://waka.vn/ebook',
        ),
        WakaScrapedCategory(
          title: 'Sách Hội viên',
          url: 'https://waka.vn/sach-hoi-vien',
        ),
        WakaScrapedCategory(
          title: 'Sách Hiệu Sồi',
          url: 'https://waka.vn/hieu-soi',
        ),
        WakaScrapedCategory(title: 'Waka Shop', url: 'https://waka.vn/shop'),
      ],
      books: _fallbackBooks
          .map(
            (book) => WakaScrapedBook(
              title: book.title,
              url: book.url,
              imageUrl: '',
              section: book.section,
            ),
          )
          .toList(growable: false),
      scrapedAt: DateTime.now(),
    );
  }
}

const _fallbackBooks = [
  WakaScrapedBook(
    title: 'Thoát nợ sống nhẹ',
    url: 'https://waka.vn/ebook/thoat-no-song-nhe-marcus-phung-bxMdzW.html',
    imageUrl:
        'https://307a0e78.vws.vegacdn.vn/view/v2/image/img.book/0/0/1/55930.jpg?v=1&w=350&h=510',
    section: 'Sách mới mỗi ngày - Dành cho Hội viên!',
  ),
  WakaScrapedBook(
    title: 'Chỉ yêu trúc mã',
    url: 'https://waka.vn/ebook/chi-yeu-truc-ma-dang-cap-nhat-bnM2WW.html',
    imageUrl:
        'https://307a0e78.vws.vegacdn.vn/view/v2/image/img.book/0/0/1/55909.jpg?v=1&w=350&h=510',
    section: 'Sách mới mỗi ngày - Dành cho Hội viên!',
  ),
  WakaScrapedBook(
    title: 'Dám kiếm tiền, dám đầu tư',
    url:
        'https://waka.vn/ebook/dam-kiem-tien-dam-dau-tu-marcus-phung-bnM2mW.html',
    imageUrl:
        'https://307a0e78.vws.vegacdn.vn/view/v2/image/img.book/0/0/1/55897.jpg?v=1&w=350&h=510',
    section: 'Sách kỹ năng',
  ),
  WakaScrapedBook(
    title: 'Xuyên không giả làm bạn gái tổng tài',
    url:
        'https://waka.vn/ebook/xuyen-khong-gia-lam-ban-gai-tong-tai-dang-cap-nhat-bV6WOW.html',
    imageUrl:
        'https://307a0e78.vws.vegacdn.vn/view/v2/image/img.book/0/0/1/55882.jpg?v=1&w=350&h=510',
    section: 'Sách Hội viên',
  ),
  WakaScrapedBook(
    title: 'Bẫy lừa đảo',
    url: 'https://waka.vn/ebook/bay-lua-dao-noah-pham-blMDvW.html',
    imageUrl:
        'https://307a0e78.vws.vegacdn.vn/view/v2/image/img.book/0/0/1/55882.jpg?v=1&w=350&h=510',
    section: 'Bảng Xếp Hạng',
  ),
  WakaScrapedBook(
    title: 'Sáu cú sốc thay đổi lịch sử World Cup',
    url:
        'https://waka.vn/ebook/sau-cu-soc-thay-doi-lich-su-world-cup-aron-kim-bNnZ7W.html',
    imageUrl:
        'https://307a0e78.vws.vegacdn.vn/view/v2/image/img.book/0/0/1/55930.jpg?v=1&w=350&h=510',
    section: 'Sồi động mùa World Cup 2026',
  ),
  WakaScrapedBook(
    title: 'Kiếp trước là yêu, kiếp này là buông',
    url:
        'https://waka.vn/ebook/kiep-truoc-la-yeu-kiep-nay-la-buong-dang-cap-nhat-b346QW.html',
    imageUrl:
        'https://307a0e78.vws.vegacdn.vn/view/v2/image/img.book/0/0/1/55909.jpg?v=1&w=350&h=510',
    section: 'Truyện đang được đọc nhiều',
  ),
  WakaScrapedBook(
    title: 'World Cup ly kỳ truyện',
    url: 'https://waka.vn/ebook/world-cup-ly-ky-truyen-aron-kim-bRvGaW.html',
    imageUrl:
        'https://307a0e78.vws.vegacdn.vn/view/v2/image/img.book/0/0/1/55897.jpg?v=1&w=350&h=510',
    section: 'Sồi động mùa World Cup 2026',
  ),
  WakaScrapedBook(
    title: 'Hành trình vĩ đại của nhân loại',
    url: 'https://waka.vn/ebook/hanh-trinh-vi-dai-cua-nhan-loai-demo-1.html',
    imageUrl:
        'https://307a0e78.vws.vegacdn.vn/view/v2/image/img.book/0/0/1/55930.jpg?v=1&w=350&h=510',
    section: 'Sách mới mỗi ngày - Dành cho Hội viên!',
  ),
  WakaScrapedBook(
    title: 'Đọc vị bất kỳ ai',
    url: 'https://waka.vn/ebook/doc-vi-bat-ky-ai-demo-2.html',
    imageUrl:
        'https://307a0e78.vws.vegacdn.vn/view/v2/image/img.book/0/0/1/55897.jpg?v=1&w=350&h=510',
    section: 'Sách Hiệu Sồi',
  ),
  WakaScrapedBook(
    title: 'Nghệ thuật đàm phán',
    url: 'https://waka.vn/ebook/nghe-thuat-dam-phan-demo-3.html',
    imageUrl:
        'https://307a0e78.vws.vegacdn.vn/view/v2/image/img.book/0/0/1/55882.jpg?v=1&w=350&h=510',
    section: 'Sách Hiệu Sồi',
  ),
  WakaScrapedBook(
    title: 'Thần số học - Con số đọc vị con người',
    url: 'https://waka.vn/ebook/than-so-hoc-demo-4.html',
    imageUrl:
        'https://307a0e78.vws.vegacdn.vn/view/v2/image/img.book/0/0/1/55909.jpg?v=1&w=350&h=510',
    section: 'Sách Hiệu Sồi',
  ),
  WakaScrapedBook(
    title: 'Phản biện để bứt phá',
    url: 'https://waka.vn/ebook/phan-bien-de-but-pha-demo-5.html',
    imageUrl:
        'https://307a0e78.vws.vegacdn.vn/view/v2/image/img.book/0/0/1/55930.jpg?v=1&w=350&h=510',
    section: 'Sách Hiệu Sồi',
  ),
  WakaScrapedBook(
    title: 'Siêu cấp cưng chiều',
    url: 'https://waka.vn/ebook/sieu-cap-cung-chieu-demo-6.html',
    imageUrl:
        'https://307a0e78.vws.vegacdn.vn/view/v2/image/img.book/0/0/1/55909.jpg?v=1&w=350&h=510',
    section: 'Bảng Xếp Hạng',
  ),
  WakaScrapedBook(
    title: 'Đập nồi bán sắt đi học',
    url: 'https://waka.vn/ebook/dap-noi-ban-sat-di-hoc-demo-7.html',
    imageUrl:
        'https://307a0e78.vws.vegacdn.vn/view/v2/image/img.book/0/0/1/55882.jpg?v=1&w=350&h=510',
    section: 'Bảng Xếp Hạng',
  ),
  WakaScrapedBook(
    title: 'Ngu ngôn làm giàu cho người mới bắt đầu',
    url: 'https://waka.vn/ebook/ngu-ngon-lam-giau-demo-8.html',
    imageUrl:
        'https://307a0e78.vws.vegacdn.vn/view/v2/image/img.book/0/0/1/55897.jpg?v=1&w=350&h=510',
    section: 'Bảng Xếp Hạng',
  ),
  WakaScrapedBook(
    title: 'Neymar - Thiên tài tranh cãi',
    url: 'https://waka.vn/ebook/neymar-thien-tai-tranh-cai-demo-9.html',
    imageUrl:
        'https://307a0e78.vws.vegacdn.vn/view/v2/image/img.book/0/0/1/55930.jpg?v=1&w=350&h=510',
    section: 'Sồi động mùa World Cup 2026',
  ),
  WakaScrapedBook(
    title: 'Lionel Messi - Hành trình của một thiên tài',
    url: 'https://waka.vn/ebook/lionel-messi-demo-10.html',
    imageUrl:
        'https://307a0e78.vws.vegacdn.vn/view/v2/image/img.book/0/0/1/55909.jpg?v=1&w=350&h=510',
    section: 'Sồi động mùa World Cup 2026',
  ),
  WakaScrapedBook(
    title: 'Wayne Rooney - Quỷ đầu đàn',
    url: 'https://waka.vn/ebook/wayne-rooney-demo-11.html',
    imageUrl:
        'https://307a0e78.vws.vegacdn.vn/view/v2/image/img.book/0/0/1/55882.jpg?v=1&w=350&h=510',
    section: 'Sồi động mùa World Cup 2026',
  ),
  WakaScrapedBook(
    title: 'Chuyện tình bên hiên nhà',
    url: 'https://waka.vn/ebook/chuyen-tinh-ben-hien-nha-demo-12.html',
    imageUrl:
        'https://307a0e78.vws.vegacdn.vn/view/v2/image/img.book/0/0/1/55909.jpg?v=1&w=350&h=510',
    section: 'Truyện đang được đọc nhiều',
  ),
  WakaScrapedBook(
    title: 'Bí mật sau ánh trăng',
    url: 'https://waka.vn/ebook/bi-mat-sau-anh-trang-demo-13.html',
    imageUrl:
        'https://307a0e78.vws.vegacdn.vn/view/v2/image/img.book/0/0/1/55897.jpg?v=1&w=350&h=510',
    section: 'Truyện đang được đọc nhiều',
  ),
  WakaScrapedBook(
    title: 'Tổng tài lạnh lùng và cô vợ nhỏ',
    url: 'https://waka.vn/ebook/tong-tai-lanh-lung-demo-14.html',
    imageUrl:
        'https://307a0e78.vws.vegacdn.vn/view/v2/image/img.book/0/0/1/55882.jpg?v=1&w=350&h=510',
    section: 'Truyện đang được đọc nhiều',
  ),
];
