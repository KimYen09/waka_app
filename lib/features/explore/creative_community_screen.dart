import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../shared/widgets/waka_search_sheet.dart';
import '../profile/author_registration_screen.dart';
import '../reader/book_detail_screen.dart';

class CreativeCommunityScreen extends StatefulWidget {
  const CreativeCommunityScreen({super.key});

  @override
  State<CreativeCommunityScreen> createState() => _CreativeCommunityScreenState();
}

class _CreativeCommunityScreenState extends State<CreativeCommunityScreen>
    with SingleTickerProviderStateMixin {
  late TabController _mainTabController;
  int _selectedCategoryChip = 0;
  final Set<String> _followedAuthors = {};

  static const _categoryChips = [
    'Tất cả',
    'Tác phẩm kinh điển',
    'Kinh tế',
    'Chính trị',
    'Giáo dục - Văn hóa & Xã hội',
    'Phát triển cá nhân',
  ];

  static const _eBookProducts = [
    _CommunityBook(
      id: 501,
      title: 'Giữa chốn phồn hoa gặp được người - Tập 2',
      author: 'Cửu Nguyệt Hi',
      imageUrl: 'https://307a0e78.vws.vegacdn.vn/view/v2/image/img.book/0/0/1/33467.jpg?v=1&w=480&h=700',
      badge: 'HỘI VIÊN',
    ),
    _CommunityBook(
      id: 502,
      title: 'Làm đĩ',
      author: 'Vũ Trọng Phụng',
      imageUrl: 'https://down-vn.img.susercontent.com/file/c98e25971a7301c8248a2506f33d293b',
    ),
    _CommunityBook(
      id: 503,
      title: 'Bên nhau trọn đời',
      author: 'Cố Mạn',
      imageUrl: 'https://307a0e78.vws.vegacdn.vn/view/v2/image/img.book/0/0/0/16736.jpg?v=1&w=480&h=700',
    ),
    _CommunityBook(
      id: 504,
      title: 'CM-12 Phía sau kế hoạch phản gián',
      author: 'Nguyễn Khắc Đức',
      imageUrl: 'https://cdn1.fahasa.com/media/catalog/product/z/7/z7559362432815_58b7db0644c7ffc7e9378ada6274a2f4_2_1.jpg',
    ),
    _CommunityBook(
      id: 505,
      title: '[Tóm tắt sách] 1000 câu hỏi về tình dục dành cho các cặp đôi',
      author: 'Trần Nhật Dương',
      imageUrl: 'https://307a0e78.vws.vegacdn.vn/view/v2/image/img.book/0/0/1/47101.jpg?v=7&w=480&h=700',
    ),
    _CommunityBook(
      id: 506,
      title: 'Bộ Khoa học và Công nghệ kế thừa lịch sử, hướng tới tương lai',
      author: 'Bộ Khoa học và Công nghệ',
      imageUrl: 'https://vista.gov.vn/vn-uploads/science-technology/2024_08/bia-sach-trang-2023.png',
    ),
    _CommunityBook(
      id: 507,
      title: 'Di chúc của Chủ tịch Hồ Chí Minh',
      author: 'Hồ Chí Minh',
      imageUrl: 'https://www.nxbtre.com.vn/Images/Read/nxbtre_di-chuc-cua-chu-tich-ho-chi-minh-19-5-1890-02-9-1969.pdf_page-1.png',
    ),
    _CommunityBook(
      id: 508,
      title: 'Tôi đi học',
      author: 'Nguyễn Ngọc Ký',
      imageUrl: 'https://firstnews.vn/upload/products/original/-1729482421.jpg',
    ),
    _CommunityBook(
      id: 509,
      title: 'Tóm lược Chuyển đổi số - Chiến lược & Lộ trình',
      author: 'David L. Rogers',
      imageUrl: 'https://images.unsplash.com/photo-1528127269322-539801943592?w=500',
    ),
    _CommunityBook(
      id: 510,
      title: 'Khi ta thay đổi thế giới sẽ đổi thay',
      author: 'Karen Casey',
      imageUrl: 'https://images.unsplash.com/photo-1461360370896-922624d12aa1?w=500',
    ),
    _CommunityBook(
      id: 511,
      title: 'Cách nghĩ để thành công',
      author: 'Napoleon Hill',
      imageUrl: 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=500',
    ),
    _CommunityBook(
      id: 512,
      title: 'Bắt sóng cảm xúc',
      author: 'Bí mật lực hấp dẫn',
      imageUrl: 'https://images.unsplash.com/photo-1522071820081-009f0129c71c?w=500',
    ),
  ];

  static const _audioBooks = [
    _CommunityBook(
      id: 601,
      title: 'Tóm lược Chuyển đổi số - Chiến lược & Lộ trình',
      author: 'David L. Rogers',
      imageUrl: 'https://images.unsplash.com/photo-1528127269322-539801943592?w=500',
      isAudio: true,
    ),
    _CommunityBook(
      id: 602,
      title: 'Giải mã 12 cung hoàng đạo 2024',
      author: 'Ban biên tập Waka',
      imageUrl: 'https://images.unsplash.com/photo-1509198397868-475647b2a1e5?w=500',
      isAudio: true,
    ),
    _CommunityBook(
      id: 603,
      title: 'AI lắng nghe tôi trải lòng',
      author: 'Cuộc đối thoại cảm xúc',
      imageUrl: 'https://images.unsplash.com/photo-1451187580459-43490279c0fa?w=500',
      isAudio: true,
    ),
    _CommunityBook(
      id: 604,
      title: 'Tuyển tập Lịch sử Việt - Góc khuất chưa từng kể',
      author: 'Góc khuất lịch sử',
      imageUrl: 'https://images.unsplash.com/photo-1461360370896-922624d12aa1?w=500',
      isAudio: true,
    ),
  ];

  static const _hotAuthors = [
    _Author('Sơ Hạ', '954 người theo dõi', 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=300'),
    _Author('Tử Dạ', '893 người theo dõi', 'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=300'),
    _Author('MIN LAZY', '607 người theo dõi', 'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=300'),
    _Author('Sơn Mạt Vi Vân', '1,240 người theo dõi', 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=300'),
  ];

  static const _truyenDaiGenres = [
    _GenreCardItem('TÌNH CẢM LÃNG MẠN', 'https://images.unsplash.com/photo-1518621736915-f3b1c41bfd00?w=500', [Color(0xFF5A1846), Color(0xFFC70039)]),
    _GenreCardItem('TRINH THÁM KINH DỊ', 'https://images.unsplash.com/photo-1509198397868-475647b2a1e5?w=500', [Color(0xFF1C1C24), Color(0xFF3F2B96)]),
    _GenreCardItem('KHOA HỌC VIỄN TƯỞNG', 'https://images.unsplash.com/photo-1451187580459-43490279c0fa?w=500', [Color(0xFF0F2027), Color(0xFF2C5364)]),
    _GenreCardItem('DUYÊN GÁI', 'https://images.unsplash.com/photo-1516589178581-6cd7833ae3b2?w=500', [Color(0xFF4A0E4E), Color(0xFF810554)]),
    _GenreCardItem('THUẦN VIỆT', 'https://images.unsplash.com/photo-1528127269322-539801943592?w=500', [Color(0xFF1D4350), Color(0xFFA9C25D)]),
    _GenreCardItem('CẢM HỨNG LỊCH SỬ', 'https://images.unsplash.com/photo-1461360370896-922624d12aa1?w=500', [Color(0xFF3A6073), Color(0xFF3A7BD5)]),
  ];

  @override
  void initState() {
    super.initState();
    _mainTabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _mainTabController.dispose();
    super.dispose();
  }

  void _toggleFollow(String authorName) {
    setState(() {
      if (_followedAuthors.contains(authorName)) {
        _followedAuthors.remove(authorName);
      } else {
        _followedAuthors.add(authorName);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WakaColors.background,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            backgroundColor: const Color(0xFF00BFA5),
            elevation: 0,
            pinned: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: const Text(
              'Cộng đồng sáng tác & Thư viện',
              style: TextStyle(
                color: Colors.white,
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.search_rounded, color: Colors.white, size: 26),
                onPressed: () => showWakaSearchSheet(context),
              ),
              IconButton(
                icon: const Icon(Icons.tune_rounded, color: Colors.white, size: 24),
                onPressed: () => showWakaSearchSheet(context),
              ),
            ],
            bottom: TabBar(
              controller: _mainTabController,
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5),
              tabs: const [
                Tab(text: 'Cộng đồng'),
                Tab(text: 'EBook (Sách)'),
              ],
            ),
          ),
        ],
        body: TabBarView(
          controller: _mainTabController,
          children: [
            _buildCreativeCommunityTab(),
            _buildEBookTab(),
            _buildAudioBookTab(),
          ],
        ),
      ),
    );
  }

  // TAB 1: CỘNG ĐỒNG SÁNG TÁC
  Widget _buildCreativeCommunityTab() {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        // 4 Nút tròn nhanh
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildCategoryCircleButton('Tất cả truyện', const Color(0xFF4C8C3B), Icons.grid_view_rounded),
            _buildCategoryCircleButton('Truyện dài', const Color(0xFF1E88C7), Icons.menu_book_rounded),
            _buildCategoryCircleButton('Truyện ngắn', const Color(0xFF8E24AA), Icons.eco_rounded),
            _buildCategoryCircleButton('Bảng xếp hạng', const Color(0xFFFB8C00), Icons.equalizer_rounded),
          ],
        ),
        const SizedBox(height: 24),

        // SECTION 1: TÁC GIẢ HOT
        const Text(
          'Tác giả HOT',
          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 175,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _hotAuthors.length,
            separatorBuilder: (_, _) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final author = _hotAuthors[index];
              final isFollowed = _followedAuthors.contains(author.name);
              return Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundImage: NetworkImage(author.avatarUrl),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    author.name,
                    style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  Text(
                    author.followers,
                    style: const TextStyle(color: WakaColors.mutedText, fontSize: 11),
                  ),
                  const SizedBox(height: 6),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isFollowed ? Colors.white : const Color(0xFF4C8C3B),
                      backgroundColor: isFollowed ? const Color(0xFF4C8C3B) : Colors.transparent,
                      side: const BorderSide(color: Color(0xFF4C8C3B)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () => _toggleFollow(author.name),
                    child: Text(
                      isFollowed ? 'ĐÃ THEO DÕI' : 'THEO DÕI',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 20),

        // Banner TRỞ THÀNH TÁC GIẢ TẠI CỘNG ĐỒNG VIẾT WAKA
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2E7D32), Color(0xFF66BB6A)],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'TRỞ THÀNH TÁC GIẢ',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
                    ),
                    const Text(
                      'TẠI CỘNG ĐỒNG VIẾT WAKA',
                      style: TextStyle(color: Color(0xFFD7D7D7), fontSize: 14, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFD54F),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const AuthorRegistrationScreen(),
                          ),
                        );
                      },
                      child: const Text('QUYỀN LỢI TÁC GIẢ', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.edit_note_rounded, color: Colors.white, size: 54),
            ],
          ),
        ),
        const SizedBox(height: 28),

        // SECTION 2: Thể loại Truyện dài
        const Text(
          'Truyện dài',
          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _truyenDaiGenres.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.65,
          ),
          itemBuilder: (context, index) => _buildGenreCardItem(_truyenDaiGenres[index]),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  // TAB 2: EBOOK (SÁCH TRUYỆN - KHỚP ÁNH 2, 3, 4)
  Widget _buildEBookTab() {
    return Column(
      children: [
        _buildCategoryChipsBar(),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            physics: const BouncingScrollPhysics(),
            itemCount: _eBookProducts.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 18,
              childAspectRatio: 0.62,
            ),
            itemBuilder: (context, index) => _buildBookGridTile(context, _eBookProducts[index]),
          ),
        ),
      ],
    );
  }

  // TAB 3: SÁCH NÓI (AUDIOBOOKS - KHỚP ÁNH 1)
  Widget _buildAudioBookTab() {
    return Column(
      children: [
        _buildCategoryChipsBar(),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            physics: const BouncingScrollPhysics(),
            itemCount: _audioBooks.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 18,
              childAspectRatio: 0.62,
            ),
            itemBuilder: (context, index) => _buildBookGridTile(context, _audioBooks[index]),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryChipsBar() {
    return Container(
      color: const Color(0xFF00BFA5),
      height: 46,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: _categoryChips.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final isSelected = index == _selectedCategoryChip;
          return ChoiceChip(
            label: Text(
              _categoryChips[index],
              style: TextStyle(
                color: isSelected ? const Color(0xFF00BFA5) : Colors.white,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                fontSize: 13,
              ),
            ),
            selected: isSelected,
            selectedColor: Colors.white,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            onSelected: (selected) {
              if (selected) setState(() => _selectedCategoryChip = index);
            },
          );
        },
      ),
    );
  }

  Widget _buildBookGridTile(BuildContext context, _CommunityBook book) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => BookDetailScreen(
              book: BookDetailData(
                bookId: book.id,
                title: book.title,
                author: book.author,
                imageUrl: book.imageUrl,
                colors: const [Color(0xFF00BFA5), Color(0xFF00897B)],
                icon: book.isAudio ? Icons.headphones_rounded : Icons.menu_book_rounded,
              ),
            ),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  book.imageUrl,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    height: 200,
                    color: const Color(0xFF00BFA5),
                    child: const Icon(Icons.book_rounded, color: Colors.white, size: 40),
                  ),
                ),
              ),
              if (book.isAudio)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: CircleAvatar(
                        radius: 22,
                        backgroundColor: Colors.white70,
                        child: Icon(Icons.play_arrow_rounded, color: Colors.black, size: 30),
                      ),
                    ),
                  ),
                ),
              if (book.badge != null)
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFB300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      book.badge!,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
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
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            book.author,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: WakaColors.mutedText,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCircleButton(String title, Color color, IconData icon) {
    return GestureDetector(
      onTap: () => showWakaSearchSheet(context, initialQuery: title),
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildGenreCardItem(_GenreCardItem genre) {
    return GestureDetector(
      onTap: () => showWakaSearchSheet(context, initialQuery: genre.title),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: genre.gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Text(
            genre.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w900,
              shadows: [Shadow(color: Colors.black, blurRadius: 6)],
            ),
          ),
        ),
      ),
    );
  }
}

class _CommunityBook {
  const _CommunityBook({
    required this.id,
    required this.title,
    required this.author,
    required this.imageUrl,
    this.badge,
    this.isAudio = false,
  });

  final int id;
  final String title;
  final String author;
  final String imageUrl;
  final String? badge;
  final bool isAudio;
}

class _Author {
  const _Author(this.name, this.followers, this.avatarUrl);
  final String name;
  final String followers;
  final String avatarUrl;
}

class _GenreCardItem {
  const _GenreCardItem(this.title, this.imageUrl, this.gradient);
  final String title;
  final String imageUrl;
  final List<Color> gradient;
}
