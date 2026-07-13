import 'dart:async';


import 'package:flutter/material.dart';

import '../../core/services/local_banners_service.dart';
import '../../core/services/waka_api_store.dart';
import '../../core/services/waka_scraper_service.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/icons/acorn_icon.dart';

const _homeIllustrationAsset = 'assets/images/welcome_books.jpg';

class HomeBook {
  const HomeBook({
    required this.title,
    required this.colors,
    required this.icon,
    this.badge = 'HỘI VIÊN',
    this.badgeColor = const Color(0xFFFFB51F),
    this.price = '',
    this.assetAlignment = Alignment.center,
    this.imageUrl = '',
    this.section = '',
    this.url = '',
  });

  final String title;
  final List<Color> colors;
  final IconData icon;
  final String badge;
  final Color badgeColor;
  final String price;
  final Alignment assetAlignment;
  final String imageUrl;
  final String section;
  final String url;
}

const dailyBooks = [
  HomeBook(
    title: 'Xuyên không giả làm bạn gái tổng tài',
    colors: [Color(0xFF141414), Color(0xFF513016)],
    icon: Icons.diamond_outlined,
    assetAlignment: Alignment.topCenter,
  ),
  HomeBook(
    title: 'Bẫy lừa đảo',
    colors: [Color(0xFF06111F), Color(0xFF0B4B7D)],
    icon: Icons.credit_card_rounded,
    assetAlignment: Alignment.center,
  ),
  HomeBook(
    title: 'Sáu cú sốc thay đổi lịch sử',
    colors: [Color(0xFF1B2B3D), Color(0xFFD99B16)],
    icon: Icons.emoji_events_outlined,
    assetAlignment: Alignment.bottomCenter,
  ),
  HomeBook(
    title: 'Hành trình vĩ đại của nhân loại',
    colors: [Color(0xFFD9BA75), Color(0xFF7F4E20)],
    icon: Icons.public_rounded,
    assetAlignment: Alignment.topCenter,
  ),
];

const rankingBooks = [
  HomeBook(
    title: 'Siêu cấp cưng chiều',
    colors: [Color(0xFFDAB25A), Color(0xFF4D2117)],
    icon: Icons.auto_stories_outlined,
    assetAlignment: Alignment.topCenter,
  ),
  HomeBook(
    title: 'Đập nồi bán sắt đi học',
    colors: [Color(0xFF1D2744), Color(0xFF8798D7)],
    icon: Icons.rocket_launch_outlined,
    assetAlignment: Alignment.center,
  ),
  HomeBook(
    title: 'Ngu ngôn làm giàu cho người mới bắt đầu',
    colors: [Color(0xFF14A783), Color(0xFFF0922B)],
    icon: Icons.savings_outlined,
    badge: '79.000đ',
    badgeColor: Color(0xFFE83BA7),
    assetAlignment: Alignment.bottomCenter,
  ),
];

const footballBooks = [
  HomeBook(
    title: 'Neymar - Thiên tài tranh cãi',
    colors: [Color(0xFF5BA4FF), Color(0xFF0C4FA5)],
    icon: Icons.sports_soccer_rounded,
    assetAlignment: Alignment.topCenter,
  ),
  HomeBook(
    title: 'Lionel Messi - Hành trình của một thiên tài',
    colors: [Color(0xFF73221D), Color(0xFF16102A)],
    icon: Icons.sports_soccer_rounded,
    assetAlignment: Alignment.center,
  ),
  HomeBook(
    title: 'Wayne Rooney - Quỷ đầu đàn',
    colors: [Color(0xFF701D20), Color(0xFF160D0F)],
    icon: Icons.sports_soccer_rounded,
    assetAlignment: Alignment.bottomCenter,
  ),
];

const skillBooks = [
  HomeBook(
    title: 'Thành tích cao, thu nhập thấp',
    colors: [Color(0xFFFFB60D), Color(0xFFFF8A00)],
    icon: Icons.school_outlined,
    badge: '59.000đ',
    badgeColor: Color(0xFFE83BA7),
  ),
  HomeBook(
    title: 'Thần số học - Con số đọc vị con người',
    colors: [Color(0xFF15100B), Color(0xFFB88236)],
    icon: Icons.auto_awesome_rounded,
    badge: '29.000đ',
    badgeColor: Color(0xFFE83BA7),
  ),
  HomeBook(
    title: 'Phản biện để bứt phá',
    colors: [Color(0xFF0B4779), Color(0xFFE6A11A)],
    icon: Icons.psychology_alt_outlined,
    badge: '59.000đ',
    badgeColor: Color(0xFFE83BA7),
  ),
];

const storyBooks = [
  HomeBook(
    title: 'Truyện HOT - Cánh cửa thời gian',
    colors: [Color(0xFF251333), Color(0xFFB64E91)],
    icon: Icons.auto_stories_rounded,
    assetAlignment: Alignment.topCenter,
  ),
  HomeBook(
    title: 'Chuyện tình bên hiên nhà',
    colors: [Color(0xFF3B1E1E), Color(0xFFE28478)],
    icon: Icons.favorite_border_rounded,
    assetAlignment: Alignment.center,
  ),
  HomeBook(
    title: 'Bí mật sau ánh trăng',
    colors: [Color(0xFF071C2F), Color(0xFF5B78B8)],
    icon: Icons.nights_stay_outlined,
    assetAlignment: Alignment.bottomCenter,
  ),
];

const allHomeBooks = [
  ...dailyBooks,
  ...rankingBooks,
  ...footballBooks,
  ...skillBooks,
  ...storyBooks,
];

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _apiStore = WakaApiStore();
  final _bannerService = const LocalBannersService();
  final _searchController = TextEditingController();
  bool _isSearching = false;
  String _searchText = '';
  int _selectedCategoryIndex = 0;
  bool _isLoadingApi = false;
  String _apiErrorMessage = '';
  List<WakaHomeBanner> _homeBanners = const [];
  List<HomeBook> _apiBooks = const [];

  List<HomeBook> get _filteredBooks {
    final sourceBooks = _allBooks;
    if (_searchText.isEmpty) {
      return sourceBooks;
    }

    return sourceBooks
        .where((book) => _homeMatches(book.title, _searchText))
        .toList();
  }

  List<HomeBook> get _allBooks {
    if (_apiBooks.isEmpty) return allHomeBooks;
    return _apiBooks;
  }

  List<HomeBook> get _apiDailyBooks {
    return _booksFromWaka(
      sectionQueries: const ['Sách mới', 'Sách điện tử', 'ebook'],
      urlQueries: const ['/ebook/'],
      backupTitleQueries: const ['sách', 'đời', 'người', 'hành trình'],
      fallbackBooks: dailyBooks,
    );
  }

  List<HomeBook> get _apiMemberBooks {
    return _booksFromWaka(
      sectionQueries: const ['Sách Hội viên', 'Sách miễn phí'],
      urlQueries: const ['/ebook/'],
      backupTitleQueries: const [
        'yêu',
        'tình',
        'tổng tài',
        'trúc mã',
        'world cup',
        'tiền',
        'học',
      ],
      fallbackBooks: dailyBooks,
    );
  }

  List<HomeBook> get _apiRankingBooks {
    return _booksFromWaka(
      sectionQueries: const ['Bảng Xếp Hạng', 'Top', 'Xếp hạng'],
      backupTitleQueries: const [
        'siêu',
        'bẫy',
        'tiền',
        'giàu',
        'thành công',
        'đọc vị',
      ],
      fallbackBooks: rankingBooks,
    );
  }

  List<HomeBook> get _apiFootballBooks {
    return _booksFromWaka(
      sectionQueries: const ['World Cup', 'Bóng đá', 'Thể thao'],
      titleQueries: const ['world cup', 'neymar', 'messi', 'rooney', 'bóng đá'],
      backupTitleQueries: const [
        'world cup',
        'bóng đá',
        'neymar',
        'messi',
        'rooney',
        'thể thao',
      ],
      fallbackBooks: footballBooks,
    );
  }

  List<HomeBook> get _apiSkillBooks {
    return _booksFromWaka(
      sectionQueries: const ['Sách Hiệu Sồi', 'Kỹ năng', 'Phát triển bản thân'],
      titleQueries: const [
        'tiền',
        'đầu tư',
        'kinh tế',
        'thành công',
        'học',
        'sống',
      ],
      backupTitleQueries: const [
        'kỹ năng',
        'tiền',
        'đầu tư',
        'kinh tế',
        'thành công',
        'quy luật',
        'đàm phán',
      ],
      fallbackBooks: skillBooks,
    );
  }

  List<HomeBook> get _apiStoryBooks {
    return _booksFromWaka(
      sectionQueries: const ['Truyện', 'Truyện tranh'],
      titleQueries: const ['yêu', 'tình', 'truyện', 'trúc mã', 'tổng tài'],
      urlQueries: const ['/truyen-tranh/'],
      backupTitleQueries: const [
        'yêu',
        'tình',
        'truyện',
        'trúc mã',
        'tổng tài',
        'cô vợ',
      ],
      fallbackBooks: storyBooks,
    );
  }

  List<HomeBook> _booksFromWaka({
    required List<String> sectionQueries,
    List<String> titleQueries = const [],
    List<String> urlQueries = const [],
    List<String> backupTitleQueries = const [],
    required List<HomeBook> fallbackBooks,
    int limit = 30,
    int minItems = 10,
  }) {
    if (_apiBooks.isEmpty) return _expandFallbackBooks(fallbackBooks, minItems);

    final books = _dedupeHomeBooks(
      _apiBooks
          .where(
            (book) =>
                _matchesAny(book.section, sectionQueries) ||
                _matchesAny(book.title, titleQueries) ||
                _matchesAny(book.url, urlQueries),
          )
          .toList(growable: false),
    );
    final filledBooks = [...books];

    if (filledBooks.length < minItems) {
      _appendUniqueBooks(
        filledBooks,
        _apiBooks
            .where(
              (book) =>
                  _matchesAny(book.title, backupTitleQueries) ||
                  _matchesAny(book.section, sectionQueries) ||
                  _matchesAny(book.url, urlQueries),
            )
            .toList(growable: false),
        minItems,
      );
    }

    if (filledBooks.length < minItems) {
      _appendUniqueBooks(
        filledBooks,
        _expandFallbackBooks(fallbackBooks, minItems),
        minItems,
      );
    }

    if (filledBooks.length < minItems) {
      return _expandFallbackBooks(filledBooks, minItems);
    }
    return filledBooks.take(limit).toList(growable: false);
  }

  @override
  void initState() {
    super.initState();
    _loadHomeBanners();
    _loadHomeApi();
  }

  Future<void> _loadHomeBanners() async {
    try {
      final banners = await _bannerService.loadHomeBanners();
      if (!mounted) return;

      setState(() {
        _homeBanners = banners;
      });
    } on Object {
      // The book carousel remains available if the local banner data is missing.
    }
  }

  Future<void> _loadHomeApi({bool forceRefresh = false}) async {
    setState(() {
      _isLoadingApi = true;
      _apiErrorMessage = '';
    });

    try {
      final books = await _apiStore.getAllBooks(
        forceRefresh: forceRefresh,
        maxPagesPerCategory: 18,
      );
      if (!mounted) return;

      setState(() {
        _apiBooks = books.map(_mapApiBookToHomeBook).toList();
        _isLoadingApi = false;
      });
    } on Object catch (error) {
      if (!mounted) return;

      setState(() {
        _apiErrorMessage = error.toString();
        _isLoadingApi = false;
      });
    }
  }

  void _openSearch() {
    setState(() => _isSearching = true);
  }

  void _closeSearch() {
    _searchController.clear();
    setState(() {
      _isSearching = false;
      _searchText = '';
    });
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() => _searchText = '');
  }

  void _onSearchChanged(String value) {
    setState(() => _searchText = value.trim());
  }

  void _selectCategory(int index) {
    setState(() => _selectedCategoryIndex = index);
  }

  void _openSectionBooks(String title, List<HomeBook> fallbackBooks) {
    _openHomeBookList(context, title: title, books: fallbackBooks);
  }

  String get _primarySectionTitle {
    return switch (_selectedCategoryIndex) {
      1 => 'Sách Hội viên nổi bật',
      2 => 'Sách Hiệu Sồi chọn lọc',
      3 => 'Truyện đang được đọc nhiều',
      _ => 'Sách mới mỗi ngày - Dành cho Hội viên!',
    };
  }

  List<HomeBook> get _primaryCategoryBooks {
    return switch (_selectedCategoryIndex) {
      1 => _apiMemberBooks,
      2 => _apiSkillBooks,
      3 => _apiStoryBooks,
      _ => _apiDailyBooks,
    };
  }

  Color get _screenBackground {
    return const Color(0xFF080808);
  }

  List<String> get _categoryChips {
    return switch (_selectedCategoryIndex) {
      1 => ['Sách điện tử', 'Sách nói', 'Truyện tranh'],
      2 => ['Kỹ năng', 'Cổ đại', 'Đam mỹ', 'Hiện đại', 'Huyền huyễn'],
      3 => [
        'Thơ - Tản văn',
        'Marketing - Bán hàng',
        'Trinh thám - Kinh dị',
        'Quản trị - Lãnh đạo',
      ],
      _ => ['Sách điện tử', 'Sách Hội viên', 'Sách Hiệu Sồi', 'Truyện'],
    };
  }

  Color get _chipColor {
    return switch (_selectedCategoryIndex) {
      2 => const Color(0xFF20C3C8),
      3 => const Color(0xFFE94E56),
      _ => WakaColors.elevatedSoft,
    };
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasSearchText = _searchText.isNotEmpty;
    final filteredBooks = _filteredBooks;
    final primaryBooks = hasSearchText ? filteredBooks : _primaryCategoryBooks;
    final showingCategoryPage = !hasSearchText && _selectedCategoryIndex != 0;

    return Container(
      color: _screenBackground,
      child: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: _HomeHeader(
                controller: _searchController,
                isSearching: _isSearching,
                hasSearchText: hasSearchText,
                onSearchTap: _openSearch,
                onChanged: _onSearchChanged,
                onClear: _clearSearch,
                onClose: _closeSearch,
                selectedCategoryIndex: _selectedCategoryIndex,
              ),
            ),
            if (!hasSearchText && !showingCategoryPage) ...[
              const SliverToBoxAdapter(child: SizedBox(height: 20)),
              SliverToBoxAdapter(
                child: _CategoryTabs(
                  selectedIndex: _selectedCategoryIndex,
                  onChanged: _selectCategory,
                  onClose: () => _selectCategory(0),
                  showClose: false,
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 20)),
              SliverToBoxAdapter(
                child: _homeBanners.isEmpty
                    ? _FeaturedCategoryCarousel(books: _allBooks)
                    : _OfficialHomeBannerCarousel(banners: _homeBanners),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 30)),
            ] else if (showingCategoryPage) ...[
              const SliverToBoxAdapter(child: SizedBox(height: 18)),
              SliverToBoxAdapter(
                child: _CategoryTabs(
                  selectedIndex: _selectedCategoryIndex,
                  onChanged: _selectCategory,
                  onClose: () => _selectCategory(0),
                  showClose: true,
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 28)),
              SliverToBoxAdapter(
                child: _FeaturedCategoryCarousel(books: _allBooks),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 28)),
              SliverToBoxAdapter(
                child: _CategoryChipSection(
                  chips: _categoryChips,
                  color: _chipColor,
                  books: _allBooks,
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ] else
              const SliverToBoxAdapter(child: SizedBox(height: 28)),
            if (_isLoadingApi)
              const SliverToBoxAdapter(child: _ApiStatusNotice.loading())
            else if (_apiErrorMessage.isNotEmpty)
              SliverToBoxAdapter(
                child: _ApiStatusNotice.error(
                  message:
                      'Không tải được dữ liệu Waka, đang dùng dữ liệu mẫu.',
                  onRetry: () => _loadHomeApi(forceRefresh: true),
                ),
              ),
            SliverToBoxAdapter(
              child: _SectionTitle(
                title: hasSearchText
                    ? 'Kết quả tìm kiếm'
                    : showingCategoryPage
                    ? 'Mới nhất'
                    : _primarySectionTitle,
                onTap: () => _openSectionBooks(
                  hasSearchText
                      ? 'Kết quả tìm kiếm'
                      : showingCategoryPage
                      ? 'Mới nhất'
                      : _primarySectionTitle,
                  primaryBooks,
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 14)),
            SliverToBoxAdapter(
              child: primaryBooks.isEmpty
                  ? const _HomeEmptySearchResult()
                  : _BookShelf(books: primaryBooks),
            ),
            if (!hasSearchText && _selectedCategoryIndex == 0) ...[
              const SliverToBoxAdapter(child: SizedBox(height: 34)),
              SliverToBoxAdapter(
                child: _SectionTitle(
                  title: 'Bảng Xếp Hạng',
                  onTap: () =>
                      _openSectionBooks('Bảng Xếp Hạng', _apiRankingBooks),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 14)),
              SliverToBoxAdapter(child: _BookShelf(books: _apiRankingBooks)),
              const SliverToBoxAdapter(child: SizedBox(height: 34)),
              SliverToBoxAdapter(
                child: _SectionTitle(
                  title: 'Sồi động mùa World Cup 2026',
                  onTap: () => _openSectionBooks(
                    'Sồi động mùa World Cup 2026',
                    _apiFootballBooks,
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 14)),
              SliverToBoxAdapter(child: _BookShelf(books: _apiFootballBooks)),
              const SliverToBoxAdapter(child: SizedBox(height: 34)),
              SliverToBoxAdapter(
                child: _SectionTitle(
                  title: 'TUYỂN TẬP SÁCH KỸ NĂNG,...',
                  onTap: () => _openSectionBooks(
                    'TUYỂN TẬP SÁCH KỸ NĂNG,...',
                    _apiSkillBooks,
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 14)),
              SliverToBoxAdapter(child: _BookShelf(books: _apiSkillBooks)),
            ],
            if (!hasSearchText && _selectedCategoryIndex == 1) ...[
              const SliverToBoxAdapter(child: SizedBox(height: 34)),
              SliverToBoxAdapter(
                child: _SectionTitle(
                  title: 'Sách mới dành cho Hội viên',
                  onTap: () => _openSectionBooks(
                    'Sách mới dành cho Hội viên',
                    _apiDailyBooks,
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 14)),
              SliverToBoxAdapter(child: _BookShelf(books: _apiDailyBooks)),
              const SliverToBoxAdapter(child: SizedBox(height: 34)),
              SliverToBoxAdapter(
                child: _SectionTitle(
                  title: 'Sồi động mùa World Cup 2026',
                  onTap: () => _openSectionBooks(
                    'Sồi động mùa World Cup 2026',
                    _apiFootballBooks,
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 14)),
              SliverToBoxAdapter(child: _BookShelf(books: _apiFootballBooks)),
            ],
            if (!hasSearchText && _selectedCategoryIndex == 2) ...[
              const SliverToBoxAdapter(child: SizedBox(height: 34)),
              SliverToBoxAdapter(
                child: _SectionTitle(
                  title: 'Bảng Xếp Hạng',
                  onTap: () =>
                      _openSectionBooks('Bảng Xếp Hạng', _apiRankingBooks),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 14)),
              SliverToBoxAdapter(child: _BookShelf(books: _apiRankingBooks)),
            ],
            if (!hasSearchText && _selectedCategoryIndex == 3) ...[
              const SliverToBoxAdapter(child: SizedBox(height: 34)),
              SliverToBoxAdapter(
                child: _SectionTitle(
                  title: 'Truyện đề xuất hôm nay',
                  onTap: () => _openSectionBooks(
                    'Truyện đề xuất hôm nay',
                    _apiStoryBooks,
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 14)),
              SliverToBoxAdapter(child: _BookShelf(books: _apiStoryBooks)),
            ],
            const SliverToBoxAdapter(child: SizedBox(height: 22)),
          ],
        ),
      ),
    );
  }
}

bool _homeMatches(String source, String query) {
  return _homeNormalize(source).contains(_homeNormalize(query));
}

bool _matchesAny(String source, List<String> queries) {
  return queries.any((query) => _homeMatches(source, query));
}

void _appendUniqueBooks(
  List<HomeBook> target,
  List<HomeBook> source,
  int minItems,
) {
  for (final book in _dedupeHomeBooks(source)) {
    final exists = target.any(
      (item) =>
          _homeNormalize(item.title) == _homeNormalize(book.title) ||
          (item.url.isNotEmpty && item.url == book.url),
    );
    if (!exists) target.add(book);
    if (target.length >= minItems) break;
  }
}

List<HomeBook> _dedupeHomeBooks(List<HomeBook> books) {
  final seenKeys = <String>{};
  final result = <HomeBook>[];

  for (final book in books) {
    final key = book.url.isNotEmpty
        ? book.url
        : '${_homeNormalize(book.title)}|${book.imageUrl}';
    if (seenKeys.add(key)) {
      result.add(book);
    }
  }

  return result;
}

List<HomeBook> _expandFallbackBooks(List<HomeBook> books, int minItems) {
  if (books.isEmpty || books.length >= minItems) return books;

  final expandedBooks = _dedupeHomeBooks(books);
  _appendUniqueBooks(expandedBooks, allHomeBooks, minItems);

  return expandedBooks;
}

String _homeNormalize(String value) {
  return value
      .toLowerCase()
      .replaceAll('\n', ' ')
      .replaceAll(RegExp('[àáạảãâầấậẩẫăằắặẳẵ]'), 'a')
      .replaceAll(RegExp('[èéẹẻẽêềếệểễ]'), 'e')
      .replaceAll(RegExp('[ìíịỉĩ]'), 'i')
      .replaceAll(RegExp('[òóọỏõôồốộổỗơờớợởỡ]'), 'o')
      .replaceAll(RegExp('[ùúụủũưừứựửữ]'), 'u')
      .replaceAll(RegExp('[ỳýỵỷỹ]'), 'y')
      .replaceAll('đ', 'd');
}

HomeBook _mapApiBookToHomeBook(WakaScrapedBook book) {
  final colors = _colorsForTitle(book.title);
  return HomeBook(
    title: book.title,
    colors: colors,
    icon: _iconForTitle(book.title),
    imageUrl: book.imageUrl,
    section: book.section,
    url: book.url,
    assetAlignment: Alignment.topCenter,
  );
}

List<Color> _colorsForTitle(String title) {
  final normalized = _homeNormalize(title);
  if (normalized.contains('world cup') || normalized.contains('bong da')) {
    return const [Color(0xFF1B4E8C), Color(0xFF0B1D35)];
  }
  if (normalized.contains('tien') || normalized.contains('dau tu')) {
    return const [Color(0xFFD8A21B), Color(0xFF111111)];
  }
  if (normalized.contains('yeu') || normalized.contains('tinh')) {
    return const [Color(0xFF44204B), Color(0xFFB05CA8)];
  }
  if (normalized.contains('hoc') || normalized.contains('song')) {
    return const [Color(0xFF113E5E), Color(0xFF28A6C4)];
  }
  return const [Color(0xFF252038), Color(0xFF6D4FB2)];
}

IconData _iconForTitle(String title) {
  final normalized = _homeNormalize(title);
  if (normalized.contains('world cup') || normalized.contains('bong da')) {
    return Icons.sports_soccer_rounded;
  }
  if (normalized.contains('tien') || normalized.contains('dau tu')) {
    return Icons.savings_outlined;
  }
  if (normalized.contains('yeu') || normalized.contains('tinh')) {
    return Icons.favorite_border_rounded;
  }
  if (normalized.contains('hoc')) return Icons.school_outlined;
  return Icons.auto_stories_outlined;
}

class _ApiStatusNotice extends StatelessWidget {
  const _ApiStatusNotice.loading()
    : message = 'Đang tải dữ liệu từ Waka...',
      onRetry = null,
      loading = true;

  const _ApiStatusNotice.error({required this.message, required this.onRetry})
    : loading = false;

  final String message;
  final VoidCallback? onRetry;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            if (loading)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: WakaColors.accent,
                ),
              )
            else
              const Icon(
                Icons.wifi_off_rounded,
                color: WakaColors.mutedText,
                size: 18,
              ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: WakaColors.mutedText,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                ),
              ),
            ),
            if (onRetry != null)
              TextButton(onPressed: onRetry, child: const Text('Thử lại')),
          ],
        ),
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.controller,
    required this.isSearching,
    required this.hasSearchText,
    required this.onSearchTap,
    required this.onChanged,
    required this.onClear,
    required this.onClose,
    required this.selectedCategoryIndex,
  });

  final TextEditingController controller;
  final bool isSearching;
  final bool hasSearchText;
  final VoidCallback onSearchTap;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final VoidCallback onClose;
  final int selectedCategoryIndex;

  @override
  Widget build(BuildContext context) {
    if (isSearching) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 13, 16, 0),
        child: Row(
          children: [
            const Icon(Icons.grid_view_rounded, color: Colors.white, size: 30),
            const SizedBox(width: 14),
            Expanded(
              child: Container(
                height: 42,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F2F3),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.search_rounded,
                      color: Color(0xFF9FA0A4),
                      size: 24,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: TextField(
                        controller: controller,
                        autofocus: true,
                        onChanged: onChanged,
                        cursorColor: WakaColors.accent,
                        textInputAction: TextInputAction.search,
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          height: 1,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Tìm sách',
                          hintStyle: TextStyle(
                            color: Color(0xFF9FA0A4),
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            height: 1,
                          ),
                          border: InputBorder.none,
                          isCollapsed: true,
                        ),
                      ),
                    ),
                    if (hasSearchText)
                      GestureDetector(
                        onTap: onClear,
                        child: const Icon(
                          Icons.cancel_rounded,
                          color: Color(0xFF9FA0A4),
                          size: 21,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              visualDensity: VisualDensity.compact,
              onPressed: onClose,
              icon: const Icon(
                Icons.close_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 13, 16, 0),
      child: Row(
        children: [
          const Icon(Icons.grid_view_rounded, color: Colors.white, size: 30),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: WakaColors.gold, width: 1.2),
            ),
            child: Row(
              children: [
                selectedCategoryIndex == 2
                    ? const AcornIcon(color: WakaColors.gold, size: 18)
                    : const Icon(
                        Icons.workspace_premium_outlined,
                        color: WakaColors.gold,
                        size: 18,
                      ),
                const SizedBox(width: 5),
                Text(
                  selectedCategoryIndex == 2 ? 'Nạp Sồi' : 'Gói cước',
                  style: const TextStyle(
                    color: WakaColors.gold,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 18),
          const Icon(
            Icons.add_shopping_cart_rounded,
            color: Colors.white,
            size: 28,
          ),
          const SizedBox(width: 18),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: onSearchTap,
            icon: const Icon(
              Icons.search_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
        ],
      ),
    );
  }
}

class _WakaWebBannerCarousel extends StatefulWidget {
  const _WakaWebBannerCarousel({required this.books});

  final List<HomeBook> books;

  @override
  State<_WakaWebBannerCarousel> createState() => _WakaWebBannerCarouselState();
}

class _WakaWebBannerCarouselState extends State<_WakaWebBannerCarousel> {
  late final PageController _pageController;
  Timer? _timer;
  int _currentIndex = 0;

  List<HomeBook> get _bannerBooks {
    final source = widget.books.isEmpty ? allHomeBooks : widget.books;
    return source.take(5).toList(growable: false);
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.88);
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!_pageController.hasClients || _bannerBooks.isEmpty) return;

      final nextIndex = (_currentIndex + 1) % _bannerBooks.length;
      _pageController.animateToPage(
        nextIndex,
        duration: const Duration(milliseconds: 480),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final books = _bannerBooks;
    if (books.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 232,
      child: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: books.length,
              onPageChanged: (index) => setState(() => _currentIndex = index),
              itemBuilder: (context, index) {
                return AnimatedBuilder(
                  animation: _pageController,
                  builder: (context, child) {
                    double distance = 0;
                    if (_pageController.hasClients &&
                        _pageController.position.haveDimensions) {
                      distance = (_pageController.page! - index).abs();
                    } else {
                      distance = (_currentIndex - index).abs().toDouble();
                    }

                    final scale = (1 - distance * 0.045).clamp(0.94, 1.0);
                    return Transform.scale(scale: scale, child: child);
                  },
                  child: _WakaWebBannerCard(book: books[index], index: index),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              books.length,
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: _currentIndex == index ? 20 : 7,
                height: 7,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: _currentIndex == index
                      ? WakaColors.accent
                      : Colors.white.withValues(alpha: 0.30),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WakaWebBannerCard extends StatelessWidget {
  const _WakaWebBannerCard({required this.book, required this.index});

  final HomeBook book;
  final int index;

  @override
  Widget build(BuildContext context) {
    final accent = book.colors[index % book.colors.length];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.42),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _BookArtwork(book: book),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.black.withValues(alpha: 0.18),
                    accent.withValues(alpha: 0.46),
                    Colors.black.withValues(alpha: 0.84),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 18,
              top: 18,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: WakaColors.gold,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: const Text(
                  'WAKA ĐỀ XUẤT',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
              ),
            ),
            Positioned(
              left: 18,
              right: 118,
              bottom: 22,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    book.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      height: 1.05,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 13,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: WakaColors.accent,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: const Text(
                      'Đọc ngay',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              right: 18,
              bottom: 18,
              child: Container(
                width: 72,
                height: 104,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.42),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.34),
                      blurRadius: 14,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: _BookArtwork(book: book),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryTabs extends StatelessWidget {
  const _CategoryTabs({
    required this.selectedIndex,
    required this.onChanged,
    required this.onClose,
    required this.showClose,
  });

  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final VoidCallback onClose;
  final bool showClose;

  static const tabs = [
    'Sách điện tử',
    'Sách Hội viên',
    'Sách Hiệu Sồi',
    'Truyện',
  ];

  @override
  Widget build(BuildContext context) {
    final orderedIndexes = showClose
        ? [
            selectedIndex,
            ...List.generate(
              tabs.length,
              (index) => index,
            ).where((index) => index != selectedIndex),
          ]
        : List.generate(tabs.length, (index) => index);

    return SizedBox(
      height: showClose ? 48 : 32,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, itemIndex) {
          if (showClose && itemIndex == 0) {
            return GestureDetector(
              onTap: onClose,
              child: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white38, width: 1.2),
                  color: Colors.white.withValues(alpha: 0.04),
                ),
                child: const Icon(
                  Icons.close_rounded,
                  color: Colors.white,
                  size: 30,
                ),
              ),
            );
          }

          final tabIndex =
              orderedIndexes[showClose ? itemIndex - 1 : itemIndex];
          final selected = tabIndex == selectedIndex;

          return GestureDetector(
            onTap: () => onChanged(tabIndex),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              height: showClose ? 46 : 32,
              alignment: Alignment.center,
              padding: EdgeInsets.symmetric(horizontal: showClose ? 28 : 0),
              decoration: BoxDecoration(
                color: showClose && selected
                    ? Colors.white.withValues(alpha: 0.11)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(28),
                border: showClose && selected
                    ? Border.all(color: Colors.white38, width: 1.2)
                    : null,
              ),
              child: Text(
                tabs[tabIndex],
                style: TextStyle(
                  color: Colors.white.withValues(alpha: selected ? 0.94 : 0.68),
                  fontSize: showClose
                      ? (selected ? 24 : 23)
                      : (selected ? 18.5 : 17.5),
                  fontWeight: FontWeight.w800,
                  height: 1.05,
                ),
              ),
            ),
          );
        },
        separatorBuilder: (_, _) => SizedBox(width: showClose ? 12 : 26),
        itemCount: showClose ? tabs.length + 1 : tabs.length,
      ),
    );
  }
}

class _OfficialHomeBannerCarousel extends StatefulWidget {
  const _OfficialHomeBannerCarousel({required this.banners});

  final List<WakaHomeBanner> banners;

  @override
  State<_OfficialHomeBannerCarousel> createState() =>
      _OfficialHomeBannerCarouselState();
}

class _OfficialHomeBannerCarouselState
    extends State<_OfficialHomeBannerCarousel> {
  late final PageController _pageController;
  Timer? _timer;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.66);
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!_pageController.hasClients || widget.banners.isEmpty) return;

      final nextIndex = (_currentIndex + 1) % widget.banners.length;
      _pageController.animateToPage(
        nextIndex,
        duration: const Duration(milliseconds: 480),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.banners.isEmpty) return const SizedBox.shrink();
    final width = MediaQuery.sizeOf(context).width;

    return SizedBox(
      height: 460,
      child: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: widget.banners.length,
              onPageChanged: (index) => setState(() => _currentIndex = index),
              itemBuilder: (context, index) {
                return AnimatedBuilder(
                  animation: _pageController,
                  builder: (context, child) {
                    double distance = 0;
                    if (_pageController.hasClients &&
                        _pageController.position.haveDimensions) {
                      distance = (_pageController.page! - index).abs();
                    } else {
                      distance = (_currentIndex - index).abs().toDouble();
                    }

                    final scale = (1 - distance * 0.08).clamp(0.88, 1.0);
                    final opacity = (1 - distance * 0.30).clamp(0.56, 1.0);

                    return Center(
                      child: Opacity(
                        opacity: opacity,
                        child: Transform.scale(scale: scale, child: child),
                      ),
                    );
                  },
                  child: _OfficialHomeBannerCard(
                    banner: widget.banners[index],
                    width: width * 0.66,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              widget.banners.length,
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: _currentIndex == index ? 20 : 7,
                height: 7,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: _currentIndex == index
                      ? WakaColors.accent
                      : Colors.white.withValues(alpha: 0.34),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OfficialHomeBannerCard extends StatelessWidget {
  const _OfficialHomeBannerCard({required this.banner, required this.width});

  final WakaHomeBanner banner;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 430,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.34),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.network(
        banner.imageUrl,
        fit: BoxFit.cover,
        alignment: Alignment.center,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF302242), Color(0xFF6B3A68)],
              ),
            ),
            child: const Center(
              child: Icon(
                Icons.image_not_supported_outlined,
                color: Colors.white70,
                size: 56,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FeaturedCategoryCarousel extends StatefulWidget {
  const _FeaturedCategoryCarousel({required this.books});

  final List<HomeBook> books;

  @override
  State<_FeaturedCategoryCarousel> createState() =>
      _FeaturedCategoryCarouselState();
}

class _FeaturedCategoryCarouselState extends State<_FeaturedCategoryCarousel> {
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.66);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    return SizedBox(
      height: 430,
      child: PageView.builder(
        controller: _pageController,
        itemCount: widget.books.length,
        itemBuilder: (context, index) {
          return AnimatedBuilder(
            animation: _pageController,
            builder: (context, child) {
              double distance = 0;
              if (_pageController.hasClients &&
                  _pageController.position.haveDimensions) {
                distance = (_pageController.page! - index).abs();
              }

              final scale = (1 - distance * 0.08).clamp(0.88, 1.0);
              final opacity = (1 - distance * 0.30).clamp(0.56, 1.0);

              return Center(
                child: Opacity(
                  opacity: opacity,
                  child: Transform.scale(scale: scale, child: child),
                ),
              );
            },
            child: _FeaturedCover(
              book: widget.books[index],
              width: width * 0.66,
            ),
          );
        },
      ),
    );
  }
}

class _FeaturedCover extends StatelessWidget {
  const _FeaturedCover({required this.book, required this.width});

  final HomeBook book;
  final double width;

  @override
  Widget build(BuildContext context) {
    final hasRemoteImage = book.imageUrl.isNotEmpty;

    return Container(
      width: width,
      height: 410,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.34),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _BookArtwork(book: book),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: book.colors
                    .map(
                      (color) =>
                          color.withValues(alpha: hasRemoteImage ? 0.10 : 0.62),
                    )
                    .toList(),
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: hasRemoteImage ? 0.20 : 0.58),
                ],
              ),
            ),
          ),
          if (!hasRemoteImage)
            Center(
              child: Icon(
                book.icon,
                color: Colors.white.withValues(alpha: 0.64),
                size: 92,
              ),
            ),
          Positioned(
            left: 22,
            right: 22,
            bottom: 50,
            child: Text(
              book.title,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.w900,
                height: 1.02,
              ),
            ),
          ),
          Positioned(
            right: 18,
            bottom: 18,
            child: Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withValues(alpha: 0.42),
              ),
              child: const Icon(
                Icons.menu_book_rounded,
                color: Colors.white,
                size: 32,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryChipSection extends StatelessWidget {
  const _CategoryChipSection({
    required this.chips,
    required this.color,
    required this.books,
  });

  final List<String> chips;
  final Color color;
  final List<HomeBook> books;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.fromLTRB(12, 18, 12, 26),
      child: Column(
        children: [
          _SectionTitle(
            title: 'Danh mục',
            actionLabel: 'Xem tất cả',
            onTap: () => _openHomeBookList(
              context,
              title: 'Tất cả danh mục',
              books: books,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 50,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemBuilder: (context, index) {
                final chip = chips[index];
                final chipBooks = _booksForCategory(chip, books);

                return InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: () =>
                      _openHomeBookList(context, title: chip, books: chipBooks),
                  child: Ink(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: index.isEven
                          ? color
                          : color.withValues(alpha: 0.82),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Center(
                      child: Text(
                        chip,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 21,
                          fontWeight: FontWeight.w500,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
                );
              },
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemCount: chips.length,
            ),
          ),
        ],
      ),
    );
  }
}

List<HomeBook> _booksForCategory(String category, List<HomeBook> books) {
  final matchedBooks = _dedupeHomeBooks(
    books
        .where(
          (book) =>
              _homeMatches(book.section, category) ||
              _homeMatches(book.title, category) ||
              _homeMatches(book.url, _urlQueryForCategory(category)),
        )
        .toList(growable: false),
  );

  if (matchedBooks.length >= 10) return matchedBooks;

  final filledBooks = [...matchedBooks];
  _appendUniqueBooks(
    filledBooks,
    books
        .where(
          (book) =>
              _homeMatches(book.title, category) ||
              _homeMatches(book.section, category),
        )
        .toList(growable: false),
    10,
  );

  return filledBooks.isEmpty
      ? books.take(10).toList(growable: false)
      : filledBooks;
}

String _urlQueryForCategory(String category) {
  if (_homeMatches(category, 'Sách nói')) return '/sach-noi/';
  if (_homeMatches(category, 'Truyện')) return '/truyen-tranh/';
  if (_homeMatches(category, 'Combo')) return '/combo/';
  if (_homeMatches(category, 'Sách điện tử') ||
      _homeMatches(category, 'Hội viên') ||
      _homeMatches(category, 'Hiệu Sồi')) {
    return '/ebook/';
  }

  return category;
}

void _openHomeBookList(
  BuildContext context, {
  required String title,
  required List<HomeBook> books,
}) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => _HomeBookListScreen(title: title, books: books),
    ),
  );
}

class _AdBannerCarousel extends StatefulWidget {
  const _AdBannerCarousel();

  @override
  State<_AdBannerCarousel> createState() => _AdBannerCarouselState();
}

class _AdBannerCarouselState extends State<_AdBannerCarousel> {
  static const _bannerCount = 3;

  late final PageController _pageController;
  Timer? _autoSlideTimer;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.66);
    _autoSlideTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!_pageController.hasClients) return;

      final nextIndex = (_currentIndex + 1) % _bannerCount;
      _pageController.animateToPage(
        nextIndex,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _autoSlideTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final cardWidth = width * 0.65;

    return SizedBox(
      height: 418,
      child: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: _bannerCount,
              onPageChanged: (index) => setState(() => _currentIndex = index),
              itemBuilder: (context, index) {
                return AnimatedBuilder(
                  animation: _pageController,
                  builder: (context, child) {
                    double distance = 0;
                    if (_pageController.hasClients &&
                        _pageController.position.haveDimensions) {
                      distance = (_pageController.page! - index).abs();
                    } else {
                      distance = (_currentIndex - index).abs().toDouble();
                    }

                    final scale = (1 - distance * 0.08).clamp(0.9, 1.0);
                    final opacity = (1 - distance * 0.35).clamp(0.58, 1.0);

                    return Align(
                      alignment: Alignment.topCenter,
                      child: Opacity(
                        opacity: opacity,
                        child: Transform.scale(
                          scale: scale,
                          alignment: Alignment.topCenter,
                          child: child,
                        ),
                      ),
                    );
                  },
                  child: _buildBanner(index, cardWidth),
                );
              },
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _bannerCount,
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: _currentIndex == index ? 18 : 6,
                height: 6,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: _currentIndex == index
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.38),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBanner(int index, double cardWidth) {
    return switch (index) {
      0 => _FlashSaleAdBanner(width: cardWidth),
      1 => _MemberAdBanner(width: cardWidth),
      _ => _StoryAdBanner(width: cardWidth),
    };
  }
}

class _FlashSaleAdBanner extends StatelessWidget {
  const _FlashSaleAdBanner({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: width,
          height: 366,
          decoration: BoxDecoration(
            color: const Color(0xFFC6FF21),
            borderRadius: BorderRadius.circular(10),
            boxShadow: const [
              BoxShadow(
                color: Colors.black45,
                blurRadius: 16,
                offset: Offset(0, 8),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              Positioned(
                right: -30,
                top: -20,
                child: Transform.rotate(
                  angle: 0.12,
                  child: Container(
                    width: 210,
                    height: 58,
                    color: const Color(0xFFE989D2),
                  ),
                ),
              ),
              Positioned(
                left: -32,
                bottom: 58,
                child: Transform.rotate(
                  angle: -0.75,
                  child: Container(
                    width: 128,
                    height: 86,
                    color: const Color(0xFFE989D2),
                  ),
                ),
              ),
              const Positioned(left: 24, top: 58, child: _CountdownBadge()),
              const Positioned(
                right: 34,
                top: 80,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Giá gốc',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        height: 1,
                      ),
                    ),
                    Text(
                      '99k',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 28.5,
                        decoration: TextDecoration.lineThrough,
                        decorationColor: Colors.red,
                        decorationThickness: 2,
                        height: 0.9,
                      ),
                    ),
                  ],
                ),
              ),
              const Positioned(
                left: 26,
                top: 148,
                child: Text.rich(
                  TextSpan(
                    text: 'Ưu đãi ',
                    children: [
                      TextSpan(
                        text: '49k',
                        style: TextStyle(fontSize: 60, letterSpacing: 0),
                      ),
                      TextSpan(
                        text: ' chỉ\ncòn',
                        style: TextStyle(fontSize: 12.5, height: 0.78),
                      ),
                    ],
                  ),
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 45,
                    fontFamily: 'serif',
                    height: 0.84,
                  ),
                ),
              ),
              Positioned(
                left: 25,
                right: 25,
                bottom: 30,
                child: const _LaptopAdMockup(),
              ),
            ],
          ),
        ),
        Transform.translate(
          offset: const Offset(0, -1),
          child: Container(
            width: width * 0.9,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: WakaColors.danger,
              borderRadius: BorderRadius.circular(7),
            ),
            child: const Text(
              '🔥 Gồm ~40 cuốn sách mới nhất 20...',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14.5,
                fontWeight: FontWeight.w800,
                height: 1,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LaptopAdMockup extends StatelessWidget {
  const _LaptopAdMockup();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 118,
      decoration: BoxDecoration(
        color: const Color(0xFF191919),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: Colors.black, width: 4),
      ),
      child: Column(
        children: [
          Container(
            height: 20,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: const Text(
              'FLASH SALE THÁNG 6 - Đồng giá 49K!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 7.8,
                fontWeight: FontWeight.w800,
                height: 1,
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: GridView.count(
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 6,
                mainAxisSpacing: 5,
                crossAxisSpacing: 5,
                childAspectRatio: 0.68,
                children: List.generate(
                  12,
                  (index) => _MiniCover(index: index),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CountdownBadge extends StatelessWidget {
  const _CountdownBadge();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 70,
          height: 58,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Color(0xFFE91E73), width: 5),
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: const Text(
            'còn\n3..2..1',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFFE91E73),
              fontSize: 15,
              fontWeight: FontWeight.w800,
              height: 0.9,
            ),
          ),
        ),
        const SizedBox(width: 4),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SaleLabel(text: 'ngày', color: Color(0xFFE91E73)),
            _SaleLabel(text: 'cuối', color: Color(0xFF7A239E)),
          ],
        ),
      ],
    );
  }
}

class _SaleLabel extends StatelessWidget {
  const _SaleLabel({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -0.03,
      child: Container(
        margin: const EdgeInsets.only(bottom: 3),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        color: color,
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18.5,
            fontWeight: FontWeight.w800,
            height: 1,
          ),
        ),
      ),
    );
  }
}

class _MiniCover extends StatelessWidget {
  const _MiniCover({required this.index});

  final int index;

  static const colors = [
    Color(0xFFF4EEE6),
    Color(0xFFFF9BAA),
    Color(0xFFDB654F),
    Color(0xFF3B576E),
    Color(0xFFB66BE3),
    Color(0xFFFF682A),
    Color(0xFF2C221D),
    Color(0xFFF0D3DB),
    Color(0xFF32256E),
    Color(0xFFDDE9C5),
    Color(0xFF9ECE44),
    Color(0xFF153B7C),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: colors[index % colors.length],
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

class _MemberAdBanner extends StatelessWidget {
  const _MemberAdBanner({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 328,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF6E0B8), Color(0xFFF7FBEC), Color(0xFFF3B1A5)],
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            _homeIllustrationAsset,
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFFF6E0B8).withValues(alpha: 0.62),
                  const Color(0xFF913D2F).withValues(alpha: 0.72),
                ],
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(18),
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Text(
                'Ưu đãi\nHội viên',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StoryAdBanner extends StatelessWidget {
  const _StoryAdBanner({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 328,
      decoration: BoxDecoration(
        color: const Color(0xFF17110C),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF3A2A18)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            _homeIllustrationAsset,
            fit: BoxFit.cover,
            alignment: Alignment.bottomCenter,
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.15),
                  const Color(0xFF17110C).withValues(alpha: 0.86),
                ],
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(18),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Text(
                'Truyện\nHOT',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFFEAD9BA),
                  fontSize: 23,
                  fontWeight: FontWeight.w800,
                  height: 1.05,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    required this.onTap,
    this.actionLabel,
  });

  final String title;
  final VoidCallback onTap;
  final String? actionLabel;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                ),
              ),
            ),
            if (actionLabel != null) ...[
              Text(
                actionLabel!,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.72),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  height: 1,
                ),
              ),
              const SizedBox(width: 2),
            ],
            const Icon(
              Icons.chevron_right_rounded,
              color: Colors.white,
              size: 34,
            ),
          ],
        ),
      ),
    );
  }
}

class _BookShelf extends StatelessWidget {
  const _BookShelf({required this.books});

  final List<HomeBook> books;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 262,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) => _BookCard(book: books[index]),
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemCount: books.length,
      ),
    );
  }
}

class _HomeEmptySearchResult extends StatelessWidget {
  const _HomeEmptySearchResult();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 205,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, color: Colors.white54, size: 54),
          SizedBox(height: 12),
          Text(
            'Không tìm thấy sách',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Thử nhập tên sách khác',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 15,
              fontWeight: FontWeight.w600,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeBookListScreen extends StatelessWidget {
  const _HomeBookListScreen({required this.title, required this.books});

  final String title;
  final List<HomeBook> books;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080808),
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 16, 12, 10),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                          height: 1.05,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(12, 16, 12, 28),
              sliver: SliverGrid.builder(
                itemCount: books.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 22,
                  mainAxisExtent: 238,
                ),
                itemBuilder: (context, index) =>
                    _BookGridCard(book: books[index]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BookGridCard extends StatelessWidget {
  const _BookGridCard({required this.book});

  final HomeBook book;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _BookCoverImage(book: book),
        const SizedBox(height: 9),
        Text(
          book.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
            height: 1.16,
          ),
        ),
      ],
    );
  }
}

class _BookCard extends StatelessWidget {
  const _BookCard({required this.book});

  final HomeBook book;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 145,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _BookCoverImage(book: book),
          const SizedBox(height: 12),
          Text(
            book.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20.5,
              fontWeight: FontWeight.w500,
              height: 1.16,
            ),
          ),
        ],
      ),
    );
  }
}

class _BookCoverImage extends StatelessWidget {
  const _BookCoverImage({required this.book});

  final HomeBook book;

  @override
  Widget build(BuildContext context) {
    final hasRemoteImage = book.imageUrl.isNotEmpty;

    return Container(
      height: 178,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _BookArtwork(book: book),
          if (hasRemoteImage) ...[
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: book.colors
                      .map((color) => color.withValues(alpha: 0.0))
                      .toList(),
                ),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.0),
                    Colors.black.withValues(alpha: 0.04),
                  ],
                ),
              ),
            ),
          ],
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: book.badgeColor,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(4),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    book.price.isEmpty ? book.badge : book.price,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w900,
                      height: 1,
                    ),
                  ),
                  if (book.badge == 'HỘI VIÊN') ...[
                    const SizedBox(width: 3),
                    const Icon(
                      Icons.workspace_premium_rounded,
                      color: Colors.white,
                      size: 12,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BookArtwork extends StatelessWidget {
  const _BookArtwork({required this.book});

  final HomeBook book;

  @override
  Widget build(BuildContext context) {
    if (book.imageUrl.isEmpty) {
      return _GeneratedBookArtwork(book: book);
    }

    return Image.network(
      book.imageUrl,
      fit: BoxFit.cover,
      alignment: book.assetAlignment,
      errorBuilder: (_, _, _) {
        return _GeneratedBookArtwork(book: book);
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return _GeneratedBookArtwork(book: book);
      },
    );
  }
}

class _GeneratedBookArtwork extends StatelessWidget {
  const _GeneratedBookArtwork({required this.book});

  final HomeBook book;

  @override
  Widget build(BuildContext context) {
    final palette = _generatedPalette(book.title);

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: palette,
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            right: -32,
            top: -26,
            child: Container(
              width: 118,
              height: 118,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.12),
              ),
            ),
          ),
          Positioned(
            left: -20,
            bottom: 22,
            child: Transform.rotate(
              angle: -0.32,
              child: Container(
                width: 124,
                height: 42,
                color: Colors.white.withValues(alpha: 0.13),
              ),
            ),
          ),
          Center(
            child: Icon(
              book.icon,
              color: Colors.white.withValues(alpha: 0.22),
              size: 68,
            ),
          ),
          Positioned(
            left: 14,
            right: 14,
            top: 50,
            child: Text(
              _coverTitle(book.title),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w900,
                height: 1.05,
                shadows: [
                  Shadow(
                    color: Colors.black.withValues(alpha: 0.36),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: Text(
              'WAKA',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.78),
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
                height: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

List<Color> _generatedPalette(String title) {
  const palettes = [
    [Color(0xFF132A4C), Color(0xFF1A8AA4)],
    [Color(0xFF462255), Color(0xFFD65DB1)],
    [Color(0xFF503516), Color(0xFFF0A11A)],
    [Color(0xFF163D2E), Color(0xFF47C982)],
    [Color(0xFF391B24), Color(0xFFD94B64)],
    [Color(0xFF111827), Color(0xFF6D7DF2)],
    [Color(0xFF3C2218), Color(0xFFC9834B)],
    [Color(0xFF12312E), Color(0xFF16C7B4)],
  ];
  final hash = title.codeUnits.fold<int>(0, (sum, code) => sum + code);
  return palettes[hash % palettes.length];
}

String _coverTitle(String title) {
  final normalized = title.replaceAll(' - ', '\n');
  if (normalized.length <= 28) return normalized;
  return normalized.substring(0, 28);
}
