import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../reader/book_detail_screen.dart';

enum YouthCornerType { student, military }

class YouthCornerDetailScreen extends StatefulWidget {
  const YouthCornerDetailScreen({super.key, required this.type});

  final YouthCornerType type;

  @override
  State<YouthCornerDetailScreen> createState() => _YouthCornerDetailScreenState();
}

class _YouthCornerDetailScreenState extends State<YouthCornerDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _heroBannerIndex = 0;

  bool get _isMilitary => widget.type == YouthCornerType.military;
  String get _title => _isMilitary ? 'Góc lực lượng vũ trang' : 'Góc sinh viên';

  static const _studentHeroBanners = [
    'https://bizweb.dktcdn.net/100/180/408/products/tieu-su-elon-musk.jpg?v=1698399035523',
    'https://images.unsplash.com/photo-1512820790803-83ca734da794?w=800',
    'https://images.unsplash.com/photo-1543002588-bfa74002ed7e?w=800',
  ];

  static const _militaryHeroBanners = [
    'https://sachphapluatvn.com/hoanghung/5/images/T%C4%90_%202321.jpg',
    'https://images.unsplash.com/photo-1541339907198-e08756dedf3f?w=800',
    'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=800',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final heroBanners = _isMilitary ? _militaryHeroBanners : _studentHeroBanners;

    return Scaffold(
      backgroundColor: WakaColors.background,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          _title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, color: Colors.white),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Đang chia sẻ link $_title...'),
                  backgroundColor: WakaColors.accent,
                ),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          tabs: const [
            Tab(text: 'Sách'),
            Tab(text: 'Podcast'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildBooksTab(heroBanners),
          _buildPodcastTab(),
        ],
      ),
    );
  }

  Widget _buildBooksTab(List<String> heroBanners) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      children: [
        // HERO CAROUSEL HEADER
        Container(
          color: const Color(0xFF1E1E1E),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          child: Column(
            children: [
              SizedBox(
                height: 260,
                child: PageView.builder(
                  itemCount: heroBanners.length,
                  onPageChanged: (idx) => setState(() => _heroBannerIndex = idx),
                  itemBuilder: (context, index) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.5),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.network(
                            heroBanners[index],
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Container(
                              color: const Color(0xFFD32F2F),
                              child: const Center(
                                child: Icon(Icons.shield_rounded, color: Colors.white, size: 64),
                              ),
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.transparent, Colors.black.withValues(alpha: 0.7)],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 16,
                            left: 16,
                            right: 16,
                            child: Text(
                              _isMilitary
                                  ? 'Võ Văn Kiệt - Tiểu sử đồng chí lãnh đạo'
                                  : 'Elon Musk by Walter Isaacson',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                shadows: [Shadow(color: Colors.black, blurRadius: 8)],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),

              // Dots indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  heroBanners.length,
                  (idx) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: _heroBannerIndex == idx ? 16 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _heroBannerIndex == idx ? const Color(0xFF00BFA5) : Colors.white38,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Action buttons (ĐỌC SÁCH / NGHE SÁCH)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00BFA5),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => BookDetailScreen(
                            book: BookDetailData(
                              bookId: _isMilitary ? 801 : 802,
                              title: _isMilitary
                                  ? 'Võ Văn Kiệt - Tiểu sử'
                                  : 'Elon Musk by Walter Isaacson',
                              author: _isMilitary ? 'NXB Chính Trị Quốc Gia' : 'Walter Isaacson',
                              imageUrl: heroBanners[_heroBannerIndex],
                              colors: const [Color(0xFF00BFA5), Color(0xFF00897B)],
                              icon: Icons.menu_book_rounded,
                            ),
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.menu_book_rounded, size: 20),
                    label: const Text(
                      'ĐỌC SÁCH',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                    ),
                  ),
                  if (_isMilitary) ...[
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00BFA5),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Đang phát Sách nói Võ Văn Kiệt...'),
                            backgroundColor: Color(0xFF00BFA5),
                          ),
                        );
                      },
                      icon: const Icon(Icons.headphones_rounded, size: 20),
                      label: const Text(
                        'NGHE SÁCH',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),

        // SECTIONS BASED ON SCREENSHOTS
        if (_isMilitary) ...[
          // Section 1: Vũ khí quân sự (Khớp Ảnh 4)
          _buildCornerSection('Vũ khí quân sự', [
            _CornerBookTile(803, 'Cơ động ra-đa bảo đảm tác chiến', 'Nguyễn Xuân Giang', 'https://special.nhandan.vn/kinh-nghiem-bao-dam-ky-thuat/assets/qmqvXkxl8L/_bqd2758-4096x2731.jpg'),
            _CornerBookTile(804, '10 phút hủy diệt "pháo đài bay"', 'Trung Nguyễn', 'https://btllang.bqp.vn/images/Thang_12-2015/8-12-2015/DBP_tren_khong__phan_1_anh_0.png'),
            _CornerBookTile(805, 'Trong chớp lửa SAM-2', 'Ngô Duy Đông', 'https://lookaside.fbsbx.com/lookaside/crawler/media/?media_id=1468387411621349'),
          ]),

          // Section 2: Lửa kháng chiến (Khớp Ảnh 1)
          _buildCornerSection('Lửa kháng chiến', [
            _CornerBookTile(806, 'Nhật ký Quảng Trị', 'Lê Quang Đạo', 'http://bizweb.dktcdn.net/thumb/grande/100/180/408/products/nhat-ky-quang-tri-1972.jpg?v=1651324280003'),
            _CornerBookTile(807, 'Nhật ký Quảng Trị (Bản đặc biệt)', 'Lê Quang Đạo', 'https://307a0e78.vws.vegacdn.vn/view/v2/image/img.fm_audio_book/0/0/0/4562_fb.jpg?v=2&w=977&h=522'),
            _CornerBookTile(808, 'Vượt sông Thạch Hãn trong mưa pháo', 'Tuấn Tú', 'https://images.unsplash.com/photo-1543002588-bfa74002ed7e?w=400'),
          ]),

          // Section 3: Danh tướng Việt (Khớp Ảnh 1)
          _buildCornerSection('Danh tướng Việt', [
            _CornerBookTile(809, 'Bác Hồ với triển lãm công binh', 'Duy Thụy', 'https://i.ytimg.com/vi/q0mZA5xQCcc/oar2.jpg?sqp=-oaymwEYCJUDENAFSFqQAgHyq4qpAwcIARUAAIhC&rs=AOn4CLA2YB_Q7_RJ2-0VO9gFCYIMbCpbtg&usqp=CCk'),
            _CornerBookTile(810, 'Tay xỏ túi quần, tay cầm súng', 'Thảo Nguyên', 'https://file.qdnd.vn/data/images/0/2020/05/18/vuhuyen/1552020huyen15pg.jpg?dpi=150&quality=100&w=575'),
            _CornerBookTile(811, 'Người mở đầu mô hình "Kết nghĩa b..."', 'Tuệ Lâm', 'http://file.qdnd.vn/data/images/13/2018/01/08/tvtuongvy/26-1.jpg?w=578'),
          ]),
        ] else ...[
          // Section 1: Văn học nước ngoài (Khớp Ảnh 3)
          _buildCornerSection('Văn học nước ngoài', [
            _CornerBookTile(812, 'Mù lòa', 'José Saramago', 'https://cdn1.fahasa.com/media/catalog/product/9/7/9786049761553.jpg'),
            _CornerBookTile(813, 'Chúng ta thấy lại những vì sao', 'Jayson Greene', 'https://cdn1.fahasa.com/media/catalog/product/9/7/9786043179101.jpg'),
            _CornerBookTile(814, 'Âm thanh và cuồng nộ', 'William Faulkner', 'https://images.unsplash.com/photo-1543002588-bfa74002ed7e?w=400'),
          ]),

          // Section 2: Văn học thanh xuân (Khớp Ảnh 2)
          _buildCornerSection('Văn học thanh xuân', [
            _CornerBookTile(815, 'Đến phủ Khai Phong làm nhân viên công vụ', 'Á Đường Mặc Tâm', 'https://307a0e78.vws.vegacdn.vn/view/v2/image/img.book/0/0/0/1521.jpg?v=3&w=480&h=700'),
            _CornerBookTile(816, 'Thái tử phi thăng chức ký (Tập 1)', 'Tiên Chanh', 'https://dtv-ebook.com.vn/images/truyen-online/ebook-thai-tu-phi-thang-chuc-ky-tap-1-prc-pdf-epub.jpg'),
            _CornerBookTile(817, 'Giữa chốn phồn hoa gặp được người', 'Cửu Nguyệt Hi', 'https://307a0e78.vws.vegacdn.vn/view/v2/image/img.book/0/0/1/33467.jpg?v=1&w=480&h=700'),
          ]),

          // Section 3: Ngôn từ hạnh phúc (Khớp Ảnh 2)
          _buildCornerSection('Ngôn từ hạnh phúc', [
            _CornerBookTile(818, 'Cái ôm diệu kỳ', 'Nick Vujicic', 'https://images.unsplash.com/photo-1516589178581-6cd7833ae3b2?w=400'),
            _CornerBookTile(819, 'Tâm tình với Đất Mẹ', 'Thích Nhất Hạnh', 'https://307a0e78.vws.vegacdn.vn/view/v2/image/img.book/0/0/0/12707.jpg?v=9&w=480&h=700'),
            _CornerBookTile(820, 'Trái tim tuổi 19', 'Tony Parsons', 'https://images.unsplash.com/photo-1461360370896-922624d12aa1?w=400'),
          ]),
        ],
        const SizedBox(height: 40),
      ],
    );
  }



  Widget _buildPodcastTab() {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        _buildCornerSection('Podcast chọn lọc', [
          _CornerBookTile(840, 'Hành trình người lính', 'Waka Radio', 'https://images.unsplash.com/photo-1516979187457-637abb4f9353?w=400'),
        ]),
      ],
    );
  }

  Widget _buildCornerSection(String title, List<_CornerBookTile> books) {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: Colors.white60, size: 26),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
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
                            colors: const [Color(0xFFD32F2F), Color(0xFFB71C1C)],
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
                              color: WakaColors.surface,
                              child: const Icon(Icons.book_rounded, color: Colors.white),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
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
          ),
        ],
      ),
    );
  }
}

class _CornerBookTile {
  const _CornerBookTile(this.id, this.title, this.author, this.imageUrl);
  final int id;
  final String title;
  final String author;
  final String imageUrl;
}
