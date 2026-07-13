import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Màn "Thư viện" - phần header (avatar + tabs) đứng yên (pinned) khi cuộn,
/// phần bên dưới (chip danh mục, banner, lưới sách) cuộn trôi qua.
class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  int _selectedTab = 0;
  bool _showBanner = true;

  // 🌟 ĐÃ SETUP SẴN VỊ TRÍ 'imageUrl' ĐỂ HƯNG BỎ LINK ẢNH VÀO
  static const _books = [
    _LibraryBook(
      title: 'Cách biến khả năng của bạn thành tiền',
      author: 'Earl Prevette, A.B., LL.B',
      color: Color(0xFF1B4B8F),
      mediaType: _MediaType.audio,
      imageUrl: 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSeXzdu05LBq9hZc5bS56Yt79QG6Svtc0GTr9J9xvOGNg&s=10',
    ),
    _LibraryBook(
      title: 'Hướng dẫn sử dụng mạng xã hội an toàn',
      author: 'Bộ Thông tin và Truyền thông',
      color: Color(0xFF2A6FB0),
      mediaType: _MediaType.audio,
      imageUrl: 'https://www.vwu.vn/documents/20182/6109697/11_Dec_2023_071620_GMTAnnotation_2023-12-11_135545.jpg/166bcd82-df2d-4c3c-a371-02409b2a0014',
    ),
    _LibraryBook(
      title: '[Tóm tắt sách] Phụ nữ thông minh phải biết tiêu tiền',
      author: 'Lois P. Frankel',
      color: Color(0xFFF3D7E8),
      mediaType: _MediaType.audio,
      imageUrl: 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcShL9BmxKeCXJT1NiG-gQ5Nm9zfY_68ySMFhikkYq1DA4LvjqWeK6zJ7g&s=10',
    ),
    _LibraryBook(
      title: '[Tóm tắt sách] Họ hỏi bạn trả lời',
      author: 'Marcus Sheridan',
      color: Color(0xFFF6C85F),
      mediaType: _MediaType.audio,
      imageUrl: 'https://cdn1.fahasa.com/media/catalog/product/i/m/image_244718_1_3285.jpg',
    ),
    _LibraryBook(
      title: '[Tóm tắt sách] - Công thức hỏi',
      author: 'Ryan Levesque',
      color: Color(0xFFF6B93B),
      mediaType: _MediaType.audio,
      imageUrl: 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQgszzzQLYDW1_9G5qf1hfftkkT4S8voAdEli_iq7DHOfXtCcJR3kC_9H4&s=10',
    ),
    _LibraryBook(
      title: 'Xây dựng thương hiệu từ A đến Z',
      author: 'Fabian Geyrhalter',
      color: Color(0xFF2E9E6B),
      mediaType: _MediaType.audio,
      imageUrl: 'https://307a0e78.vws.vegacdn.vn/view/v2/image/img.book/0/0/1/55897.jpg?v=1&w=350&h=510',
    ),
    _LibraryBook(
      title: '[Tóm tắt sách] Nghệ thuật thất truyền về kết nối',
      author: 'Susan McPherson',
      color: Color(0xFF2C3E50),
      mediaType: _MediaType.audio,
      imageUrl: 'https://dilib.vn/img/news/2022/11/larger/10082-hom-nay-toi-that-tinh-1.webp',
    ),
    _LibraryBook(
      title: 'Bí mật bán mọi thứ',
      author: 'Harry Browne',
      color: Color(0xFF34495E),
      mediaType: _MediaType.audio,
      imageUrl: 'https://dtv-ebook.com.vn/images/files_2/2025/062025/bi-mat-ban-moi-thu-harry-browne.jpg',
    ),
    _LibraryBook(
      title: 'Bạn không thiếu thời gian, bạn thiếu cách dùng nó',
      author: 'Hoàng Anh Thư',
      color: Color(0xFFC0392B),
      mediaType: _MediaType.ebook,
      imageUrl: 'https://307a0e78.vws.vegacdn.vn/view/v2/image/img.book/0/0/1/55909.jpg?v=1&w=350&h=510',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: WakaColors.background,
      child: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverPersistentHeader(
              pinned: true,
              delegate: _LibraryHeaderDelegate(
                selectedTab: _selectedTab,
                onTabChanged: (i) => setState(() => _selectedTab = i),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
            const SliverToBoxAdapter(child: _CategoryChips()),
            if (_showBanner) ...[
              const SliverToBoxAdapter(child: SizedBox(height: 20)),
              SliverToBoxAdapter(
                child: _AdBanner(onClose: () {
                  setState(() => _showBanner = false);
                }),
              ),
            ],
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Sách truyện',
                  style: TextStyle(
                    color: WakaColors.text,
                    fontSize: 24,
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
                  crossAxisCount: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 20,
                  childAspectRatio: 0.56,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _LibraryBookCard(book: _books[index]),
                  childCount: _books.length,
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }
}

// ----------------------------------------------------------------------
// Header pinned: avatar + sđt + icons, và hàng tab bên dưới
// ----------------------------------------------------------------------
class _LibraryHeaderDelegate extends SliverPersistentHeaderDelegate {
  _LibraryHeaderDelegate({
    required this.selectedTab,
    required this.onTabChanged,
  });

  final int selectedTab;
  final ValueChanged<int> onTabChanged;

  static const _tabs = ['Tiếp tục', 'Đã mua', 'Yêu thích', 'Tải xuống'];
  static const double _height = 150;

  @override
  double get minExtent => _height;

  @override
  double get maxExtent => _height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
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
                child: const Icon(Icons.person,
                    color: Color(0xCCFFFFFF), size: 30),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '0932707674',
                      style: TextStyle(
                        color: WakaColors.text,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Xem hồ sơ',
                      style: TextStyle(
                        color: WakaColors.mutedText,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.notifications_none_rounded,
                  color: WakaColors.text, size: 26),
              const SizedBox(width: 18),
              const Icon(Icons.headset_mic_outlined,
                  color: WakaColors.text, size: 26),
              const SizedBox(width: 18),
              const Icon(Icons.edit_outlined,
                  color: WakaColors.text, size: 24),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 32,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _tabs.length,
              separatorBuilder: (_, __) => const SizedBox(width: 26),
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
                      fontWeight:
                          isSelected ? FontWeight.w800 : FontWeight.w500,
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
    return oldDelegate.selectedTab != selectedTab;
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
  int _selected = 0;
  static const _items = ['Sách điện tử', 'Sách nói', 'Truyện tranh', 'Sách hiệu Sồi'];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: _items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final isSelected = index == _selected;
          return GestureDetector(
            onTap: () => setState(() => _selected = index),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? WakaColors.elevatedSoft : WakaColors.surface,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Text(
                _items[index],
                style: TextStyle(
                  color: isSelected ? WakaColors.text : WakaColors.mutedText,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        },
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
                            horizontal: 12, vertical: 6),
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: const [
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
// Book card trong lưới "Sách truyện" (Đã tích hợp Image.network)
// ----------------------------------------------------------------------
enum _MediaType { audio, ebook }

class _LibraryBook {
  const _LibraryBook({
    required this.title,
    required this.author,
    required this.color,
    required this.mediaType,
    this.imageUrl, // 👈 ĐÃ BỔ SUNG KHAI BÁO imageUrl
  });

  final String title;
  final String author;
  final Color color;
  final _MediaType mediaType;
  final String? imageUrl; // 👈 URL ảnh bìa
}

class _LibraryBookCard extends StatelessWidget {
  const _LibraryBookCard({required this.book});
  final _LibraryBook book;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // 🌟 HIỂN THỊ ẢNH BÌA NẾU CÓ imageUrl
                if (book.imageUrl != null && book.imageUrl!.isNotEmpty)
                  Image.network(
                    book.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(color: book.color),
                  )
                else
                  Container(color: book.color),

                // 🌟 ICON PLAY / ĐỌC SÁCH ĐÈ CHÍNH GIỮA ẢNH
                Center(
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      book.mediaType == _MediaType.audio
                          ? Icons.play_arrow_rounded
                          : Icons.menu_book_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
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
      ],
    );
  }
}