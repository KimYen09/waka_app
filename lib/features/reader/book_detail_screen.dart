import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_theme.dart';
import 'reader_screen.dart';

class BookDetailData {
  const BookDetailData({
    required this.title,
    required this.colors,
    required this.icon,
    this.author = 'Waka Books',
    this.imageUrl = '',
    this.sourceUrl = '',
    this.price = '99.000đ',
    this.section = 'Sách điện tử',
    this.description = '',
  });

  final String title;
  final String author;
  final String imageUrl;
  final String sourceUrl;
  final String price;
  final String section;
  final String description;
  final List<Color> colors;
  final IconData icon;

  String get resolvedDescription {
    if (description.isNotEmpty) return description;
    if (_normalizedTitle.contains('diem so quyen luc')) {
      return 'Mỗi giao dịch, khoản vay hay lần thanh toán đều để lại một dấu '
          'vết tài chính. Cuốn sách giúp người đọc hiểu cách dữ liệu tín dụng '
          'được hình thành, đánh giá và ảnh hưởng đến những quyết định quan '
          'trọng trong cuộc sống.';
    }
    return '$title mở ra những góc nhìn gần gũi và thực tế, giúp người đọc '
        'khám phá chủ đề ${section.toLowerCase()} theo cách dễ hiểu, có hệ '
        'thống và có thể áp dụng vào đời sống.';
  }

  String get _normalizedTitle {
    return title
        .toLowerCase()
        .replaceAll(RegExp('[àáạảãâầấậẩẫăằắặẳẵ]'), 'a')
        .replaceAll(RegExp('[èéẹẻẽêềếệểễ]'), 'e')
        .replaceAll(RegExp('[ìíịỉĩ]'), 'i')
        .replaceAll(RegExp('[òóọỏõôồốộổỗơờớợởỡ]'), 'o')
        .replaceAll(RegExp('[ùúụủũưừứựửữ]'), 'u')
        .replaceAll(RegExp('[ỳýỵỷỹ]'), 'y')
        .replaceAll('đ', 'd');
  }
}

class BookDetailScreen extends StatefulWidget {
  const BookDetailScreen({super.key, required this.book});

  final BookDetailData book;

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  bool _isFavorite = false;
  bool _showFullDescription = false;
  bool _showMemberOffer = true;

  void _openReader() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => ReaderScreen(book: widget.book)),
    );
  }

  Future<void> _shareBook() async {
    final value = widget.book.sourceUrl.isEmpty
        ? 'Đọc ${widget.book.title} trên Waka Demo'
        : widget.book.sourceUrl;
    await Clipboard.setData(ClipboardData(text: value));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Đã sao chép liên kết sách.')));
  }

  void _showBookActions() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF29292F),
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: _MiniBookCover(book: widget.book, width: 58),
                  title: Text(
                    widget.book.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  subtitle: Text(
                    widget.book.author,
                    style: const TextStyle(color: Colors.white60),
                  ),
                ),
                const Divider(color: Colors.white12),
                _ActionTile(
                  icon: _isFavorite
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  label: _isFavorite ? 'Bỏ yêu thích' : 'Yêu thích',
                  onTap: () {
                    Navigator.pop(sheetContext);
                    setState(() => _isFavorite = !_isFavorite);
                  },
                ),
                _ActionTile(
                  icon: Icons.star_border_rounded,
                  label: 'Đánh giá',
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _showRatingSheet();
                  },
                ),
                _ActionTile(
                  icon: Icons.download_rounded,
                  label: 'Tải sách',
                  trailing: const _MemberPill(),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _showMessage('Tính năng tải sách dành cho Hội viên.');
                  },
                ),
                _ActionTile(
                  icon: Icons.share_rounded,
                  label: 'Chia sẻ sách',
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _shareBook();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showRatingSheet() {
    var rating = 5;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF29292F),
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Bạn thấy cuốn sách thế nào?',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      5,
                      (index) => IconButton(
                        onPressed: () =>
                            setSheetState(() => rating = index + 1),
                        icon: Icon(
                          index < rating
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          color: WakaColors.gold,
                          size: 38,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      _showMessage('Cảm ơn bạn đã đánh giá $rating sao.');
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: WakaColors.accent,
                      foregroundColor: Colors.black,
                      minimumSize: const Size.fromHeight(50),
                    ),
                    child: const Text(
                      'GỬI ĐÁNH GIÁ',
                      style: TextStyle(fontWeight: FontWeight.w900),
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

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF090909),
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _BookHero(
                book: widget.book,
                isFavorite: _isFavorite,
                onFavorite: () => setState(() => _isFavorite = !_isFavorite),
                onShare: _shareBook,
                onRead: _openReader,
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    22,
                    20,
                    _showMemberOffer ? 190 : 40,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _BookStats(onMore: _showBookActions),
                      const SizedBox(height: 30),
                      const _SectionHeading('Giới thiệu sách'),
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: () => setState(
                          () => _showFullDescription = !_showFullDescription,
                        ),
                        child: Text.rich(
                          TextSpan(
                            text: widget.book.resolvedDescription,
                            children: [
                              if (!_showFullDescription)
                                const TextSpan(
                                  text: '  Xem thêm',
                                  style: TextStyle(
                                    color: Colors.white38,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                            ],
                          ),
                          maxLines: _showFullDescription ? null : 4,
                          overflow: _showFullDescription
                              ? TextOverflow.visible
                              : TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            height: 1.55,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _Tag(widget.book.section),
                          const _Tag('Phát triển cá nhân'),
                        ],
                      ),
                      const SizedBox(height: 34),
                      const _SectionHeading('Bên trong cuốn sách này có gì?'),
                      const SizedBox(height: 14),
                      _InsideBookAccordion(book: widget.book),
                      const SizedBox(height: 34),
                      _RelatedBooks(
                        book: widget.book,
                        onOpen: _openRelatedBook,
                      ),
                      const SizedBox(height: 34),
                      const _ReaderReviewEmpty(),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (_showMemberOffer)
            Positioned(
              left: 14,
              right: 14,
              bottom: 14,
              child: _MemberOfferBanner(
                onClose: () => setState(() => _showMemberOffer = false),
                onBuy: () => _showMessage('Đã mở lựa chọn gói Hội viên.'),
              ),
            ),
        ],
      ),
    );
  }

  void _openRelatedBook(BookDetailData book) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => BookDetailScreen(book: book)),
    );
  }
}

class _BookHero extends StatelessWidget {
  const _BookHero({
    required this.book,
    required this.isFavorite,
    required this.onFavorite,
    required this.onShare,
    required this.onRead,
  });

  final BookDetailData book;
  final bool isFavorite;
  final VoidCallback onFavorite;
  final VoidCallback onShare;
  final VoidCallback onRead;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      stretch: true,
      expandedHeight: 600,
      backgroundColor: const Color(0xFF170909),
      leading: IconButton(
        onPressed: () => Navigator.of(context).pop(),
        icon: const Icon(Icons.arrow_back_rounded, size: 32),
      ),
      actions: [
        IconButton(
          onPressed: onFavorite,
          icon: Icon(
            isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            size: 32,
          ),
        ),
        IconButton(
          onPressed: onShare,
          icon: const Icon(Icons.share_rounded, size: 30),
        ),
        const SizedBox(width: 6),
      ],
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.parallax,
        background: Stack(
          fit: StackFit.expand,
          children: [
            _BookBackground(book: book),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x33000000),
                    Color(0xAA130707),
                    Color(0xFF090909),
                  ],
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 68, 22, 18),
                child: Column(
                  children: [
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          _MiniBookCover(book: book, width: 180),
                          const SizedBox(width: 18),
                          Expanded(child: _AccessCard(book: book)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        book.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 31,
                          height: 1.08,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Tác giả: ${book.author}  ›',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 19,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: onRead,
                      style: FilledButton.styleFrom(
                        backgroundColor: WakaColors.accent,
                        foregroundColor: Colors.black,
                        minimumSize: const Size.fromHeight(58),
                        shape: const StadiumBorder(),
                      ),
                      child: const Text(
                        'ĐỌC THỬ',
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BookBackground extends StatelessWidget {
  const _BookBackground({required this.book});

  final BookDetailData book;

  @override
  Widget build(BuildContext context) {
    if (book.imageUrl.isNotEmpty) {
      return Image.network(
        book.imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _GeneratedCover(book: book),
      );
    }
    return _GeneratedCover(book: book);
  }
}

class _MiniBookCover extends StatelessWidget {
  const _MiniBookCover({required this.book, required this.width});

  final BookDetailData book;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: width * 1.42,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(7),
        boxShadow: const [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: book.imageUrl.isEmpty
          ? _GeneratedCover(book: book)
          : Image.network(
              book.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _GeneratedCover(book: book),
            ),
    );
  }
}

class _GeneratedCover extends StatelessWidget {
  const _GeneratedCover({required this.book});

  final BookDetailData book;

  @override
  Widget build(BuildContext context) {
    final isCreditBook = book.title.toLowerCase().contains('điểm số quyền lực');
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isCreditBook
              ? const [Color(0xFFF1EDE2), Color(0xFFB90000)]
              : book.colors,
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (isCreditBook) ...[
            Positioned(
              left: -25,
              right: -25,
              bottom: -20,
              child: Transform.rotate(
                angle: -0.24,
                child: Container(height: 105, color: const Color(0xFFB60000)),
              ),
            ),
            const Positioned(
              top: 16,
              left: 12,
              right: 12,
              child: Text(
                'MARCUS PHUNG',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF8B1515),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.6,
                ),
              ),
            ),
          ],
          Center(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    book.icon,
                    color: isCreditBook
                        ? const Color(0xFFB00000)
                        : Colors.white,
                    size: 44,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    book.title.toUpperCase(),
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isCreditBook
                          ? const Color(0xFFFFE96A)
                          : Colors.white,
                      fontSize: 20,
                      height: 1.06,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Positioned(top: 0, right: 0, child: _MemberCornerBadge()),
        ],
      ),
    );
  }
}

class _MemberCornerBadge extends StatelessWidget {
  const _MemberCornerBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
      decoration: const BoxDecoration(
        color: Color(0xFFFFA914),
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(8)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'HỘI VIÊN',
            style: TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(width: 3),
          Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 11),
        ],
      ),
    );
  }
}

class _AccessCard extends StatelessWidget {
  const _AccessCard({required this.book});

  final BookDetailData book;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.24),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white38),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Mua lẻ sách hoặc trở thành Hội viên để đọc trọn cuốn sách này',
            textAlign: TextAlign.center,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Colors.white, fontSize: 13, height: 1.25),
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: () {},
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            child: const Text(
              'NÂNG CẤP',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(height: 7),
          Text(
            book.price,
            style: const TextStyle(
              color: Color(0xFFFF59C7),
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(99),
            ),
            child: const Text(
              'MUA SÁCH',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BookStats extends StatelessWidget {
  const _BookStats({required this.onMore});

  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.star_rounded, color: WakaColors.gold, size: 24),
        const SizedBox(width: 5),
        const Text(
          '5.0/5',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
        const SizedBox(width: 28),
        const Icon(Icons.visibility_outlined, color: Colors.white, size: 23),
        const SizedBox(width: 5),
        const Text('99', style: TextStyle(color: Colors.white, fontSize: 18)),
        const Spacer(),
        _RoundAction(icon: Icons.card_giftcard_rounded, onTap: () {}),
        const SizedBox(width: 8),
        _RoundAction(icon: Icons.download_rounded, onTap: () {}),
        const SizedBox(width: 8),
        _RoundAction(icon: Icons.more_vert_rounded, onTap: onMore),
      ],
    );
  }
}

class _RoundAction extends StatelessWidget {
  const _RoundAction({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      radius: 25,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, color: Colors.white, size: 27),
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 26,
        height: 1.15,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 9),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: Colors.white38),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 15),
      ),
    );
  }
}

class _InsideBookAccordion extends StatelessWidget {
  const _InsideBookAccordion({required this.book});

  final BookDetailData book;

  @override
  Widget build(BuildContext context) {
    final title = book.title;
    final items = [
      ('$title là sách gì?', book.resolvedDescription),
      (
        'Cuốn sách $title nói về điều gì?',
        'Nội dung đi từ nền tảng đến các tình huống thực tế, giúp người đọc hiểu vấn đề theo từng bước rõ ràng.',
      ),
      (
        'Đọc $title sẽ học được gì?',
        'Bạn sẽ biết cách quan sát dữ liệu, đặt câu hỏi đúng và biến kiến thức thành những lựa chọn chủ động hơn.',
      ),
      (
        'Ai nên đọc $title?',
        'Cuốn sách phù hợp với người mới bắt đầu và những ai muốn hệ thống lại kiến thức theo cách dễ áp dụng.',
      ),
      (
        'Điểm khác biệt của $title là gì?',
        'Các khái niệm được giải thích bằng ví dụ gần gũi, hạn chế thuật ngữ và tập trung vào hành động cụ thể.',
      ),
      (
        'Thông điệp chính của sách là gì?',
        'Hiểu rõ cách một hệ thống vận hành sẽ giúp chúng ta đưa ra quyết định tốt hơn và bảo vệ tương lai của mình.',
      ),
      (
        'Trích dẫn nổi bật trong sách là gì?',
        'Kiến thức chỉ thật sự có giá trị khi nó giúp bạn thay đổi một quyết định trong đời sống.',
      ),
    ];
    return Column(
      children: List.generate(
        items.length,
        (index) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Material(
            color: const Color(0xFF1B1B1D),
            borderRadius: BorderRadius.circular(12),
            clipBehavior: Clip.antiAlias,
            child: Theme(
              data: Theme.of(
                context,
              ).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                iconColor: WakaColors.accent,
                collapsedIconColor: Colors.white,
                title: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 34,
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          color: index == 0 ? WakaColors.accent : Colors.white,
                          fontSize: 23,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        items[index].$1,
                        style: TextStyle(
                          color: index == 0 ? WakaColors.accent : Colors.white,
                          fontSize: 18,
                          height: 1.2,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                children: [
                  Text(
                    items[index].$2,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      height: 1.55,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RelatedBooks extends StatelessWidget {
  const _RelatedBooks({required this.book, required this.onOpen});

  final BookDetailData book;
  final ValueChanged<BookDetailData> onOpen;

  @override
  Widget build(BuildContext context) {
    final books = [
      BookDetailData(
        title: 'Sổ tay tài chính gia đình',
        author: book.author,
        colors: const [Color(0xFFFF5A13), Color(0xFFB40000)],
        icon: Icons.savings_outlined,
        section: 'Tài chính cá nhân',
      ),
      BookDetailData(
        title: 'Thoát nợ sống nhẹ',
        author: book.author,
        colors: const [Color(0xFFFFD400), Color(0xFF181818)],
        icon: Icons.balance_rounded,
        section: 'Tài chính cá nhân',
      ),
      BookDetailData(
        title: 'Dám kiếm tiền, dám đầu tư',
        author: book.author,
        colors: const [Color(0xFF0B315B), Color(0xFFFFB217)],
        icon: Icons.trending_up_rounded,
        section: 'Phát triển cá nhân',
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cùng tác giả ${book.author}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 260,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: books.length,
            separatorBuilder: (_, _) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final related = books[index];
              return GestureDetector(
                onTap: () => onOpen(related),
                child: SizedBox(
                  width: 135,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _MiniBookCover(book: related, width: 135),
                      const SizedBox(height: 9),
                      Text(
                        related.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
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
    );
  }
}

class _ReaderReviewEmpty extends StatelessWidget {
  const _ReaderReviewEmpty();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeading('Độc giả đánh giá'),
        SizedBox(height: 30),
        Center(
          child: Column(
            children: [
              Icon(Icons.auto_awesome_rounded, color: Colors.white30, size: 76),
              SizedBox(height: 12),
              Text(
                'Chưa có đánh giá nào',
                style: TextStyle(color: Colors.white54, fontSize: 17),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MemberOfferBanner extends StatelessWidget {
  const _MemberOfferBanner({required this.onClose, required this.onBuy});

  final VoidCallback onClose;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 12, 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF8212), Color(0xFFFF1717), Color(0xFFCB003B)],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'ƯU ĐÃI HỘI VIÊN',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              InkResponse(
                onTap: onClose,
                child: const Icon(
                  Icons.close_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF171717),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Text.rich(
                    TextSpan(
                      text: 'WAKA 12 THÁNG\n',
                      style: TextStyle(
                        color: WakaColors.accent,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                      children: [
                        TextSpan(
                          text: '499.000đ',
                          style: TextStyle(color: Color(0xFFFFFF29)),
                        ),
                      ],
                    ),
                  ),
                ),
                FilledButton(
                  onPressed: onBuy,
                  style: FilledButton.styleFrom(
                    backgroundColor: WakaColors.accent,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text(
                    'MUA NGAY',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.card_giftcard_rounded, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text(
                'Tặng thêm 02 tháng',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: Colors.white, size: 30),
      title: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 19),
      ),
      trailing: trailing,
    );
  }
}

class _MemberPill extends StatelessWidget {
  const _MemberPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFB600), Color(0xFFFF4B25)],
        ),
        borderRadius: BorderRadius.circular(99),
      ),
      child: const Text(
        'HỘI VIÊN',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
      ),
    );
  }
}
