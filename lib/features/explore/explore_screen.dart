import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../shared/widgets/waka_search_sheet.dart';
import 'book_news_screen.dart';
import 'creative_community_screen.dart';
import 'digital_library_screen.dart';
import 'vinh_nghiem_buddhist_screen.dart';
import 'youth_books_screen.dart';

/// Màn "Khám phá" - tab Cộng đồng (lưới 2x2 thẻ màu) + tab Thông tin (feed
/// bài đăng của Waka.vn, có ảnh/text/thời gian) + tab Tin tức (chuyển sang màn hình Tin tức Sách).
class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  int _selectedTab = 0;
  static const _tabs = ['Cộng đồng', 'Thông tin', 'Tin tức'];
  final ScrollController _scrollController = ScrollController();

  static const _communityCards = [
    _CommunityCard(
      title: 'TỦ SÁCH\nTHANH NIÊN',
      color: Color(0xFFD32F2F),
      icon: Icons.auto_awesome_rounded,
      type: _CommunityCardType.youth,
    ),
    _CommunityCard(
      title: 'CỘNG ĐỒNG\nSÁNG TÁC',
      color: Color(0xFF4C8C3B),
      icon: Icons.edit_rounded,
      type: _CommunityCardType.community,
    ),
    _CommunityCard(
      title: 'THƯ VIỆN\nSỐ 4.0',
      color: Color(0xFF1E88C7),
      icon: Icons.school_rounded,
      type: _CommunityCardType.digitalLibrary,
    ),
    _CommunityCard(
      title: 'SÁCH PHẬT\nVĨNH NGHIÊM',
      color: Color(0xFFD4A017),
      icon: Icons.spa_rounded,
      type: _CommunityCardType.buddhism,
    ),
  ];

  static const _posts = [
    _Post(
      author: 'Waka.vn',
      timeAgo: '3 giờ trước',
      content:
          'PHẬN LÀ IDOL NHƯNG CHỈ ĐAM MÊ MÁY MÓC VỚI LUYỆN CƠ TAY ?\n\nSống qua ngày chỉ nghĩ cách bào tiền của ông chủ để mua linh kiện.',
      hasImage: true,
      imageUrl: 'https://images.unsplash.com/photo-1544716278-ca5e3f4abd8c?w=600',
    ),
    _Post(
      author: 'Waka.vn',
      timeAgo: '15 giờ trước',
      content:
          '"Tiền bạc vô tình trở thành ranh giới nghiệt ngã phân định giữa một cuộc sống bình yên và một cuộc sống héo mòn.\n\nNhìn vào thực tế ngoài kia mà xem, ranh giới đó rõ...',
      hasImage: true,
      imageUrl: 'https://images.unsplash.com/photo-1512820790803-83ca734da794?w=600',
    ),
    _Post(
      author: 'Waka.vn',
      timeAgo: '1 ngày trước',
      content:
          'Top 5 cuốn sách giúp bạn quản lý thời gian hiệu quả hơn trong năm nay. Cuốn số 3 sẽ khiến bạn phải suy nghĩ lại về cách mình đang làm việc mỗi ngày...',
      hasImage: true,
      imageUrl: 'https://307a0e78.vws.vegacdn.vn/view/v2/image/img.book/0/0/1/55930.jpg?v=1&w=350&h=510',
    ),
    _Post(
      author: 'Waka.vn',
      timeAgo: '2 ngày trước',
      content:
          'Cộng đồng Sáng Tác Waka vừa mở cuộc thi viết truyện ngắn chủ đề "Thanh xuân". Giải thưởng lên đến 10 triệu đồng, hạn nộp bài đến hết tháng này!',
      hasImage: false,
    ),
  ];

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    if (index == 2) {
      // Tab Tin tức: Mở màn hình Tin Tức Sách
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const BookNewsScreen()),
      );
      return;
    }

    setState(() => _selectedTab = index);

    if (index == 1) {
      // Tab Thông tin: Lướt cuộn mượt xuống khu vực "Thông tin" nằm bên dưới
      _scrollController.animateTo(
        290.0,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    } else if (index == 0) {
      // Tab Cộng đồng: Lướt lên trên cùng
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  void _openCardDestination(_CommunityCardType type) {
    switch (type) {
      case _CommunityCardType.youth:
        // Mở Tủ Sách Thanh Niên (Màn hình màu đỏ lịch sử & cách mạng)
        Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const YouthBooksScreen()),
        );
        break;
      case _CommunityCardType.community:
        // Mở Cộng Đồng Sáng Tác (Giao diện xanh lá cây với Tác giả HOT, Thể loại, Truyện HOT & Waka đề cử)
        Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const CreativeCommunityScreen()),
        );
        break;
      case _CommunityCardType.digitalLibrary:
        // Mở Thư Viện Số 4.0
        Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const DigitalLibraryScreen()),
        );
        break;
      case _CommunityCardType.buddhism:
        // Mở Sách Phật Vĩnh Nghiêm (Giao diện 4 tab Phật giáo chính chủ)
        Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const VinhNghiemBuddhistScreen()),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: WakaColors.background,
      child: SafeArea(
        bottom: false,
        child: CustomScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          slivers: [
            const SliverToBoxAdapter(child: SizedBox(height: 8)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    const Text(
                      'Khám phá',
                      style: TextStyle(
                        color: WakaColors.text,
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(
                        Icons.search_rounded,
                        color: WakaColors.text,
                        size: 30,
                      ),
                      onPressed: () => showWakaSearchSheet(context),
                    ),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 18)),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 40,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: _tabs.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final isSelected = index == _selectedTab;
                    return GestureDetector(
                      onTap: () => _onTabTapped(index),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.white : WakaColors.surface,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Text(
                          _tabs[index],
                          style: TextStyle(
                            color: isSelected ? Colors.black : WakaColors.mutedText,
                            fontSize: 15.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 28)),
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Cộng đồng trên Waka',
                  style: TextStyle(
                    color: WakaColors.text,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 14)),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.68,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) => GestureDetector(
                    onTap: () => _openCardDestination(_communityCards[index].type),
                    child: _CommunityCardWidget(card: _communityCards[index]),
                  ),
                  childCount: _communityCards.length,
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 34)),
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Thông tin',
                  style: TextStyle(
                    color: WakaColors.text,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 14)),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _PostCard(post: _posts[index]),
                ),
                childCount: _posts.length,
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }
}

enum _CommunityCardType { youth, community, digitalLibrary, buddhism }

class _CommunityCard {
  const _CommunityCard({
    required this.title,
    required this.color,
    required this.icon,
    required this.type,
  });

  final String title;
  final Color color;
  final IconData icon;
  final _CommunityCardType type;
}

class _CommunityCardWidget extends StatelessWidget {
  const _CommunityCardWidget({required this.card});
  final _CommunityCard card;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: card.color,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: card.color.withValues(alpha: 0.35),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Stack(
        children: [
          Text(
            card.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w800,
              height: 1.15,
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              child: Icon(card.icon, color: Colors.white, size: 22),
            ),
          ),
        ],
      ),
    );
  }
}

class _Post {
  const _Post({
    required this.author,
    required this.timeAgo,
    required this.content,
    required this.hasImage,
    this.imageUrl,
  });

  final String author;
  final String timeAgo;
  final String content;
  final bool hasImage;
  final String? imageUrl;
}

class _PostCard extends StatelessWidget {
  const _PostCard({required this.post});
  final _Post post;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: WakaColors.surface,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(
                  color: Color(0xFFF5A623),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text(
                    'W',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Text(
                          'Waka.vn',
                          style: TextStyle(
                            color: WakaColors.text,
                            fontSize: 15.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(
                          Icons.verified_rounded,
                          color: WakaColors.accent,
                          size: 16,
                        ),
                      ],
                    ),
                    Text(
                      post.timeAgo,
                      style: const TextStyle(
                        color: WakaColors.mutedText,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          RichText(
            text: TextSpan(
              style: const TextStyle(
                color: WakaColors.text,
                fontSize: 15,
                height: 1.35,
              ),
              children: [
                TextSpan(text: post.content),
                const TextSpan(
                  text: '  Xem',
                  style: TextStyle(
                    color: WakaColors.accent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          if (post.hasImage && post.imageUrl != null) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                post.imageUrl!,
                height: 190,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  height: 190,
                  width: double.infinity,
                  color: WakaColors.surface,
                  child: const Center(
                    child: Icon(
                      Icons.image_not_supported_rounded,
                      color: Colors.white24,
                      size: 40,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
