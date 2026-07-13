import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class OffersScreen extends StatelessWidget {
  const OffersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: WakaColors.homeBackground,
      child: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            const SliverToBoxAdapter(child: _OffersHeader()),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
            const SliverToBoxAdapter(child: _CategoryTabs()),
            const SliverToBoxAdapter(child: SizedBox(height: 20)),
            const SliverToBoxAdapter(child: _FlashSaleSection()),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
            const SliverToBoxAdapter(child: _MembershipSection()),
            const SliverToBoxAdapter(child: SizedBox(height: 30)),
            SliverToBoxAdapter(
              child: _SectionTitle(title: 'Sách hay giá tốt', onTap: () {}),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 14)),
            const SliverToBoxAdapter(child: _BookGridSection()),
            const SliverToBoxAdapter(child: SizedBox(height: 30)),
            SliverToBoxAdapter(
              child: _SectionTitle(title: 'Combo bán chạy', onTap: () {}),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 14)),
            const SliverToBoxAdapter(child: _ComboSection()),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }
}

// ----------------------------------------------------------------------
// Header: "Ưu đãi" + search
// ----------------------------------------------------------------------
class _OffersHeader extends StatelessWidget {
  const _OffersHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Row(
        children: [
          const Text(
            'Ưu đãi',
            style: TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w800,
            ),
          ),
          const Spacer(),
          const Icon(Icons.search_rounded, color: Colors.white, size: 30),
        ],
      ),
    );
  }
}

// ----------------------------------------------------------------------
// Tabs: Tất cả / Mua lẻ / Combo
// ----------------------------------------------------------------------
class _CategoryTabs extends StatefulWidget {
  const _CategoryTabs();

  @override
  State<_CategoryTabs> createState() => _CategoryTabsState();
}

class _CategoryTabsState extends State<_CategoryTabs> {
  int _selected = 0;
  static const _tabs = ['Tất cả', 'Mua lẻ', 'Combo'];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: _tabs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final isSelected = index == _selected;
          return GestureDetector(
            onTap: () => setState(() => _selected = index),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : WakaColors.surface,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  if (isSelected && index == 0) ...[
                    const Icon(Icons.bolt_rounded,
                        color: WakaColors.flashPink, size: 18),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    _tabs[index],
                    style: TextStyle(
                      color: isSelected ? Colors.black : Colors.white70,
                      fontSize: 15.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ----------------------------------------------------------------------
// Flash Sale: tiêu đề + countdown + carousel + giá + nút mua
// ----------------------------------------------------------------------
class _FlashSaleSection extends StatefulWidget {
  const _FlashSaleSection();

  @override
  State<_FlashSaleSection> createState() => _FlashSaleSectionState();
}

class _FlashSaleSectionState extends State<_FlashSaleSection> {
  static const _books = [
    _FlashBook(
      title: 'Vong Tang',
      subtitle: 'Ám ảnh tâm linh...',
      discountPercent: 51,
      color: Color(0xFF1A1A1A),
      oldPrice: '120.000đ',
      newPrice: '59.000đ',
      imageUrl: 'https://cdn.hstatic.net/products/200000294254/b_a_ti_ng_v_ng_t_ng_lam_1_311356bce78245efabadab78958f50ca_large.png',
    ),
    _FlashBook(
      title: 'Hiểu về trái tim',
      subtitle: 'Minh Niệm',
      discountPercent: 25,
      color: Color(0xFF6B6B60),
      oldPrice: '79.000đ',
      newPrice: '59.000đ',
      imageUrl: 'https://cdn1.fahasa.com/media/flashmagazine/images/page_images/hieu_ve_trai_tim_tai_ban_2023/2023_02_21_08_51_07_1-390x510.jpg',
    ),
    _FlashBook(
      title: 'Thấu Hiểu Trẻ Tự Kỷ',
      subtitle: 'TS Phạm Toàn',
      discountPercent: 0,
      oldPrice: '99.000đ',
      newPrice: '69.000đ',
      imageUrl: 'https://media.nxbtrithuc.com.vn/Picture/2022/7/14/image-20220714153711022.jpg',
      color: Color(0xFF16223A),
    ),
  ];

  late final PageController _controller;
  int _current = 1;
  Timer? _timer;
  Duration _remaining = const Duration(hours: 431, minutes: 38, seconds: 38);

  @override
  void initState() {
    super.initState();
    _controller = PageController(viewportFraction: 0.62, initialPage: 1);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_remaining.inSeconds <= 0) return;
      setState(() => _remaining -= const Duration(seconds: 1));
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  String _two(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final current = _books[_current];
    final width = MediaQuery.sizeOf(context).width;
    final cardWidth = width * 0.56;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: const [
              Text(
                'FLASH',
                style: TextStyle(
                  color: WakaColors.flashPink,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
              Icon(Icons.bolt_rounded, color: WakaColors.flashPink, size: 22),
              Text(
                'SALE',
                style: TextStyle(
                  color: WakaColors.flashPink,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: 'SALE CHỈ TỪ 19K   ',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      TextSpan(
                        text: 'Mở Kho Sá',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              _CountdownBox(text: _two(_remaining.inHours)),
              const _ColonDot(),
              _CountdownBox(text: _two(_remaining.inMinutes % 60)),
              const _ColonDot(),
              _CountdownBox(text: _two(_remaining.inSeconds % 60)),
            ],
          ),
        ),
        const SizedBox(height: 18),
        SizedBox(
          height: 340,
          child: PageView.builder(
            controller: _controller,
            itemCount: _books.length,
            onPageChanged: (i) => setState(() => _current = i),
            itemBuilder: (context, index) {
              final book = _books[index];
              return AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  double distance = 0;
                  if (_controller.hasClients &&
                      _controller.position.haveDimensions) {
                    distance = (_controller.page! - index).abs();
                  } else {
                    distance = (_current - index).abs().toDouble();
                  }
                  final scale = (1 - distance * 0.16).clamp(0.78, 1.0);
                  return Center(
                    child: Transform.scale(
                      scale: scale,
                      child: child,
                    ),
                  );
                },
                child: _FlashBookCover(book: book, width: cardWidth),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        if (current.newPrice != null) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                current.oldPrice ?? '',
                style: const TextStyle(
                  color: Colors.white38,
                  fontSize: 16,
                  decoration: TextDecoration.lineThrough,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                current.newPrice!,
                style: const TextStyle(
                  color: Color(0xFFFF4757),
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
        ],
        Text(
          current.title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 19,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () {},
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
            decoration: BoxDecoration(
              color: WakaColors.accent,
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Text(
              'MUA NGAY',
              style: TextStyle(
                color: Colors.black,
                fontSize: 15.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ColonDot extends StatelessWidget {
  const _ColonDot();
  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 2),
      child: Text(
        ':',
        style: TextStyle(
          color: Colors.white,
          fontSize: 17,
          fontWeight: FontWeight.w800,
        ),
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
      width: 30,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white24),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _FlashBook {
  const _FlashBook({
    required this.title,
    required this.subtitle,
    required this.discountPercent,
    required this.color,
    required this.imageUrl,
    this.oldPrice,
    this.newPrice,
  });

  final String title;
  final String imageUrl;
  final String subtitle;
  final int discountPercent;
  final Color color;
  final String? oldPrice;
  final String? newPrice;
}

class _FlashBookCover extends StatelessWidget {
  const _FlashBookCover({required this.book, required this.width});
  final _FlashBook book;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: book.color,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 🌟 LOAD ẢNH BÌA TỪ URL Ở ĐÂY
          Image.network(
            book.imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Center(
              child: Text(
                book.title,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),

          // Nút % giảm giá góc trên
          if (book.discountPercent > 0)
            Positioned(
              right: 8,
              top: 8,
              child: Container(
                width: 46,
                height: 46,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFC107),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '-${book.discountPercent}%',
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ----------------------------------------------------------------------
// Phù hợp với bạn: gói hội viên
// ----------------------------------------------------------------------
class _MembershipSection extends StatelessWidget {
  const _MembershipSection();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Phù hợp với bạn',
            style: TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Mở khóa hơn 20.000 nội dung Ebook, Sách nói, Truyện tranh... với gói Hội viên Waka',
            style: TextStyle(color: WakaColors.mutedText, fontSize: 14.5),
          ),
          const SizedBox(height: 18),
          const _MembershipCard(
            title: 'WAKA 6 THÁNG',
            subtitle: '183 ngày đọc/nghe sách',
            price: '399.000Đ',
            oldPrice: '414.000Đ',
            badgeText: 'TIẾT KIỆM 10%',
            highlighted: false,
          ),
          const SizedBox(height: 16),
          const _MembershipCard(
            title: 'WAKA 12 THÁNG',
            subtitle: '365 ngày đọc/nghe sách',
            price: '499.000Đ',
            oldPrice: '828.000Đ',
            badgeText: 'Tặng thêm 02 tháng',
            highlighted: true,
          ),
        ],
      ),
    );
  }
}

class _MembershipCard extends StatelessWidget {
  const _MembershipCard({
    required this.title,
    required this.subtitle,
    required this.price,
    required this.oldPrice,
    required this.badgeText,
    required this.highlighted,
  });

  final String title;
  final String subtitle;
  final String price;
  final String oldPrice;
  final String badgeText;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      decoration: BoxDecoration(
        color: WakaColors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: WakaColors.accent,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: WakaColors.mutedText,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      price,
                      style: const TextStyle(
                        color: Color(0xFFE8FF66),
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      oldPrice,
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 14,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (highlighted)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFFF8A00), Color(0xFFE0333F)],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(14),
                  bottomRight: Radius.circular(14),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.card_giftcard_rounded,
                      color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    badgeText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );

    return Stack(
      clipBehavior: Clip.none,
      children: [
        if (highlighted)
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFFF8A00), width: 1.4),
            ),
            child: content,
          )
        else
          content,
        if (!highlighted)
          Positioned(
            right: 0,
            top: -12,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF8A00), Color(0xFFE0333F)],
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                badgeText,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ----------------------------------------------------------------------
// Section title dùng chung ("Sách hay giá tốt", "Combo bán chạy")
// ----------------------------------------------------------------------
class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.onTap});
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: onTap,
        child: Row(
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const Spacer(),
            const Icon(Icons.chevron_right_rounded,
                color: Colors.white54, size: 26),
          ],
        ),
      ),
    );
  }
}

// ----------------------------------------------------------------------
// Sách hay giá tốt (Hiển thị ảnh thật từ URL Waka + Kéo ngang)
// ----------------------------------------------------------------------
class _BookGridSection extends StatelessWidget {
  const _BookGridSection();

  static const _books = [
    (
      price: '99.000đ',
      title: 'Thoát nợ sống nhẹ',
      imageUrl:
          'https://307a0e78.vws.vegacdn.vn/view/v2/image/img.book/0/0/1/55930.jpg?v=1&w=350&h=510',
    ),
    (
      price: '79.000đ',
      title: 'Chỉ yêu trúc mã',
      imageUrl:
          'https://307a0e78.vws.vegacdn.vn/view/v2/image/img.book/0/0/1/55909.jpg?v=1&w=350&h=510',
    ),
    (
      price: '129.000đ',
      title: 'Dám kiếm tiền, dám đầu tư',
      imageUrl:
          'https://307a0e78.vws.vegacdn.vn/view/v2/image/img.book/0/0/1/55897.jpg?v=1&w=350&h=510',
    ),
    (
      price: '89.000đ',
      title: 'Xuyên không giả làm bạn gái tổng tài',
      imageUrl:
          'https://307a0e78.vws.vegacdn.vn/view/v2/image/img.book/0/0/1/55882.jpg?v=1&w=350&h=510',
    ),
    (
      price: '119.000đ',
      title: 'Kiếp trước là yêu, kiếp này là buông',
      imageUrl:
          'https://307a0e78.vws.vegacdn.vn/view/v2/image/img.book/0/0/1/55909.jpg?v=1&w=350&h=510',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 250,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: _books.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final book = _books[index];
          return SizedBox(
            width: 130,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.network(
                        book.imageUrl,
                        width: 130,
                        height: 180,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 130,
                          height: 180,
                          color: WakaColors.surface,
                          child: const Icon(Icons.book, color: Colors.white38),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 0,
                      top: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: const BoxDecoration(
                          color: WakaColors.flashPink,
                          borderRadius: BorderRadius.only(
                            topRight: Radius.circular(4),
                            bottomRight: Radius.circular(4),
                          ),
                        ),
                        child: Text(
                          book.price,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  book.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 13.5),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ----------------------------------------------------------------------
// Combo bán chạy (Hiển thị ảnh thật từ URL Waka + Kéo ngang)
// ----------------------------------------------------------------------
class _ComboSection extends StatelessWidget {
  const _ComboSection();

  static const _combos = [
    (
      price: '99.000đ',
      title: 'Combo Thao túng tâm lý',
      imageUrl:
          'https://cdn1.fahasa.com/media/catalog/product/8/9/8936066692298-1.jpg',
    ),
    (
      price: '149.000đ',
      title: 'Combo 7 ebook luyện kỹ năng tư duy',
      imageUrl:
          'https://mcbooks.vn/wp-content/uploads/2025/07/Bia-truoc-cuon-Ren-Luyen-Ky-Nang-Tu-Duy-Logic-1-Phut.png',
    ),
    (
      price: '199.000đ',
      title: 'Bộ đôi sách bán chạy nhất',
      imageUrl:
          'https://307a0e78.vws.vegacdn.vn/view/v2/image/img.book/0/0/1/55882.jpg?v=1&w=350&h=510',
    ),
    (
      price: '129.000đ',
      title: 'Combo Sách Kỹ Năng Sống',
      imageUrl:
          'https://www.nxbtre.com.vn/Images/Book/nxbtre_full_12252023_032502.jpg',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 240,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: _combos.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final combo = _combos[index];
          return SizedBox(
            width: 150,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.network(
                        combo.imageUrl,
                        width: 150,
                        height: 170,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 150,
                          height: 170,
                          color: WakaColors.surface,
                          child: const Icon(
                            Icons.collections_bookmark_rounded,
                            color: Colors.white38,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 0,
                      top: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: const BoxDecoration(
                          color: WakaColors.flashPink,
                          borderRadius: BorderRadius.only(
                            topRight: Radius.circular(4),
                            bottomRight: Radius.circular(4),
                          ),
                        ),
                        child: Text(
                          combo.price,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  combo.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 13.5),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}