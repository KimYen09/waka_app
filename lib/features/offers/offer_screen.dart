import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/services/local_books_service.dart';
import '../../core/services/waka_scraper_service.dart';
import '../../core/theme/app_theme.dart';

enum _OfferTab { all, retail, combo }

class OfferScreen extends StatefulWidget {
  const OfferScreen({super.key});

  @override
  State<OfferScreen> createState() => _OfferScreenState();
}

class _OfferScreenState extends State<OfferScreen> {
  final _booksService = const LocalBooksService();
  final _searchController = TextEditingController();
  var _selectedTab = _OfferTab.all;
  var _isSearching = false;
  var _searchText = '';
  List<_OfferBook> _books = const [];

  List<_OfferBook> get _sourceBooks {
    if (_books.isEmpty) return _fallbackOfferBooks;
    return _books;
  }

  List<_OfferBook> get _filteredBooks {
    final books = _sourceBooks
        .where((book) {
          if (_searchText.isEmpty) return true;
          return _matches(book.title, _searchText);
        })
        .toList(growable: false);

    return switch (_selectedTab) {
      _OfferTab.all => books,
      _OfferTab.retail => books.where((book) => !book.isCombo).toList(),
      _OfferTab.combo => books.where((book) => book.isCombo).toList(),
    };
  }

  List<_OfferBook> get _retailBooks =>
      _filteredBooks.where((book) => !book.isCombo).take(12).toList();

  List<_OfferBook> get _comboBooks =>
      _filteredBooks.where((book) => book.isCombo).take(12).toList();

  @override
  void initState() {
    super.initState();
    _loadOfferBooks();
  }

  Future<void> _loadOfferBooks() async {
    try {
      final result = await _booksService.loadBooks();
      final books = _mapBooksToOffers(result.books);
      if (!mounted || books.isEmpty) return;
      setState(() => _books = books);
    } on Object {
      // Fallback data keeps the screen complete for offline demos.
    }
  }

  void _selectTab(_OfferTab tab) {
    setState(() => _selectedTab = tab);
  }

  void _toggleSearch() {
    setState(() => _isSearching = !_isSearching);
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchText = '';
      _isSearching = false;
    });
  }

  void _onSearchChanged(String value) {
    setState(() => _searchText = value.trim());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final heroBook = _retailBooks.isNotEmpty
        ? _retailBooks.first
        : _fallbackOfferBooks.first;
    final showPlans = _selectedTab == _OfferTab.all;
    final showRetail =
        _selectedTab == _OfferTab.all || _selectedTab == _OfferTab.retail;
    final showCombo =
        _selectedTab == _OfferTab.all || _selectedTab == _OfferTab.combo;

    return Container(
      color: WakaColors.background,
      child: SafeArea(
        bottom: false,
        child: Stack(
          children: [                            
            const Positioned.fill(child: _OfferBackground()),
            CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: _OfferHeader(
                    selectedTab: _selectedTab,
                    isSearching: _isSearching,
                    controller: _searchController,
                    onSearchTap: _toggleSearch,
                    onClearSearch: _clearSearch,
                    onSearchChanged: _onSearchChanged,
                    onTabChanged: _selectTab,
                  ),
                ),
                if (_selectedTab != _OfferTab.combo) ...[
                  const SliverToBoxAdapter(child: SizedBox(height: 18)),
                  SliverToBoxAdapter(child: _FlashSaleHero(book: heroBook)),
                ],
                if (showPlans) ...[
                  const SliverToBoxAdapter(child: SizedBox(height: 34)),
                  const SliverToBoxAdapter(child: _MembershipSection()),
                ],
                if (showRetail && _retailBooks.isNotEmpty) ...[
                  const SliverToBoxAdapter(child: SizedBox(height: 34)),
                  SliverToBoxAdapter(
                    child: _OfferShelf(
                      title: 'Sách hay giá tốt',
                      books: _retailBooks,
                    ),
                  ),
                ],
                if (showCombo && _comboBooks.isNotEmpty) ...[
                  const SliverToBoxAdapter(child: SizedBox(height: 36)),
                  SliverToBoxAdapter(
                    child: _OfferShelf(
                      title: 'Combo bán chạy',
                      books: _comboBooks,
                    ),
                  ),
                ],
                const SliverToBoxAdapter(child: SizedBox(height: 96)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _OfferHeader extends StatelessWidget {
  const _OfferHeader({
    required this.selectedTab,
    required this.isSearching,
    required this.controller,
    required this.onSearchTap,
    required this.onClearSearch,
    required this.onSearchChanged,
    required this.onTabChanged,
  });

  final _OfferTab selectedTab;
  final bool isSearching;
  final TextEditingController controller;
  final VoidCallback onSearchTap;
  final VoidCallback onClearSearch;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<_OfferTab> onTabChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 22, 14, 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.84),
            Colors.black.withValues(alpha: 0.54),
            Colors.transparent,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Ưu đãi',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
              ),
              IconButton(
                onPressed: isSearching ? onClearSearch : onSearchTap,
                icon: Icon(
                  isSearching ? Icons.close_rounded : Icons.search_rounded,
                  color: Colors.white,
                  size: 36,
                ),
              ),
            ],
          ),
          if (isSearching) ...[
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              onChanged: onSearchChanged,
              autofocus: true,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                hintText: 'Tìm sách ưu đãi',
                hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.46),
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
                prefixIcon: const Icon(Icons.search, color: Colors.white54),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(28),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ],
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                _OfferTabButton(
                  label: 'Tất cả',
                  icon: Icons.bolt_rounded,
                  active: selectedTab == _OfferTab.all,
                  onTap: () => onTabChanged(_OfferTab.all),
                ),
                const SizedBox(width: 20),
                _OfferTabButton(
                  label: 'Mua lẻ',
                  active: selectedTab == _OfferTab.retail,
                  onTap: () => onTabChanged(_OfferTab.retail),
                ),
                const SizedBox(width: 20),
                _OfferTabButton(
                  label: 'Combo',
                  active: selectedTab == _OfferTab.combo,
                  onTap: () => onTabChanged(_OfferTab.combo),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OfferTabButton extends StatelessWidget {
  const _OfferTabButton({
    required this.label,
    required this.active,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.symmetric(
          horizontal: active ? 18 : 8,
          vertical: active ? 10 : 8,
        ),
        decoration: BoxDecoration(
          color: active ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                color: active ? const Color(0xFFF44977) : Colors.white,
                size: 28,
              ),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: TextStyle(
                color: active ? Colors.black : Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w900,
                height: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FlashSaleHero extends StatefulWidget {
  const _FlashSaleHero({required this.book});

  final _OfferBook book;

  @override
  State<_FlashSaleHero> createState() => _FlashSaleHeroState();
}

class _FlashSaleHeroState extends State<_FlashSaleHero> {
  late final PageController _controller;
  Timer? _countdownTimer;
  int _remainingSeconds = 10000;

  @override
  void initState() {
    super.initState();
    _controller = PageController(viewportFraction: 0.58);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _remainingSeconds <= 0) return;
      setState(() => _remainingSeconds--);
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final books = [widget.book, ..._fallbackOfferBooks.skip(1).take(2)];
    final hours = _remainingSeconds ~/ 3600;
    final minutes = (_remainingSeconds % 3600) ~/ 60;
    final seconds = _remainingSeconds % 60;

    return SizedBox(
      height: 560,
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topCenter,
                  radius: 0.95,
                  colors: [
                    const Color(0xFF3B1021).withValues(alpha: 0.75),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 14,
            top: 4,
            child: Row(
              children: [
                const Text(
                  'FLASH',
                  style: TextStyle(
                    color: Color(0xFFFF3F71),
                    fontSize: 25,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
                const Icon(
                  Icons.bolt_rounded,
                  color: Color(0xFFFF3F71),
                  size: 32,
                ),
                const Text(
                  'SALE',
                  style: TextStyle(
                    color: Color(0xFFFF3F71),
                    fontSize: 25,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
                const SizedBox(width: 14),
                _CountdownBox(text: hours.toString().padLeft(2, '0')),
                const SizedBox(width: 3),
                _CountdownBox(text: minutes.toString().padLeft(2, '0')),
                const SizedBox(width: 3),
                _CountdownBox(text: seconds.toString().padLeft(2, '0')),
              ],
            ),
          ),
          Positioned.fill(
            top: 68,
            child: PageView.builder(
              controller: _controller,
              physics: const BouncingScrollPhysics(),
              itemCount: books.length,
              itemBuilder: (context, index) {
                final book = books[index];
                return AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    var distance = 0.0;
                    if (_controller.hasClients &&
                        _controller.position.haveDimensions) {
                      distance = (_controller.page! - index).abs();
                    }
                    final scale = (1 - distance * 0.10).clamp(0.82, 1.0);
                    final opacity = (1 - distance * 0.40).clamp(0.45, 1.0);
                    return Opacity(
                      opacity: opacity,
                      child: Transform.scale(scale: scale, child: child),
                    );
                  },
                  child: _FlashSaleCard(book: book),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CountdownBox extends StatelessWidget {
  const _CountdownBox({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 19,
          fontWeight: FontWeight.w900,
          height: 1,
        ),
      ),
    );
  }
}

class _FlashSaleCard extends StatelessWidget {
  const _FlashSaleCard({required this.book});

  final _OfferBook book;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: 225,
          height: 300,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(child: _OfferCover(book: book, borderRadius: 6)),
              Positioned(
                right: -14,
                top: -12,
                child: Container(
                  width: 58,
                  height: 58,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFC82C),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    book.discount,
                    style: const TextStyle(
                      color: Color(0xFF562D00),
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              book.oldPrice,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.55),
                fontSize: 25,
                decoration: TextDecoration.lineThrough,
                decorationColor: Colors.white.withValues(alpha: 0.64),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              book.price,
              style: const TextStyle(
                color: Color(0xFFFF3D72),
                fontSize: 31,
                fontWeight: FontWeight.w900,
                height: 1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          book.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 25,
            fontWeight: FontWeight.w600,
            height: 1,
          ),
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF20E59F), Color(0xFF12B892)],
            ),
            borderRadius: BorderRadius.circular(999),
          ),
          child: const Text(
            'MUA NGAY',
            style: TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
        ),
      ],
    );
  }
}

class _MembershipSection extends StatelessWidget {
  const _MembershipSection();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Phù hợp với bạn',
            style: TextStyle(
              color: Colors.white,
              fontSize: 25,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Mở khóa hơn 20.000 nội dung Ebook,\nSách nói, Truyện tranh... với gói Hội viên\nWaka',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.92),
              fontSize: 21,
              fontWeight: FontWeight.w400,
              height: 1.18,
            ),
          ),
          const SizedBox(height: 28),
          const _PlanCard(
            title: 'WAKA 6 THÁNG',
            subtitle: '183 ngày đọc sách',
            price: '399.000đ',
            oldPrice: '414.000đ',
            ribbon: 'TIẾT KIỆM 10%',
          ),
          const SizedBox(height: 16),
          Text(
            'Tự động gia hạn mỗi 6 tháng, hủy bất cứ lúc nào',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.55),
              fontSize: 18,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 28),
          const _PlanCard(
            title: 'WAKA 12 THÁNG',
            subtitle: '365 ngày đọc sách',
            price: '499.000 đ',
            oldPrice: '828.000đ',
            ribbon: 'TẶNG THÊM 02 THÁNG',
            highlighted: true,
          ),
          const SizedBox(height: 16),
          Text(
            'Tự động gia hạn mỗi 12 tháng, hủy bất cứ lúc nào',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.55),
              fontSize: 18,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.title,
    required this.subtitle,
    required this.price,
    required this.oldPrice,
    required this.ribbon,
    this.highlighted = false,
  });

  final String title;
  final String subtitle;
  final String price;
  final String oldPrice;
  final String ribbon;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final borderColor = highlighted
        ? const Color(0xFFFF8B00)
        : WakaColors.accent;

    return Padding(
      padding: EdgeInsets.only(bottom: highlighted ? 54 : 0),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(14, 28, 14, 18),
            decoration: BoxDecoration(
              color: const Color(0xFF101E1E).withValues(alpha: 0.96),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor.withValues(alpha: 0.62)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: WakaColors.accent,
                          fontSize: 25,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.72),
                          fontSize: 22,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      price,
                      maxLines: 1,
                      style: const TextStyle(
                        color: Color(0xFF7CF3E8),
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      oldPrice,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.60),
                        fontSize: 21,
                        decoration: TextDecoration.lineThrough,
                        decorationColor: Colors.white.withValues(alpha: 0.58),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            right: 0,
            top: -15,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFFF9F1A), Color(0xFFE91952)],
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(10),
                  topRight: Radius.circular(10),
                  bottomLeft: Radius.circular(16),
                ),
              ),
              child: Text(
                ribbon,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
            ),
          ),
          if (highlighted)
            Positioned(
              left: 0,
              right: 0,
              bottom: -54,
              child: Container(
                height: 56,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFFF9700), Color(0xFFE5094D)],
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(14),
                    bottomRight: Radius.circular(14),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.card_giftcard_rounded, color: Colors.white),
                    SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        'Tặng thêm 02 tháng',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _OfferShelf extends StatelessWidget {
  const _OfferShelf({required this.title, required this.books});

  final String title;
  final List<_OfferBook> books;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: Colors.white,
                size: 38,
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        SizedBox(
          height: 300,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: books.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              return _OfferBookCard(book: books[index]);
            },
          ),
        ),
      ],
    );
  }
}

class _OfferBookCard extends StatelessWidget {
  const _OfferBookCard({required this.book});

  final _OfferBook book;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              SizedBox(
                height: 195,
                width: 150,
                child: _OfferCover(book: book, borderRadius: 4),
              ),
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: const BoxDecoration(
                    color: Color(0xFFE83BA7),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(4),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        book.price,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          height: 1,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(
                        Icons.shopping_bag_rounded,
                        color: Colors.white,
                        size: 13,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            book.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w500,
              height: 1.16,
            ),
          ),
        ],
      ),
    );
  }
}

class _OfferCover extends StatelessWidget {
  const _OfferCover({required this.book, required this.borderRadius});

  final _OfferBook book;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: book.colors,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: book.imageUrl.isEmpty
          ? _GeneratedOfferCover(book: book)
          : Image.network(
              book.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _GeneratedOfferCover(book: book),
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return _GeneratedOfferCover(book: book);
              },
            ),
    );
  }
}

class _GeneratedOfferCover extends StatelessWidget {
  const _GeneratedOfferCover({required this.book});

  final _OfferBook book;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: book.colors,
            ),
          ),
        ),
        Center(
          child: Icon(
            book.isCombo ? Icons.widgets_rounded : Icons.menu_book_rounded,
            color: Colors.white.withValues(alpha: 0.28),
            size: 70,
          ),
        ),
        Positioned(
          left: 14,
          right: 14,
          bottom: 24,
          child: Text(
            book.title,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w900,
              height: 1.05,
            ),
          ),
        ),
      ],
    );
  }
}

class _OfferBackground extends StatelessWidget {
  const _OfferBackground();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _OfferBackgroundPainter(),
      child: const SizedBox.expand(),
    );
  }
}

class _OfferBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..color = const Color(0xFFFF2F64).withValues(alpha: 0.14);
    final centerX = size.width / 2;

    for (var i = 0; i < 7; i++) {
      final top = 36.0 + i * 56;
      final width = 120.0 + i * 86;
      final height = 90.0 + i * 64;
      final path = Path()
        ..moveTo(centerX, top)
        ..lineTo(centerX + width / 2, top + height / 2)
        ..lineTo(centerX, top + height)
        ..lineTo(centerX - width / 2, top + height / 2)
        ..close();
      canvas.drawPath(path, paint);
    }

    final glowPaint = Paint()
      ..shader =
          RadialGradient(
            colors: [
              const Color(0xFFB01132).withValues(alpha: 0.24),
              Colors.transparent,
            ],
          ).createShader(
            Rect.fromCircle(
              center: Offset(size.width * 0.5, size.height * 0.46),
              radius: size.width * 0.72,
            ),
          );
    canvas.drawRect(Offset.zero & size, glowPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _OfferBook {
  const _OfferBook({
    required this.title,
    required this.price,
    required this.oldPrice,
    required this.discount,
    required this.colors,
    this.imageUrl = '',
    this.isCombo = false,
  });

  final String title;
  final String price;
  final String oldPrice;
  final String discount;
  final List<Color> colors;
  final String imageUrl;
  final bool isCombo;
}

List<_OfferBook> _mapBooksToOffers(List<WakaScrapedBook> books) {
  final seen = <String>{};
  final mapped = <_OfferBook>[];
  for (final book in books) {
    if (book.imageUrl.isEmpty) continue;
    final key = book.url.isNotEmpty ? book.url : _normalize(book.title);
    if (!seen.add(key)) continue;

    final index = mapped.length;
    final isCombo = _looksLikeCombo(book.title, index);
    mapped.add(
      _OfferBook(
        title: _cleanTitle(book.title, isCombo: isCombo),
        price: _offerPrice(index, isCombo),
        oldPrice: _oldOfferPrice(index, isCombo),
        discount: '-${[25, 21, 20, 15, 9, 30][index % 6]}%',
        colors: _offerColors(book.title),
        imageUrl: book.imageUrl,
        isCombo: isCombo,
      ),
    );
  }

  final result = [...mapped];
  for (final fallback in _fallbackOfferBooks) {
    if (result.length >= 36) break;
    if (result.any(
      (book) => _normalize(book.title) == _normalize(fallback.title),
    )) {
      continue;
    }
    result.add(fallback);
  }
  return result;
}

bool _looksLikeCombo(String title, int index) {
  final normalized = _normalize(title);
  return normalized.contains('combo') || index % 7 == 0 || index % 11 == 0;
}

String _cleanTitle(String title, {required bool isCombo}) {
  final trimmed = title.replaceFirst(RegExp(r'^Sách\s*-\s*'), '').trim();
  if (!isCombo) return trimmed;
  if (_normalize(trimmed).contains('combo')) return trimmed;
  return 'Combo $trimmed';
}

String _offerPrice(int index, bool isCombo) {
  final prices = isCombo
      ? const ['99.000đ', '149.000đ', '249.000đ', '299.000đ']
      : const ['59.000đ', '79.000đ', '29.000đ', '99.000đ', '119.000đ'];
  return prices[index % prices.length];
}

String _oldOfferPrice(int index, bool isCombo) {
  final prices = isCombo
      ? const ['139.000đ', '199.000đ', '349.000đ', '399.000đ']
      : const ['79.000đ', '99.000đ', '59.000đ', '149.000đ', '169.000đ'];
  return prices[index % prices.length];
}

List<Color> _offerColors(String title) {
  final normalized = _normalize(title);
  if (normalized.contains('yeu') || normalized.contains('tinh')) {
    return const [Color(0xFF562048), Color(0xFFE45AA7)];
  }
  if (normalized.contains('tien') || normalized.contains('dau tu')) {
    return const [Color(0xFF13315C), Color(0xFFD7A321)];
  }
  if (normalized.contains('combo')) {
    return const [Color(0xFFB20E1E), Color(0xFFEA4638)];
  }
  return const [Color(0xFF193B48), Color(0xFF6BBE8B)];
}

String _normalize(String value) {
  return value
      .toLowerCase()
      .replaceAll(RegExp('[àáạảãâầấậẩẫăằắặẳẵ]'), 'a')
      .replaceAll(RegExp('[èéẹẻẽêềếệểễ]'), 'e')
      .replaceAll(RegExp('[ìíịỉĩ]'), 'i')
      .replaceAll(RegExp('[òóọỏõôồốộổỗơờớợởỡ]'), 'o')
      .replaceAll(RegExp('[ùúụủũưừứựửữ]'), 'u')
      .replaceAll(RegExp('[ỳýỵỷỹ]'), 'y')
      .replaceAll('đ', 'd');
}

bool _matches(String value, String query) {
  return _normalize(value).contains(_normalize(query));
}

const _fallbackOfferBooks = [
  _OfferBook(
    title: 'Hiểu về trái tim',
    price: '59.000đ',
    oldPrice: '79.000đ',
    discount: '-25%',
    colors: [Color(0xFF526D5F), Color(0xFFAAD844)],
  ),
  _OfferBook(
    title: 'Tâm sự về tình yêu',
    price: '79.000đ',
    oldPrice: '99.000đ',
    discount: '-20%',
    colors: [Color(0xFFF8D8EA), Color(0xFFFFFFFF)],
  ),
  _OfferBook(
    title: 'Con Là Tất Cả Của Mẹ',
    price: '29.000đ',
    oldPrice: '59.000đ',
    discount: '-30%',
    colors: [Color(0xFF0F2744), Color(0xFFF3B263)],
  ),
  _OfferBook(
    title: 'Đừng đọc nếu muốn mộng mơ',
    price: '99.000đ',
    oldPrice: '149.000đ',
    discount: '-21%',
    colors: [Color(0xFF26313A), Color(0xFFB9C1C8)],
  ),
  _OfferBook(
    title: 'Combo Thao túng tâm lý',
    price: '99.000đ',
    oldPrice: '139.000đ',
    discount: '-29%',
    colors: [Color(0xFFC50E19), Color(0xFF2B0508)],
    isCombo: true,
  ),
  _OfferBook(
    title: 'Combo 7 ebook luyện kỹ năng tư duy',
    price: '99.000đ',
    oldPrice: '179.000đ',
    discount: '-45%',
    colors: [Color(0xFFF7ECE6), Color(0xFFF6FFFF)],
    isCombo: true,
  ),
  _OfferBook(
    title: 'Bộ đôi sách Tiếng Anh',
    price: '249.000đ',
    oldPrice: '329.000đ',
    discount: '-24%',
    colors: [Color(0xFFEFFDFD), Color(0xFF83DACF)],
    isCombo: true,
  ),
];
