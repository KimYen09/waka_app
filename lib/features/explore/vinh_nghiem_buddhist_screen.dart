import 'package:flutter/material.dart';

import '../../shared/widgets/waka_search_sheet.dart';
import '../reader/book_detail_screen.dart';

class VinhNghiemBuddhistScreen extends StatefulWidget {
  const VinhNghiemBuddhistScreen({super.key});

  @override
  State<VinhNghiemBuddhistScreen> createState() => _VinhNghiemBuddhistScreenState();
}

class _VinhNghiemBuddhistScreenState extends State<VinhNghiemBuddhistScreen> {
  int _currentNavIndex = 0;
  int _libraryTab = 0; // 0: Đã nghe, 1: Đã đọc, 2: Yêu thích

  static const _goldColor = Color(0xFFC5A059);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: Column(
          children: [
            // Header Phật giáo vàng/ngọc bích
            Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 14),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFE0F2F1), Color(0xFFFFF8E1)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _goldColor),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const Text(
                        'Sách Phật Vĩnh Nghiêm',
                        style: TextStyle(
                          color: _goldColor,
                          fontSize: 21,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.spa_rounded, color: _goldColor, size: 28),
                    ],
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => showWakaSearchSheet(context, initialQuery: 'Sách Phật Vĩnh Nghiêm'),
                    child: Container(
                      height: 42,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.search_rounded, color: Colors.grey, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Nhập từ khóa tìm kiếm',
                            style: TextStyle(color: Colors.grey, fontSize: 14),
                          ),
                          Spacer(),
                          Icon(Icons.mic_none_rounded, color: Colors.grey, size: 20),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Tab View Body
            Expanded(
              child: IndexedStack(
                index: _currentNavIndex,
                children: [
                  _buildEBookTab(),
                  _buildCategoryTab(),
                  _buildProfileTab(),
                ],
              ),
            ),
          ],
        ),
      ),

      // Bottom Navigation Bar 3 Tabs Phật Giáo
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentNavIndex.clamp(0, 2),
          onTap: (index) => setState(() => _currentNavIndex = index),
          selectedItemColor: _goldColor,
          unselectedItemColor: Colors.grey,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.local_florist_rounded),
              label: 'Sách điện tử',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.filter_vintage_rounded),
              label: 'Danh mục',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.eco_rounded),
              label: 'Cá nhân',
            ),
          ],
        ),
      ),
    );
  }

  // TAB 1: SÁCH ĐIỆN TỬ (Khớp 2 Ảnh mới + Ảnh cũ)
  Widget _buildEBookTab() {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        // SECTION 1: Phật pháp ứng dụng (Khớp Ảnh 1 mới)
        _buildSectionTitleHeader('Phật pháp ứng dụng'),
        const SizedBox(height: 14),
        _buildFeaturedBookTile(
          id: 700,
          title: '365 ngày tâm an',
          author: 'Vạn Lại Quán Như',
          imageUrl: 'https://images.unsplash.com/photo-1506126613408-eca07ce68773?w=500',
          summary:
              'Những lúc giải quyết xong công việc, tôi thường tự thưởng cho mình bằng cách đọc một vài bài viết hay, mang tính chất khích lệ ý chí, nuôi dưỡng tâm hồn. Sau đó, nhận thấy "món ngon không thể hưởng thụ một mình", nên tôi biên dịch lại những b...',
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 210,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildBuddhistBookItem('365 ngày tâm an', 'https://images.unsplash.com/photo-1506126613408-eca07ce68773?w=500'),
              _buildBuddhistBookItem('Chân lý vô thường', 'https://images.unsplash.com/photo-1518241353330-0f7941c2d9b5?w=500'),
              _buildBuddhistBookItem('Ba bước quản lý cuộc đời', 'https://bizweb.dktcdn.net/100/197/269/products/1-0f8e860e-9a8d-4e06-80a7-68e4685ac5c8.jpg?v=1759391926580'),
              _buildBuddhistBookItem('Có Phật pháp là có biện pháp', 'https://down-vn.img.susercontent.com/file/vn-11134207-7r98o-lvef03jxjiw4fc'),
            ],
          ),
        ),
        const SizedBox(height: 28),

        // SECTION 2: Phật pháp chuyên sâu
        _buildSectionTitleHeader('Phật pháp chuyên sâu'),
        const SizedBox(height: 14),
        _buildFeaturedBookTile(
          id: 701,
          title: 'Tìm hiểu nguồn gốc Duy thức học',
          author: 'Thích Quảng Đại',
          imageUrl: 'https://images.unsplash.com/photo-1544716278-ca5e3f4abd8c?w=500',
          summary:
              'Xưa nay, Duy thức học (Vijñānavādin) là một vấn đề đặc biệt được giới nghiên cứu Phật giáo rất quan tâm, bởi vì nó là một trong những nền tư tưởng triết học cốt lõi của Phật giáo...',
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 210,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildBuddhistBookItem('Tìm hiểu nguồn gốc Duy thức học', 'https://images.unsplash.com/photo-1544716278-ca5e3f4abd8c?w=500'),
              _buildBuddhistBookItem('Luật học đại cương', 'https://images.unsplash.com/photo-1589829545856-d10d557cf95f?w=500'),
              _buildBuddhistBookItem('Đối thoại giữa mật giáo và hiển giáo', 'https://307a0e78.vws.vegacdn.vn/view/v2/image/img.book/0/0/1/40208.jpg?v=2&w=480&h=700'),
              _buildBuddhistBookItem('Lịch sử Phật giáo Ấn Độ', 'https://product.hstatic.net/200000979221/product/lich-su-phat-giao-an-do_be0ccf3bf704422981a77dd66ca89b35.png'),
            ],
          ),
        ),
        const SizedBox(height: 28),

        // SECTION 3: Có thể bạn thích (Khớp Ảnh 2 mới)
        _buildSectionTitleHeader('Có thể bạn thích'),
        const SizedBox(height: 14),
        SizedBox(
          height: 210,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildBuddhistBookItem('Kinh Địa Tạng Bồ Tát Bổn Nguyện (Sách tranh)', 'https://cdn1.fahasa.com/media/flashmagazine/images/page_images/so_tay_chep_kinh___dia_tang_bo_tat_bon_nguyen/2024_12_04_16_00_57_1-390x510.jpg'),
              _buildBuddhistBookItem('Đời ta ta vui', 'https://images.unsplash.com/photo-1509198397868-475647b2a1e5?w=500'),
              _buildBuddhistBookItem('An lạc giữa dòng đời', 'https://lookaside.fbsbx.com/lookaside/crawler/media/?media_id=824136326384451'),
            ],
          ),
        ),
        const SizedBox(height: 28),

        // SECTION 4: Sách miễn phí (Khớp Ảnh 2 mới)
        _buildSectionTitleHeader('Sách miễn phí'),
        const SizedBox(height: 14),
        SizedBox(
          height: 210,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildBuddhistBookItem('Truyện tranh Kinh Dược Sư - Tập 1', 'https://cdn1.fahasa.com/media/catalog/product/9/7/9786046175087.jpg'),
              _buildBuddhistBookItem('Truyện tranh Kinh Dược Sư - Tập 2', 'https://bookbuy.vn/Res/Images/Product/duoc-su-tu-su-light-novel-%E2%80%93-tap-2_118816_1.jpg'),
              _buildBuddhistBookItem('Lời tâm huyết', 'https://salt.tikicdn.com/cache/w300/ts/product/1a/13/ff/3642c79f0e321c64b529fffa9f4904be.jpg'),
            ],
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }



  // TAB 3: DANH MỤC
  Widget _buildCategoryTab() {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Thể loại sách điện tử',
          style: TextStyle(color: _goldColor, fontSize: 18, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.65,
          children: [
            _buildCategoryGridItem('PHẬT PHÁP ỨNG DỤNG', 'https://images.unsplash.com/photo-1506126613408-eca07ce68773?w=500'),
            _buildCategoryGridItem('PHẬT PHÁP CHUYÊN SÂU', 'https://images.unsplash.com/photo-1518241353330-0f7941c2d9b5?w=500'),
            _buildCategoryGridItem('SÁCH TỤNG NIỆM', 'https://images.unsplash.com/photo-1544716278-ca5e3f4abd8c?w=500'),
            _buildCategoryGridItem('TRUYỆN TRANH PHẬT GIÁO', 'https://images.unsplash.com/photo-1512820790803-83ca734da794?w=500'),
          ],
        ),
        const SizedBox(height: 24),

        const Text(
          'Thể loại tập âm thanh',
          style: TextStyle(color: _goldColor, fontSize: 18, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.65,
          children: [
            _buildCategoryGridItem('THIỀN', 'https://images.unsplash.com/photo-1506126613408-eca07ce68773?w=500'),
            _buildCategoryGridItem('REVIEW CHÙA', 'https://images.unsplash.com/photo-1541339907198-e08756dedf3f?w=500'),
            _buildCategoryGridItem('PHẬT PHÁP', 'https://images.unsplash.com/photo-1518241353330-0f7941c2d9b5?w=500'),
          ],
        ),
        const SizedBox(height: 30),
      ],
    );
  }

  // TAB 4: CÁ NHÂN
  Widget _buildProfileTab() {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFDF5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFF0E6D2)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              const CircleAvatar(
                radius: 28,
                backgroundColor: Color(0xFF00BFA5),
                child: Icon(Icons.person_rounded, color: Colors.white, size: 36),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      '0932707674',
                      style: TextStyle(
                        color: _goldColor,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Tài khoản thường',
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
              ),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: _goldColor,
                  side: const BorderSide(color: _goldColor),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Đang đăng ký Nâng cấp Hội viên Sách Phật...'),
                      backgroundColor: _goldColor,
                    ),
                  );
                },
                child: const Text(
                  'NÂNG CẤP\nHỘI VIÊN',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        const Text(
          'Thư viện của bạn',
          style: TextStyle(color: _goldColor, fontSize: 18, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),

        Row(
          children: [
            _buildLibraryChoiceChip(0, 'Đã nghe'),
            const SizedBox(width: 10),
            _buildLibraryChoiceChip(1, 'Đã đọc'),
            const SizedBox(width: 10),
            _buildLibraryChoiceChip(2, 'Yêu thích'),
          ],
        ),
        const SizedBox(height: 50),

        Center(
          child: Column(
            children: const [
              Icon(Icons.book_outlined, color: _goldColor, size: 70),
              SizedBox(height: 16),
              Text(
                'Bạn chưa có cuốn sách nào',
                style: TextStyle(color: Colors.grey, fontSize: 15),
              ),
            ],
          ),
        ),
        const SizedBox(height: 50),
      ],
    );
  }

  Widget _buildSectionTitleHeader(String title) {
    return Row(
      children: [
        const Icon(Icons.spa_rounded, color: _goldColor, size: 22),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: _goldColor,
            fontSize: 19,
            fontWeight: FontWeight.w800,
          ),
        ),
        const Spacer(),
        const Icon(Icons.chevron_right_rounded, color: _goldColor, size: 26),
      ],
    );
  }

  Widget _buildFeaturedBookTile({
    required int id,
    required String title,
    required String author,
    required String imageUrl,
    required String summary,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => BookDetailScreen(
              book: BookDetailData(
                bookId: id,
                title: title,
                author: author,
                imageUrl: imageUrl,
                colors: const [Color(0xFFC5A059), Color(0xFF8C6D31)],
                icon: Icons.spa_rounded,
              ),
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                imageUrl,
                width: 110,
                height: 155,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  width: 110,
                  height: 155,
                  color: const Color(0xFFF5F0E6),
                  child: const Icon(Icons.book_rounded, color: _goldColor),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    summary,
                    maxLines: 5,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 12.5,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLibraryChoiceChip(int index, String label) {
    final isSelected = _libraryTab == index;
    return GestureDetector(
      onTap: () => setState(() => _libraryTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? _goldColor : const Color(0xFFF5F0E6),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : _goldColor,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            fontSize: 13.5,
          ),
        ),
      ),
    );
  }

  Widget _buildBuddhistBookItem(String title, String imageUrl) {
    return Container(
      width: 110,
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              imageUrl,
              width: 110,
              height: 150,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                width: 110,
                height: 150,
                color: const Color(0xFFF5F0E6),
                child: const Icon(Icons.book_rounded, color: _goldColor),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.black87, fontSize: 12.5, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }



  Widget _buildCategoryGridItem(String title, String imageUrl) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        image: DecorationImage(
          image: NetworkImage(imageUrl),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(Colors.black.withValues(alpha: 0.45), BlendMode.darken),
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13.5,
              fontWeight: FontWeight.w900,
              shadows: [Shadow(color: Colors.black, blurRadius: 6)],
            ),
          ),
        ),
      ),
    );
  }
}
