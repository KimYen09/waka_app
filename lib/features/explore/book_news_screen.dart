import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../shared/widgets/waka_search_sheet.dart';
import '../reader/book_detail_screen.dart';

class BookNewsArticle {
  const BookNewsArticle({
    required this.id,
    required this.title,
    required this.category,
    required this.author,
    required this.date,
    required this.readTime,
    required this.summary,
    required this.content,
    required this.imageUrl,
    this.isHot = false,
    this.relatedBookTitle,
    this.relatedBookId = 1,
  });

  final int id;
  final String title;
  final String category;
  final String author;
  final String date;
  final String readTime;
  final String summary;
  final String content;
  final String imageUrl;
  final bool isHot;
  final String? relatedBookTitle;
  final int relatedBookId;
}

class BookNewsScreen extends StatefulWidget {
  const BookNewsScreen({super.key});

  @override
  State<BookNewsScreen> createState() => _BookNewsScreenState();
}

class _BookNewsScreenState extends State<BookNewsScreen> {
  int _selectedCategoryIndex = 0;
  static const _categories = ['Tất cả', 'Đọc nhiều', 'Tác giả', 'Cuộc thi', 'Review sách'];

  static const List<BookNewsArticle> _articles = [
    BookNewsArticle(
      id: 1,
      title: 'Waka tích hợp Trợ lý ảo AI Gemini: Cách mạng hóa trải nghiệm tóm tắt & gợi ý sách 24/7',
      category: 'Công nghệ & Đọc sách',
      author: 'Ban Biên Tập Waka',
      date: '04/08/2026',
      readTime: '4 phút đọc',
      isHot: true,
      summary:
          'Nền tảng đọc sách Waka chính thức tích hợp công nghệ AI Gemini tiên tiến. Độc giả có thể tương tác hỏi đáp, tóm tắt chương sách và nhận gợi ý cuốn sách phù hợp với tâm trạng tức thì.',
      content: '''
Nền tảng đọc sách điện tử Waka vui mừng thông báo chính thức tích hợp Trợ lý ảo AI Gemini vào toàn bộ ứng dụng di động.

Được phát triển dựa trên mô hình ngôn ngữ thế hệ mới, Trợ lý AI Waka mang đến cho độc giả hàng loạt tính năng thông minh:

1. Gợi ý sách thông minh theo tâm trạng và sở thích cá nhân.
2. Tóm tắt nội dung cốt lõi của các cuốn sách dày chỉ trong vài giây.
3. Giải đáp các thắc mắc về tác giả, bối cảnh lịch sử và thông điệp tác phẩm.

Người dùng có thể trải nghiệm ngay tính năng mới bằng cách bấm vào biểu tượng Robot AI ở góc phải màn hình bất kỳ.
''',
      imageUrl: 'https://images.unsplash.com/photo-1516321318423-f06f85e504b3?w=800',
      relatedBookTitle: 'Thói Quen Nguyên Tử - Atomic Habits',
      relatedBookId: 101,
    ),
    BookNewsArticle(
      id: 2,
      title: 'Top 10 cuốn sách bán chạy nhất Tháng 8/2026 trên nền tảng Waka',
      category: 'Đọc nhiều',
      author: 'Waka Ranking',
      date: '03/08/2026',
      readTime: '5 phút đọc',
      summary:
          'Khám phá danh sách 10 tựa sách bùng nổ doanh số và lượt đọc nhiều nhất tháng này, dẫn đầu bởi dòng sách kỹ năng sống và phát triển tư duy tài chính.',
      content: '''
Tháng 8/2026 chứng kiến sự bùng nổ của dòng sách phát triển bản thân và tư duy tài chính trên Waka.

Top 3 cuốn sách dẫn đầu bảng xếp hạng:
1. Đắc Nhân Tâm - Dale Carnegie (Lượt đọc kỷ lục)
2. Cha Giàu Cha Nghèo - Robert Kiyosaki
3. World Cup Ly Kỳ Truyện - Tuyển tập thể thao nổi bật

Hãy truy cập ngay mục Bảng Xếp Hạng trên Trang Chủ để khám phá trọn bộ 10 tựa sách được yêu thích nhất!
''',
      imageUrl: 'https://images.unsplash.com/photo-1544716278-ca5e3f4abd8c?w=800',
      relatedBookTitle: 'Đắc Nhân Tâm',
      relatedBookId: 102,
    ),
    BookNewsArticle(
      id: 3,
      title: 'Phát động Cuộc thi Sáng tác Truyện ngắn Thanh Xuân 2026 - Tổng giải thưởng 50 triệu đồng',
      category: 'Cuộc thi',
      author: 'Cộng đồng Sáng tác Waka',
      date: '02/08/2026',
      readTime: '3 phút đọc',
      summary:
          'Sân chơi sáng tác lớn nhất trong năm dành cho các tác giả trẻ yêu thích viết lách. Thời gian nhận bài dự thi từ ngày 01/08 đến hết ngày 31/08/2026.',
      content: '''
Cộng đồng Sáng Tác Waka chính thức khởi động Cuộc thi viết truyện ngắn với chủ đề "Ký Ức Thanh Xuân".

Cơ cấu giải thưởng hấp dẫn:
• 01 Giải Nhất: 20.000.000 VNĐ + Hợp đồng xuất bản sách điện tử độc quyền.
• 02 Giải Nhì: 10.000.000 VNĐ / giải.
• 03 Giải Ba: 5.000.000 VNĐ / giải.

Các tác giả có thể gửi bài trực tiếp qua mục Cộng Đồng trên ứng dụng Waka.
''',
      imageUrl: 'https://images.unsplash.com/photo-1455390582262-044cdead277a?w=800',
    ),
    BookNewsArticle(
      id: 4,
      title: 'Bí quyết đọc sách hiệu quả: 15 phút mỗi ngày thay đổi tư duy tài chính',
      category: 'Review sách',
      author: 'Chuyên gia Waka',
      date: '01/08/2026',
      readTime: '6 phút đọc',
      summary:
          'Chỉ cần dành 15 phút đọc sách mỗi ngày trước khi ngủ, bạn có thể hoàn thành hơn 20 cuốn sách mỗi năm và trang bị cho mình nền tảng quản lý tài chính vững chắc.',
      content: '''
Đọc sách không đòi hỏi bạn phải dành ra hàng giờ đồng hồ liên tục. Kỹ thuật "Micro-Reading" (Đọc từng khoảng nhỏ) giúp bạn duy trì thói quen đọc bền vững:

• Đặt mục tiêu 10-15 trang mỗi ngày.
• Tận dụng tính năng nghe Sách Nói khi di chuyển.
• Đánh dấu (Bookmark) và ghi chú các ý tưởng cốt lõi.

Trải nghiệm ngay tính năng nghe Sách Nói Waka để tối ưu hóa thời gian của bạn mỗi ngày!
''',
      imageUrl: 'https://images.unsplash.com/photo-1512820790803-83ca734da794?w=800',
      relatedBookTitle: 'Tư Duy Nhanh Và Chậm',
      relatedBookId: 103,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final filtered = _selectedCategoryIndex == 0
        ? _articles
        : _articles
            .where((a) =>
                a.category.toLowerCase().contains(_categories[_selectedCategoryIndex].toLowerCase()))
            .toList();

    return Scaffold(
      backgroundColor: WakaColors.background,
      appBar: AppBar(
        backgroundColor: WakaColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Tin Tức & Sự Kiện Sách',
          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
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
        padding: const EdgeInsets.symmetric(vertical: 12),
        children: [
          // Danh mục tin tức Filter Chips
          SizedBox(
            height: 38,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final isSelected = index == _selectedCategoryIndex;
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategoryIndex = index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected ? WakaColors.accent : WakaColors.surface,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _categories[index],
                      style: TextStyle(
                        color: isSelected ? Colors.black : Colors.white70,
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),

          // Bài viết Nổi Bật (Featured Card)
          if (_articles.isNotEmpty && _selectedCategoryIndex == 0) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildFeaturedCard(context, _articles.first),
            ),
            const SizedBox(height: 24),
          ],

          // Tiêu đề danh sách
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Bài viết mới nhất',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Danh sách tin tức
          ...filtered.map((article) => _buildArticleTile(context, article)),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildFeaturedCard(BuildContext context, BookNewsArticle article) {
    return GestureDetector(
      onTap: () => _openArticleDetail(context, article),
      child: Container(
        decoration: BoxDecoration(
          color: WakaColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Image.network(
                  article.imageUrl,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    height: 200,
                    color: const Color(0xFF163D2E),
                    child: const Center(
                      child: Icon(Icons.newspaper_rounded, color: WakaColors.accent, size: 50),
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF3D00),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.local_fire_department_rounded, color: Colors.white, size: 14),
                        SizedBox(width: 4),
                        Text(
                          'TIN NỔI BẬT',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        article.category,
                        style: const TextStyle(
                          color: WakaColors.accent,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${article.date} • ${article.readTime}',
                        style: const TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    article.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    article.summary,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArticleTile(BuildContext context, BookNewsArticle article) {
    return GestureDetector(
      onTap: () => _openArticleDetail(context, article),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: WakaColors.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                article.imageUrl,
                width: 90,
                height: 90,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  width: 90,
                  height: 90,
                  color: const Color(0xFF163D2E),
                  child: const Icon(Icons.article_rounded, color: WakaColors.accent),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    article.category,
                    style: const TextStyle(
                      color: WakaColors.accent,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    article.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${article.author} • ${article.date}',
                    style: const TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openArticleDetail(BuildContext context, BookNewsArticle article) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ArticleDetailSheet(article: article),
    );
  }
}

class _ArticleDetailSheet extends StatelessWidget {
  const _ArticleDetailSheet({required this.article});

  final BookNewsArticle article;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      margin: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 10),
      decoration: const BoxDecoration(
        color: WakaColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Bar kéo & đóng
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: WakaColors.accent.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    article.category,
                    style: const TextStyle(
                      color: WakaColors.accent,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white, size: 26),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              physics: const BouncingScrollPhysics(),
              children: [
                Text(
                  article.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 12),

                // Tác giả & Ngày đăng
                Row(
                  children: [
                    const CircleAvatar(
                      radius: 16,
                      backgroundColor: Color(0xFFF5A623),
                      child: Text(
                        'W',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          article.author,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          '${article.date} • ${article.readTime}',
                          style: const TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Ảnh bài viết
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    article.imageUrl,
                    height: 210,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      height: 210,
                      color: WakaColors.surface,
                      child: const Center(
                        child: Icon(Icons.newspaper_rounded, color: WakaColors.accent, size: 50),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Nội dung bài viết
                Text(
                  article.content,
                  style: const TextStyle(
                    color: Color(0xDDFFFFFF),
                    fontSize: 15.5,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 24),

                // Thẻ Gợi ý Sách Đi Kèm (nếu có)
                if (article.relatedBookTitle != null) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: WakaColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: WakaColors.accent.withValues(alpha: 0.4)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.auto_awesome_rounded, color: WakaColors.accent, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'SÁCH ĐƯỢC NHẮC TỚI TRONG BÀI',
                              style: TextStyle(
                                color: WakaColors.accent,
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          article.relatedBookTitle!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: WakaColors.accent,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            icon: const Icon(Icons.menu_book_rounded, size: 20),
                            label: const Text(
                              'ĐỌC SÁCH NGAY',
                              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                            ),
                            onPressed: () {
                              Navigator.of(context).pop();
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => BookDetailScreen(
                                    book: BookDetailData(
                                      bookId: article.relatedBookId,
                                      title: article.relatedBookTitle!,
                                      author: 'Waka Recommended',
                                      colors: const [Color(0xFF163D2E), Color(0xFF47C982)],
                                      icon: Icons.menu_book_rounded,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
