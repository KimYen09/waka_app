import 'package:flutter/material.dart';

import '../../core/services/local_books_service.dart';
import '../../core/services/waka_scraper_service.dart';
import '../../core/theme/app_theme.dart';
import '../../features/reader/book_detail_screen.dart';

/// Hiển thị Modal/Sheet Tìm kiếm Sách Waka dùng chung cho toàn bộ ứng dụng
void showWakaSearchSheet(BuildContext context, {String initialQuery = ''}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _WakaSearchModal(initialQuery: initialQuery),
  );
}

class _WakaSearchModal extends StatefulWidget {
  const _WakaSearchModal({this.initialQuery = ''});

  final String initialQuery;

  @override
  State<_WakaSearchModal> createState() => _WakaSearchModalState();
}

class _WakaSearchModalState extends State<_WakaSearchModal> {
  final TextEditingController _controller = TextEditingController();
  final LocalBooksService _localBooksService = const LocalBooksService();

  List<WakaScrapedBook> _allBooks = [];
  List<WakaScrapedBook> _filteredBooks = [];
  bool _loading = true;
  String _query = '';

  static const List<String> _popularTags = [
    'World Cup 2026',
    'Sách Hội Viên',
    'Hiệu Sồi',
    'Kỹ năng sống',
    'Tài chính',
    'Đắc Nhân Tâm',
    'Truyện tranh',
    'Sách nói',
  ];

  @override
  void initState() {
    super.initState();
    _query = widget.initialQuery;
    _controller.text = widget.initialQuery;
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final result = await _localBooksService.loadBooks();
      if (!mounted) return;
      setState(() {
        _allBooks = result.books;
        _loading = false;
        _filterBooks(_query);
      });
    } on Object {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  void _filterBooks(String query) {
    _query = query.trim().toLowerCase();
    if (_query.isEmpty) {
      _filteredBooks = [];
    } else {
      _filteredBooks = _allBooks.where((book) {
        final title = book.title.toLowerCase();
        final section = book.section.toLowerCase();
        return title.contains(_query) || section.contains(_query);
      }).toList();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      margin: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 20),
      decoration: const BoxDecoration(
        color: WakaColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Thanh tìm kiếm
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: WakaColors.surface,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: TextField(
                      controller: _controller,
                      autofocus: true,
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                      decoration: InputDecoration(
                        hintText: 'Tìm tên sách, tác giả, thể loại...',
                        hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
                        prefixIcon: const Icon(Icons.search_rounded, color: WakaColors.accent),
                        suffixIcon: _query.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.close_rounded, color: Colors.white54, size: 20),
                                onPressed: () {
                                  _controller.clear();
                                  setState(() => _filterBooks(''));
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onChanged: (value) => setState(() => _filterBooks(value)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: const Text(
                    'Hủy',
                    style: TextStyle(
                      color: WakaColors.accent,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(color: Colors.white12, height: 24),

          // Nội dung kết quả hoặc từ khóa phổ biến
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: WakaColors.accent))
                : _query.isEmpty
                    ? _buildPopularKeywords()
                    : _buildSearchResults(),
          ),
          SizedBox(height: bottomPadding),
        ],
      ),
    );
  }

  Widget _buildPopularKeywords() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        Row(
          children: const [
            Icon(Icons.local_fire_department_rounded, color: Color(0xFFFF6B00), size: 20),
            SizedBox(width: 8),
            Text(
              'Từ khóa phổ biến',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _popularTags.map((tag) {
            return GestureDetector(
              onTap: () {
                _controller.text = tag;
                setState(() => _filterBooks(tag));
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: WakaColors.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white12),
                ),
                child: Text(
                  tag,
                  style: const TextStyle(
                    color: Color(0xDDFFFFFF),
                    fontSize: 13.5,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 30),
        Row(
          children: const [
            Icon(Icons.auto_stories_rounded, color: WakaColors.accent, size: 20),
            SizedBox(width: 8),
            Text(
              'Gợi ý sách nổi bật',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        ..._allBooks.take(5).map((book) => _buildBookItem(book)),
      ],
    );
  }

  Widget _buildSearchResults() {
    if (_filteredBooks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off_rounded, color: Colors.white38, size: 60),
            const SizedBox(height: 12),
            Text(
              'Không tìm thấy sách phù hợp với "$_query"',
              style: const TextStyle(color: Colors.white70, fontSize: 15),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _filteredBooks.length,
      itemBuilder: (context, index) => _buildBookItem(_filteredBooks[index]),
    );
  }

  Widget _buildBookItem(WakaScrapedBook book) {
    return InkWell(
      onTap: () {
        Navigator.of(context).pop();
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => BookDetailScreen(
              book: BookDetailData(
                bookId: book.id,
                title: book.title,
                author: book.section.isNotEmpty ? book.section : 'Waka Books',
                imageUrl: book.imageUrl,
                sourceUrl: book.url,
                section: book.section,
                colors: const [Color(0xFF163D2E), Color(0xFF47C982)],
                icon: Icons.menu_book_rounded,
              ),
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: WakaColors.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: book.imageUrl.isNotEmpty
                  ? Image.network(
                      book.imageUrl,
                      width: 50,
                      height: 70,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _fallbackCover(),
                    )
                  : _fallbackCover(),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    book.section.isNotEmpty ? book.section : 'Sách điện tử',
                    style: const TextStyle(
                      color: WakaColors.accent,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.white38),
          ],
        ),
      ),
    );
  }

  Widget _fallbackCover() {
    return Container(
      width: 50,
      height: 70,
      color: const Color(0xFF1E3A2F),
      child: const Center(
        child: Icon(Icons.book_rounded, color: WakaColors.accent, size: 24),
      ),
    );
  }
}
