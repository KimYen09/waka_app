import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return  Container(
      color: WakaColors.homeBackground,
      child: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            const SliverToBoxAdapter(child: _HomeHeader()),
            const SliverToBoxAdapter(child: SizedBox(height: 20)),
            const SliverToBoxAdapter(child: _CategoryTabs()),
            const SliverToBoxAdapter(child: SizedBox(height: 20)),
            const SliverToBoxAdapter(child: _AdBannerCarousel()),
            const SliverToBoxAdapter(child: SizedBox(height: 28)),
            SliverToBoxAdapter(
              child: _SectionTitle(
                title: 'Sách mới mỗi ngày - Dành cho Hội viên!',
                onTap: () {},
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 14)),
            const SliverToBoxAdapter(child: _BookShelf()),
            const SliverToBoxAdapter(child: SizedBox(height: 22)),
          ],
        ),
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader();

  @override
  Widget build(BuildContext context) {
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
            child: const Row(
              children: [
                Icon(
                  Icons.workspace_premium_outlined,
                  color: WakaColors.gold,
                  size: 18,
                ),
                SizedBox(width: 5),
                Text(
                  'Gói cước',
                  style: TextStyle(
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
          const Icon(Icons.search_rounded, color: Colors.white, size: 32),
        ],
      ),
    );
  }
}

class _CategoryTabs extends StatelessWidget {
  const _CategoryTabs();

  static const tabs = [
    'Sách điện tử',
    'Sách Hội viên',
    'Sách Hiệu Sồi',
    'Truyện',
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 32,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) => Text(
          tabs[index],
          style: TextStyle(
            color: Colors.white.withValues(alpha: index == 0 ? 0.74 : 0.52),
            fontSize: 17.5,
            fontWeight: FontWeight.w700,
            height: 1.05,
          ),
        ),
        separatorBuilder: (_, _) => const SizedBox(width: 26),
        itemCount: tabs.length,
      ),
    );
  }
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
      child: const Padding(
        padding: EdgeInsets.all(18),
        child: Align(
          alignment: Alignment.bottomLeft,
          child: Text(
            'Ưu đãi\nHội viên',
            style: TextStyle(
              color: Color(0xFF913D2F),
              fontSize: 25,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
        ),
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF17110C),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF3A2A18)),
      ),
      child: const Align(
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
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.onTap});

  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
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
          IconButton(
            onPressed: onTap,
            icon: const Icon(
              Icons.chevron_right_rounded,
              color: Colors.white,
              size: 34,
            ),
          ),
        ],
      ),
    );
  }
}

class _BookShelf extends StatelessWidget {
  const _BookShelf();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 205,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) => _BookCover(index: index),
        separatorBuilder: (_, _) => const SizedBox(width: 9),
        itemCount: 5,
      ),
    );
  }
}

class _BookCover extends StatelessWidget {
  const _BookCover({required this.index});

  final int index;

  static const titles = [
    'NGHỆ THUẬT\nĐÀM PHÁN',
    'Tình yêu\nonline',
    'THÀNH TÍCH\nCAO',
    'BÍ MẬT\nCỦA SÁCH',
    'DÁM\nKHÁC BIỆT',
  ];

  static const palettes = [
    [Color(0xFFFFB22B), Color(0xFF0B2636)],
    [Color(0xFFEFF9DC), Color(0xFFF9BFD1)],
    [Color(0xFFFFB20E), Color(0xFFFF7C00)],
    [Color(0xFF6846A1), Color(0xFF232B64)],
    [Color(0xFFF7EEE3), Color(0xFFB7283E)],
  ];

  @override
  Widget build(BuildContext context) {
    final colors = palettes[index % palettes.length];

    return Container(
      width: 132,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(3),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: colors,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          if (index == 0)
            Positioned(
              left: -12,
              right: -12,
              top: 58,
              child: Transform.rotate(
                angle: -0.42,
                child: Container(height: 72, color: const Color(0xFF082539)),
              ),
            ),
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              color: const Color(0xFFE83BA7),
              child: const Text(
                '49.000đ',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Text(
                titles[index % titles.length],
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: index == 1 ? Colors.white : Colors.white,
                  fontSize: index == 1 ? 27 : 18.5,
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
