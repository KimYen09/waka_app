import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_theme.dart';
import '../../shared/widgets/waka_search_sheet.dart';
import '../reader/book_detail_screen.dart';
import 'youth_corner_detail_screen.dart';

class YouthBookItem {
  const YouthBookItem({
    required this.id,
    required this.title,
    required this.author,
    required this.imageUrl,
    required this.section,
  });

  final int id;
  final String title;
  final String author;
  final String imageUrl;
  final String section;
}

class YouthBooksScreen extends StatelessWidget {
  const YouthBooksScreen({super.key});

  static const _theoDauChanBac = [
    YouthBookItem(
      id: 301,
      title: 'Ba chiếc điện thoại ở nhà sàn Bác Hồ',
      author: 'Vĩnh Thắng',
      imageUrl: 'https://bcp.cdnchinhphu.vn/Uploaded/buithuhuong/2020_05_14/7_ba_chiec_dt.jpg',
      section: 'Theo dấu chân Bác',
    ),
    YouthBookItem(
      id: 302,
      title: 'Sự lãnh đạo của Đảng, Bác Hồ là nguyên nhân cơ bản quyết định thắng lợi...',
      author: 'GS.TS Vũ Đăng Hiền',
      imageUrl: 'https://307a0e78.vws.vegacdn.vn/view/v2/image/img.book/0/0/1/42971.jpg?v=1&w=480&h=710',
      section: 'Theo dấu chân Bác',
    ),
    YouthBookItem(
      id: 303,
      title: '[Tóm tắt sách] Chuyện kể về thời niên thiếu của Bác Hồ',
      author: 'Bùi Ngọc Tam',
      imageUrl: 'https://307a0e78.vws.vegacdn.vn/view/v2/image/img.book/0/0/1/41780.jpg?v=1&w=480&h=700',
      section: 'Theo dấu chân Bác',
    ),
  ];

  static const _toQuocTrongTim = [
    YouthBookItem(
      id: 304,
      title: 'Biển đảo Việt Nam – Bản hùng ca nơi đầu sóng',
      author: 'Hà My',
      imageUrl: 'https://307a0e78.vws.vegacdn.vn/view/v2/image/img.book/0/0/1/43646.jpg?v=1&w=480&h=700',
      section: 'Tổ quốc trong tim',
    ),
    YouthBookItem(
      id: 305,
      title: 'Gạc Ma: Tổ quốc là vĩnh cửu',
      author: 'Trần Trung Hiếu',
      imageUrl: 'https://307a0e78.vws.vegacdn.vn/view/v2/image/img.book/0/0/1/43604.jpg?v=1&w=480&h=710',
      section: 'Tổ quốc trong tim',
    ),
    YouthBookItem(
      id: 306,
      title: 'Mẹ anh hùng vùng sông nước miền Tây',
      author: 'Lê Phi Hùng',
      imageUrl: 'https://cantholib.org.vn/assets/news/gts/xuatban2019/nhung-nguoi-me-anh-hung_300_445.jpg',
      section: 'Tổ quốc trong tim',
    ),
  ];

  static const _dongChayLichSu = [
    YouthBookItem(
      id: 307,
      title: '"Muôn năm tinh thần Nguyễn Văn Trỗi"',
      author: 'Hà Thư',
      imageUrl: 'https://cdn1.fahasa.com/media/flashmagazine/images/page_images/nguyen_van_troi/2022_11_18_15_40_30_1-390x510.jpg',
      section: 'Dòng chảy Lịch sử Việt',
    ),
    YouthBookItem(
      id: 308,
      title: 'Tổng bí thư đầu tiên của Đảng...',
      author: 'PGS.TS Đàm Đức Vượng',
      imageUrl: 'https://images.unsplash.com/photo-1512820790803-83ca734da794?w=400',
      section: 'Dòng chảy Lịch sử Việt',
    ),
    YouthBookItem(
      id: 309,
      title: 'Cuộc tổng tiến công Mậu Thân 1968',
      author: 'Waka Books',
      imageUrl: 'https://baokhanhhoa.vn/file/e7837c02857c8ca30185a8c39b582c03/dataimages/201801/original/images5322653_phat_hanh_sach.jpg',
      section: 'Dòng chảy Lịch sử Việt',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WakaColors.background,
      appBar: AppBar(
        backgroundColor: const Color(0xFFD32F2F),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Tủ Sách Thanh Niên',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded, color: Colors.white, size: 26),
            onPressed: () => showWakaSearchSheet(context),
          ),
        ],
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        children: [
          // Banner Đỏ 27-7 Tri ân Anh hùng dân tộc (Khớp Ảnh 2)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFB71C1C), Color(0xFFD32F2F)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD54F),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Kỷ niệm 27-7',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const Spacer(),
                    const Icon(Icons.star_rounded, color: Color(0xFFFFD54F), size: 24),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'TRI ÂN NHỮNG NGƯỜI ANH HÙNG VĨ ĐẠI CỦA DÂN TỘC',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '“HÒA BÌNH - Một cuốn sách. Một lá cờ trên ngực áo. Một lời tri ấn lịch sử.”',
                  style: TextStyle(
                    color: Color(0xFFD7D7D7),
                    fontSize: 13.5,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Bộ nút tròn: Góc sinh viên, Góc lực lượng vũ trang, Góc chia sẻ
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildCornerButton(context, 'Góc sinh viên', const Color(0xFFFFB300), Icons.school_rounded),
                _buildCornerButton(context, 'Góc lực lượng\nvũ trang', const Color(0xFFD32F2F), Icons.shield_rounded),
                _buildCornerButton(context, 'Góc chia sẻ', const Color(0xFF00BFA5), Icons.spa_rounded),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Banner Tuyển tập chọn lọc - Dòng chảy Lịch sử
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF880E4F), Color(0xFFC2185B)],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: const [
                  Icon(Icons.auto_awesome_rounded, color: Color(0xFFFFD54F), size: 28),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Dòng chảy LỊCH SỬ - 50 năm hào hùng - 50 năm độc lập',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),

          // SECTION 1: Theo dấu chân Bác
          _buildSectionHeader('Theo dấu chân Bác'),
          const SizedBox(height: 12),
          _buildHorizontalBookList(context, _theoDauChanBac),
          const SizedBox(height: 28),

          // SECTION 2: Tổ quốc trong tim
          _buildSectionHeader('Tổ quốc trong tim'),
          const SizedBox(height: 12),
          _buildHorizontalBookList(context, _toQuocTrongTim),
          const SizedBox(height: 28),

          // SECTION 3: Dòng chảy Lịch sử Việt
          _buildSectionHeader('Dòng chảy Lịch sử Việt'),
          const SizedBox(height: 12),
          _buildHorizontalBookList(context, _dongChayLichSu),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildCornerButton(BuildContext context, String title, Color color, IconData icon) {
    return GestureDetector(
      onTap: () async {
        if (title.contains('sinh viên')) {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const YouthCornerDetailScreen(type: YouthCornerType.student),
            ),
          );
        } else if (title.contains('vũ trang')) {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const YouthCornerDetailScreen(type: YouthCornerType.military),
            ),
          );
        } else if (title.contains('chia sẻ')) {
          final uri = Uri.parse('https://tusachthanhnien.vn/feed');
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          } else {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Mở trang Góc Chia Sẻ: https://tusachthanhnien.vn/feed'),
                  backgroundColor: Color(0xFF00BFA5),
                ),
              );
            }
          }
        }
      },
      child: Column(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.35),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 26),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
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
          const Icon(Icons.chevron_right_rounded, color: Colors.white70, size: 26),
        ],
      ),
    );
  }

  Widget _buildHorizontalBookList(BuildContext context, List<YouthBookItem> books) {
    return SizedBox(
      height: 210,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: books.length,
        separatorBuilder: (_, _) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final book = books[index];
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
                      section: book.section,
                      colors: const [Color(0xFFB71C1C), Color(0xFFD32F2F)],
                      icon: Icons.menu_book_rounded,
                    ),
                  ),
                ),
              );
            },
            child: SizedBox(
              width: 120,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      book.imageUrl,
                      width: 120,
                      height: 150,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        width: 120,
                        height: 150,
                        color: const Color(0xFFD32F2F),
                        child: const Icon(Icons.menu_book_rounded, color: Colors.white, size: 36),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    book.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
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
