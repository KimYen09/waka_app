import 'package:flutter/material.dart';

import '../../core/services/auth_api_service.dart';
import '../../core/services/commerce_api_service.dart';
import '../../core/theme/app_theme.dart';
import '../reader/book_detail_screen.dart';
import '../reader/reader_screen.dart';
import '../ai_assistant/ai_assistant_screen.dart';
import '../profile/account_info_screen.dart';

/// Màn "Thư viện" - header (avatar + tabs) đứng yên khi cuộn, phần dưới cuộn qua.
///
/// Tab "Đã mua" lấy từ `GET /api/orders`, tab "Yêu thích" lấy từ
/// `GET /api/favorites`, tab "Tải xuống" lấy từ `GET /api/downloads`, tab
/// "Tiếp tục" lấy từ `GET /api/progress` — được ghi lại mỗi khi lật trang ở
/// màn đọc sách.
class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  static const _service = CommerceApiService();

  int _selectedTab = 0;
  bool _showBanner = true;
  bool _isLoading = false;
  String _error = '';
  List<_ShelfBook> _favorites = const [];
  List<_ShelfBook> _purchased = const [];
  List<_ShelfBook> _downloaded = const [];
  List<_ShelfBook> _readingProgress = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!AuthSession.isSignedIn) return;
    setState(() {
      _isLoading = true;
      _error = '';
    });
    try {
      final favorites = await _service.getFavorites();
      final orders = await _service.getOrders();
      final downloads = await _service.getDownloads();
      List<_ShelfBook> readingProgress = const [];
      try {
        final progressBooks = await _service.getReadingProgressBooks();
        readingProgress = progressBooks
            .map(
              (progress) => _ShelfBook(
                bookId: progress.bookId,
                title: progress.title,
                subtitle: 'Đang đọc • Trang ${progress.currentPage + 1}',
                imageUrl: progress.imageUrl,
              ),
            )
            .toList(growable: false);
      } on Object {
        // Nếu API progress lỗi thì vẫn hiển thị các tab còn lại bình thường.
        readingProgress = const [];
      }

      // Một cuốn có thể nằm trong nhiều đơn, chỉ giữ lần xuất hiện đầu tiên.
      final seenBookIds = <int>{};
      final purchased = <_ShelfBook>[];
      for (final order in orders) {
        for (final item in order.items) {
          if (!seenBookIds.add(item.bookId)) continue;
          purchased.add(
            _ShelfBook(
              bookId: item.bookId,
              title: item.title,
              subtitle: 'Số lượng ${item.quantity}',
              imageUrl: _resolveBookCoverImage(item.bookId, item.title, item.imageUrl),
            ),
          );
        }
      }

      if (!mounted) return;
      setState(() {
        _favorites = favorites
            .map(
              (book) => _ShelfBook(
                bookId: book.bookId,
                title: book.title,
                subtitle: book.author.isEmpty ? 'Waka' : book.author,
                imageUrl: _resolveBookCoverImage(book.bookId, book.title, book.imageUrl),
              ),
            )
            .toList(growable: false);
        _purchased = purchased;
        _downloaded = downloads
            .map(
              (book) => _ShelfBook(
                bookId: book.bookId,
                title: book.title,
                subtitle: book.author.isEmpty ? 'Waka' : book.author,
                imageUrl: _resolveBookCoverImage(book.bookId, book.title, book.imageUrl),
              ),
            )
            .toList(growable: false);
        _readingProgress = readingProgress;
        _isLoading = false;
      });
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _openBook(_ShelfBook book) async {
    final bookData = BookDetailData(
      bookId: book.bookId,
      title: book.title,
      author: book.subtitle,
      imageUrl: book.imageUrl,
      section: 'Thư viện của tôi',
      colors: const [Color(0xFF163D2E), Color(0xFF47C982)],
      icon: Icons.menu_book_rounded,
    );

    if (_selectedTab == 0) {
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(builder: (_) => ReaderScreen(book: bookData)),
      );
    } else {
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => BookDetailScreen(book: bookData),
        ),
      );
    }

    if (mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: WakaColors.background,
      child: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _load,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              SliverPersistentHeader(
                pinned: true,
                delegate: _LibraryHeaderDelegate(
                  selectedTab: _selectedTab,
                  accountLabel:
                      AuthSession.current?.user.displayName ??
                      AuthSession.current?.user.identifier ??
                      'Khách',
                  onTabChanged: (i) {
                    setState(() => _selectedTab = i);
                    _load();
                  },
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
              const SliverToBoxAdapter(child: _CategoryChips()),
              if (_showBanner) ...[
                const SliverToBoxAdapter(child: SizedBox(height: 20)),
                SliverToBoxAdapter(
                  child: _AdBanner(
                    onClose: () => setState(() => _showBanner = false),
                  ),
                ),
              ],
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    _sectionTitle,
                    style: const TextStyle(
                      color: WakaColors.text,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 14)),
              ..._buildContent(),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ),
    );
  }

  String get _sectionTitle => switch (_selectedTab) {
    1 => 'Sách đã mua',
    2 => 'Sách yêu thích',
    3 => 'Đã tải xuống',
    _ => 'Đang đọc dở',
  };

  List<Widget> _buildContent() {
    if (!AuthSession.isSignedIn) {
      return const [
        SliverToBoxAdapter(
          child: _LibraryNotice(
            icon: Icons.lock_outline_rounded,
            message: 'Đăng nhập để xem sách đã mua và danh sách yêu thích.',
          ),
        ),
      ];
    }
    if (_isLoading) {
      return const [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 48),
            child: Center(
              child: CircularProgressIndicator(color: WakaColors.accent),
            ),
          ),
        ),
      ];
    }
    if (_error.isNotEmpty) {
      return [
        SliverToBoxAdapter(
          child: _LibraryNotice(
            icon: Icons.wifi_off_rounded,
            message: _error,
            onRetry: _load,
          ),
        ),
      ];
    }

    if (_selectedTab == 0) {
      if (_readingProgress.isEmpty) {
        return [
          SliverToBoxAdapter(
            child: _LibraryNotice(
              icon: Icons.auto_stories_outlined,
              message:
                  'Chưa có sách nào đang đọc dở. Hãy mở một cuốn sách và lật '
                  'trang để tiến trình được lưu lại.',
            ),
          ),
        ];
      }

      return [
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 20,
              childAspectRatio: 0.56,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) => _LibraryBookCard(
                book: _readingProgress[index],
                onTap: () => _openBook(_readingProgress[index]),
              ),
              childCount: _readingProgress.length,
            ),
          ),
        ),
      ];
    }

    final books = _selectedTab == 1
        ? _purchased
        : _selectedTab == 2
        ? _favorites
        : _downloaded;
    if (books.isEmpty) {
      final (icon, message) = switch (_selectedTab) {
        1 => (
          Icons.shopping_bag_outlined,
          'Bạn chưa mua cuốn sách nào. Ghé Waka Shop để chọn sách nhé.',
        ),
        3 => (
          Icons.download_outlined,
          'Chưa có sách tải xuống. Bấm biểu tượng tải ở màn chi tiết sách để '
              'thêm vào đây.',
        ),
        _ => (
          Icons.favorite_border_rounded,
          'Chưa có sách yêu thích. Bấm biểu tượng trái tim ở màn chi tiết '
              'sách để thêm vào đây.',
        ),
      };
      return [
        SliverToBoxAdapter(
          child: _LibraryNotice(icon: icon, message: message),
        ),
      ];
    }

    return [
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverGrid(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 20,
            childAspectRatio: 0.56,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) => _LibraryBookCard(
              book: books[index],
              onTap: () => _openBook(books[index]),
            ),
            childCount: books.length,
          ),
        ),
      ),
    ];
  }
}

/// Dữ liệu tối giản đủ để vẽ một ô sách trong lưới.
class _ShelfBook {
  const _ShelfBook({
    required this.bookId,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
  });

  final int bookId;
  final String title;
  final String subtitle;
  final String imageUrl;
}

class _LibraryNotice extends StatelessWidget {
  const _LibraryNotice({
    required this.icon,
    required this.message,
    this.onRetry,
  });

  final IconData icon;
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 34, 28, 34),
      child: Column(
        children: [
          Icon(icon, color: Colors.white24, size: 56),
          const SizedBox(height: 14),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: WakaColors.mutedText,
              fontSize: 15,
              height: 1.4,
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('THỬ LẠI'),
              style: FilledButton.styleFrom(
                backgroundColor: WakaColors.accent,
                foregroundColor: Colors.black,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ----------------------------------------------------------------------
// Header pinned: avatar + tên tài khoản + icons, và hàng tab bên dưới
// ----------------------------------------------------------------------
class _LibraryHeaderDelegate extends SliverPersistentHeaderDelegate {
  _LibraryHeaderDelegate({
    required this.selectedTab,
    required this.accountLabel,
    required this.onTabChanged,
  });

  final int selectedTab;
  final String accountLabel;
  final ValueChanged<int> onTabChanged;

  static const _tabs = ['Tiếp tục', 'Đã mua', 'Yêu thích', 'Tải xuống'];
  static const double _height = 150;

  @override
  double get minExtent => _height;

  @override
  double get maxExtent => _height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: WakaColors.background,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF71FFDC), Color(0xFF18C58E)],
                  ),
                ),
                child: const Icon(
                  Icons.person,
                  color: Color(0xCCFFFFFF),
                  size: 30,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    final user = AuthSession.current?.user;
                    final identifier = user?.identifier ?? '';
                    final isEmail = identifier.contains('@');
                    Navigator.of(context).push<void>(
                      MaterialPageRoute<void>(
                        builder: (_) => AccountInfoScreen(
                          displayName: user?.displayName?.isNotEmpty == true
                              ? user!.displayName!
                              : 'Chưa cập nhật',
                          phoneNumber: isEmail ? '' : identifier,
                          email: isEmail ? identifier : null,
                          userId: user?.id.toString() ?? '—',
                        ),
                      ),
                    );
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        accountLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: WakaColors.text,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Xem hồ sơ',
                        style: TextStyle(
                          color: WakaColors.mutedText,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.of(context).push<void>(
                    MaterialPageRoute<void>(
                      builder: (_) => const AiAssistantScreen(),
                    ),
                  );
                },
                child: const Icon(
                  Icons.headset_mic_outlined,
                  color: WakaColors.text,
                  size: 26,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 32,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _tabs.length,
              separatorBuilder: (_, _) => const SizedBox(width: 26),
              itemBuilder: (context, index) {
                final isSelected = index == selectedTab;
                return GestureDetector(
                  onTap: () => onTabChanged(index),
                  child: Text(
                    _tabs[index],
                    style: TextStyle(
                      color: isSelected
                          ? WakaColors.text
                          : WakaColors.mutedText,
                      fontSize: 19,
                      fontWeight: isSelected
                          ? FontWeight.w800
                          : FontWeight.w500,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _LibraryHeaderDelegate oldDelegate) {
    return oldDelegate.selectedTab != selectedTab ||
        oldDelegate.accountLabel != accountLabel;
  }
}

// ----------------------------------------------------------------------
// Chip danh mục
// ----------------------------------------------------------------------
class _CategoryChips extends StatefulWidget {
  const _CategoryChips();

  @override
  State<_CategoryChips> createState() => _CategoryChipsState();
}

class _CategoryChipsState extends State<_CategoryChips> {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: WakaColors.surface,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white12),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.menu_book_rounded, size: 18, color: WakaColors.accent),
          SizedBox(width: 8),
          Text(
            '📖 Sách điện tử',
            style: TextStyle(
              color: WakaColors.text,
              fontSize: 14.5,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// ----------------------------------------------------------------------
// Banner quảng cáo
// ----------------------------------------------------------------------
class _AdBanner extends StatelessWidget {
  const _AdBanner({required this.onClose});
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Stack(
        children: [
          Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0D2B2B), Color(0xFF123A3A)],
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'TRỜI MƯA CÓ XANH ĐƯA!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: WakaColors.accent,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'ĐẶT XE NGAY',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'ƯU ĐÃI TỚI 20%',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'TỐI ĐA 50K',
                      style: TextStyle(
                        color: WakaColors.gold,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            right: 6,
            top: 6,
            child: GestureDetector(
              onTap: onClose,
              child: Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: Colors.black45,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ----------------------------------------------------------------------
// Ô sách trong lưới
// ----------------------------------------------------------------------
class _LibraryBookCard extends StatelessWidget {
  const _LibraryBookCard({required this.book, required this.onTap});

  final _ShelfBook book;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (book.imageUrl.isNotEmpty)
                    Image.network(
                      book.imageUrl,
                      fit: BoxFit.cover,
                      loadingBuilder: (_, child, progress) =>
                          progress == null ? child : const _CoverPlaceholder(),
                      errorBuilder: (_, _, _) => const _CoverPlaceholder(),
                    )
                  else
                    const _CoverPlaceholder(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            book.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: WakaColors.text,
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
              height: 1.2,
            ),
          ),
          Text(
            book.subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: WakaColors.mutedText, fontSize: 11.5),
          ),
        ],
      ),
    );
  }
}

class _CoverPlaceholder extends StatelessWidget {
  const _CoverPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF163D2E), Color(0xFF47C982)],
        ),
      ),
    );
  }
}

String _resolveBookCoverImage(int bookId, String title, String rawUrl) {
  if (rawUrl.trim().isNotEmpty) return rawUrl.trim();
  final lower = title.toLowerCase();
  if (lower.contains('sáu cú sốc') || lower.contains('world cup') || lower.contains('lịch sử')) {
    return 'https://images.unsplash.com/photo-1508098682722-e99c43a406b2?w=400';
  }
  if (lower.contains('hẹn hò') || lower.contains('tỉnh thức')) {
    return 'https://images.unsplash.com/photo-1518241353330-0f7941c2d9b5?w=500';
  }
  if (lower.contains('1000 câu hỏi')) {
    return 'https://307a0e78.vws.vegacdn.vn/view/v2/image/img.book/0/0/1/47101.jpg?v=7&w=480&h=700';
  }
  if (lower.contains('giữa chốn phồn hoa')) {
    return 'https://307a0e78.vws.vegacdn.vn/view/v2/image/img.book/0/0/1/33467.jpg?v=1&w=480&h=700';
  }
  if (lower.contains('làm đĩ')) {
    return 'https://down-vn.img.susercontent.com/file/c98e25971a7301c8248a2506f33d293b';
  }
  if (lower.contains('elon musk')) {
    return 'https://bizweb.dktcdn.net/100/180/408/products/tieu-su-elon-musk.jpg?v=1698399035523';
  }
  if (lower.contains('bác hồ') || lower.contains('niên thiếu')) {
    return 'https://307a0e78.vws.vegacdn.vn/view/v2/image/img.book/0/0/1/41780.jpg?v=1&w=480&h=700';
  }
  return 'https://images.unsplash.com/photo-1544716278-ca5e3f4abd8c?w=400';
}


