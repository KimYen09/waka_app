import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_theme.dart';
import 'book_detail_screen.dart';

enum _ReaderPalette { light, sepia, dark }

enum _ReaderPageKind { cover, contents, chapter, text, previewEnd }

class ReaderScreen extends StatefulWidget {
  const ReaderScreen({super.key, required this.book});

  final BookDetailData book;

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen>
    with SingleTickerProviderStateMixin {
  late final PageController _pageController;
  late final AnimationController _openingController;
  late final Animation<double> _openingProgress;

  bool _isOpening = true;
  bool _showControls = false;
  bool _isBookmarked = false;
  int _currentPage = 0;
  double _fontSize = 20;
  double _lineHeight = 1.65;
  _ReaderPalette _palette = _ReaderPalette.light;

  List<_ReaderChapter> get _chapters => _sampleChapters(widget.book);
  List<_ReaderPageData> get _pages => _buildReaderPages(_chapters);

  double get _progress {
    if (_pages.length <= 1) return 0;
    return _currentPage / (_pages.length - 1);
  }

  Color get _backgroundColor => switch (_palette) {
    _ReaderPalette.light => const Color(0xFFF5F7F8),
    _ReaderPalette.sepia => const Color(0xFFF2E7CF),
    _ReaderPalette.dark => const Color(0xFF111214),
  };

  Color get _textColor => switch (_palette) {
    _ReaderPalette.light => const Color(0xFF25313E),
    _ReaderPalette.sepia => const Color(0xFF342D25),
    _ReaderPalette.dark => const Color(0xFFE7E7E7),
  };

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _openingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2300),
    );
    _openingProgress = CurvedAnimation(
      parent: _openingController,
      curve: Curves.easeInOutCubic,
    );
    _openingController.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() {
          _isOpening = false;
          _showControls = false;
        });
      }
    });
    _openingController.forward();
  }

  @override
  void dispose() {
    _openingController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _seek(double value) {
    final index = (value * (_pages.length - 1)).round();
    _goToPage(index);
  }

  void _goToPage(int index) {
    final safeIndex = index.clamp(0, _pages.length - 1);
    _pageController.animateToPage(
      safeIndex,
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
    );
  }

  int _pageForChapter(int chapterIndex) {
    final index = _pages.indexWhere(
      (page) => page.chapterIndex == chapterIndex,
    );
    return index < 0 ? 0 : index;
  }

  void _showTableOfContents() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF222327),
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.72,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 8, 22, 18),
                  child: Text(
                    widget.book.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const Divider(color: Colors.white12, height: 1),
                ListTile(
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _pageController.jumpToPage(0);
                  },
                  contentPadding: const EdgeInsets.symmetric(horizontal: 22),
                  leading: const Icon(
                    Icons.menu_book_rounded,
                    color: Colors.white54,
                  ),
                  title: const Text(
                    'Bìa sách và mục lục',
                    style: TextStyle(color: Colors.white, fontSize: 17),
                  ),
                ),
                const Divider(color: Colors.white12, height: 1),
                Expanded(
                  child: ListView.separated(
                    itemCount: _chapters.length,
                    separatorBuilder: (_, _) => const Divider(
                      color: Colors.white10,
                      height: 1,
                      indent: 22,
                    ),
                    itemBuilder: (context, index) {
                      final targetPage = _pageForChapter(index);
                      final active = _pages[_currentPage].chapterIndex == index;
                      return ListTile(
                        onTap: () {
                          Navigator.pop(sheetContext);
                          _pageController.animateToPage(
                            targetPage,
                            duration: const Duration(milliseconds: 380),
                            curve: Curves.easeOutCubic,
                          );
                        },
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 22,
                          vertical: 7,
                        ),
                        leading: SizedBox(
                          width: 28,
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              color: active
                                  ? WakaColors.accent
                                  : Colors.white54,
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        title: Text(
                          _chapters[index].title,
                          style: TextStyle(
                            color: active ? WakaColors.accent : Colors.white,
                            fontSize: 17,
                            fontWeight: active
                                ? FontWeight.w800
                                : FontWeight.w500,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Giữ nguyên phần tùy chỉnh cỡ chữ, màu giấy và giãn dòng.
  void _showReaderSettings() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF222327),
      showDragHandle: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            void update(VoidCallback callback) {
              setState(callback);
              setSheetState(() {});
            }

            return SafeArea(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(22, 8, 22, 28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tùy chỉnh hiển thị',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          const Text(
                            'Cỡ chữ',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                          const Spacer(),
                          IconButton.filledTonal(
                            onPressed: _fontSize <= 16
                                ? null
                                : () => update(() => _fontSize -= 1),
                            icon: const Icon(Icons.remove_rounded),
                          ),
                          SizedBox(
                            width: 54,
                            child: Text(
                              '${_fontSize.round()}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          IconButton.filledTonal(
                            onPressed: _fontSize >= 30
                                ? null
                                : () => update(() => _fontSize += 1),
                            icon: const Icon(Icons.add_rounded),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Màu nền',
                        style: TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _PaletteButton(
                            label: 'Sáng',
                            color: const Color(0xFFFAFAF8),
                            selected: _palette == _ReaderPalette.light,
                            onTap: () =>
                                update(() => _palette = _ReaderPalette.light),
                          ),
                          const SizedBox(width: 12),
                          _PaletteButton(
                            label: 'Giấy',
                            color: const Color(0xFFF2E7CF),
                            selected: _palette == _ReaderPalette.sepia,
                            onTap: () =>
                                update(() => _palette = _ReaderPalette.sepia),
                          ),
                          const SizedBox(width: 12),
                          _PaletteButton(
                            label: 'Tối',
                            color: const Color(0xFF111214),
                            selected: _palette == _ReaderPalette.dark,
                            onTap: () =>
                                update(() => _palette = _ReaderPalette.dark),
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      const Text(
                        'Giãn dòng',
                        style: TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                      Slider(
                        value: _lineHeight,
                        min: 1.3,
                        max: 2.0,
                        divisions: 7,
                        activeColor: WakaColors.accent,
                        onChanged: (value) => update(() => _lineHeight = value),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isOpening) {
      return _ReaderOpeningView(
        book: widget.book,
        progress: _openingProgress,
        onClose: () => Navigator.of(context).pop(),
      );
    }

    final overlayStyle = _palette == _ReaderPalette.dark
        ? SystemUiOverlayStyle.light
        : SystemUiOverlayStyle.dark;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: Scaffold(
        backgroundColor: _backgroundColor,
        body: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => setState(() => _showControls = !_showControls),
          child: Stack(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                color: _backgroundColor,
                child: SafeArea(
                  child: PageView.builder(
                    controller: _pageController,
                    physics: const PageScrollPhysics(),
                    itemCount: _pages.length,
                    onPageChanged: (index) {
                      setState(() {
                        _currentPage = index;
                        _showControls = false;
                      });
                    },
                    itemBuilder: (context, index) {
                      return _ZoomableReaderPage(
                        key: ValueKey('reader-page-$index'),
                        backgroundColor: _backgroundColor,
                        child: _ReaderPage(
                          page: _pages[index],
                          book: widget.book,
                          chapters: _chapters,
                          textColor: _textColor,
                          fontSize: _fontSize,
                          lineHeight: _lineHeight,
                        ),
                      );
                    },
                  ),
                ),
              ),
              AnimatedPositioned(
                duration: const Duration(milliseconds: 220),
                left: 0,
                right: 0,
                top: _showControls ? 0 : -100,
                child: _ReaderTopBar(
                  title: widget.book.title,
                  isBookmarked: _isBookmarked,
                  onBack: () => Navigator.of(context).pop(),
                  onBookmark: () =>
                      setState(() => _isBookmarked = !_isBookmarked),
                  onSettings: _showReaderSettings,
                ),
              ),
              AnimatedPositioned(
                duration: const Duration(milliseconds: 220),
                left: 0,
                right: 0,
                bottom: _showControls ? 0 : -120,
                child: _ReaderBottomBar(
                  currentPage: _currentPage,
                  pageCount: _pages.length,
                  progress: _progress,
                  onProgressChanged: _seek,
                  onContents: _showTableOfContents,
                  onSettings: _showReaderSettings,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReaderOpeningView extends StatelessWidget {
  const _ReaderOpeningView({
    required this.book,
    required this.progress,
    required this.onClose,
  });

  final BookDetailData book;
  final Animation<double> progress;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFF07152B),
        body: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0, -0.25),
              radius: 1.1,
              colors: [Color(0xFF173861), Color(0xFF07152B)],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: AnimatedBuilder(
                animation: progress,
                builder: (context, _) {
                  final percent = (progress.value * 100).round();
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 145,
                        height: 205,
                        child: _ReaderBookCover(book: book),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        '$percent %',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: 145,
                        child: LinearProgressIndicator(
                          value: progress.value,
                          minHeight: 4,
                          color: WakaColors.accent,
                          backgroundColor: Colors.white30,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Đang mở sách',
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
                      const SizedBox(height: 28),
                      OutlinedButton(
                        onPressed: onClose,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(
                            color: Colors.white,
                            width: 1.4,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 28,
                            vertical: 12,
                          ),
                          shape: const StadiumBorder(),
                        ),
                        child: const Text(
                          'ĐÓNG',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ZoomableReaderPage extends StatefulWidget {
  const _ZoomableReaderPage({
    super.key,
    required this.backgroundColor,
    required this.child,
  });

  final Color backgroundColor;
  final Widget child;

  @override
  State<_ZoomableReaderPage> createState() => _ZoomableReaderPageState();
}

class _ZoomableReaderPageState extends State<_ZoomableReaderPage> {
  late final TransformationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TransformationController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: widget.backgroundColor,
      child: InteractiveViewer(
        transformationController: _controller,
        minScale: 1,
        maxScale: 3.5,
        boundaryMargin: const EdgeInsets.all(80),
        clipBehavior: Clip.none,
        child: SizedBox.expand(child: widget.child),
      ),
    );
  }
}

class _ReaderPage extends StatelessWidget {
  const _ReaderPage({
    required this.page,
    required this.book,
    required this.chapters,
    required this.textColor,
    required this.fontSize,
    required this.lineHeight,
  });

  final _ReaderPageData page;
  final BookDetailData book;
  final List<_ReaderChapter> chapters;
  final Color textColor;
  final double fontSize;
  final double lineHeight;

  TextStyle get _bodyStyle => TextStyle(
    color: textColor,
    fontSize: fontSize,
    height: lineHeight,
    fontWeight: FontWeight.w400,
    fontFamily: 'serif',
    fontFamilyFallback: const ['Noto Serif', 'Roboto Serif'],
  );

  @override
  Widget build(BuildContext context) {
    return switch (page.kind) {
      _ReaderPageKind.cover => _CoverPage(book: book),
      _ReaderPageKind.contents => _ContentsPage(
        chapters: chapters,
        textColor: textColor,
        fontSize: fontSize,
      ),
      _ReaderPageKind.chapter => _ChapterPage(
        page: page,
        textColor: textColor,
        bodyStyle: _bodyStyle,
      ),
      _ReaderPageKind.text => _TextPage(
        text: page.text,
        textColor: textColor,
        bodyStyle: _bodyStyle,
      ),
      _ReaderPageKind.previewEnd => _PreviewEndPage(
        textColor: textColor,
        fontSize: fontSize,
      ),
    };
  }
}

class _CoverPage extends StatelessWidget {
  const _CoverPage({required this.book});

  final BookDetailData book;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(34, 20, 34, 26),
      child: Center(
        child: AspectRatio(
          aspectRatio: 0.68,
          child: _ReaderBookCover(book: book),
        ),
      ),
    );
  }
}

class _ReaderBookCover extends StatelessWidget {
  const _ReaderBookCover({required this.book});

  final BookDetailData book;

  @override
  Widget build(BuildContext context) {
    if (book.imageUrl.isNotEmpty) {
      return Image.network(
        book.imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _GeneratedReaderCover(book: book),
      );
    }
    return _GeneratedReaderCover(book: book);
  }
}

class _GeneratedReaderCover extends StatelessWidget {
  const _GeneratedReaderCover({required this.book});

  final BookDetailData book;

  @override
  Widget build(BuildContext context) {
    final isCreditBook = book.title.toLowerCase().contains('điểm số quyền lực');
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxHeight < 300;
        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isCreditBook
                  ? const [Color(0xFFF4F0E8), Color(0xFFB60000)]
                  : book.colors,
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (isCreditBook)
                Positioned(
                  left: -40,
                  right: -40,
                  bottom: compact ? 5 : 20,
                  child: Transform.rotate(
                    angle: -0.22,
                    child: Container(
                      height: compact ? 70 : 150,
                      color: const Color(0xFFB40000),
                    ),
                  ),
                ),
              Padding(
                padding: EdgeInsets.all(compact ? 10 : 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      book.icon,
                      color: isCreditBook
                          ? const Color(0xFFB00000)
                          : Colors.white,
                      size: compact ? 30 : 62,
                    ),
                    SizedBox(height: compact ? 7 : 18),
                    Text(
                      book.title.toUpperCase(),
                      maxLines: compact ? 3 : 5,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isCreditBook
                            ? const Color(0xFFFFE963)
                            : Colors.white,
                        fontSize: compact ? 15 : 27,
                        height: 1.05,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: compact ? 7 : 16),
                    Text(
                      book.author,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isCreditBook ? Colors.white : Colors.white70,
                        fontSize: compact ? 10 : 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ContentsPage extends StatelessWidget {
  const _ContentsPage({
    required this.chapters,
    required this.textColor,
    required this.fontSize,
  });

  final List<_ReaderChapter> chapters;
  final Color textColor;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(48, 42, 38, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mục lục',
            style: TextStyle(
              color: textColor,
              fontSize: fontSize + 14,
              fontFamily: 'serif',
              fontStyle: FontStyle.italic,
              height: 1,
            ),
          ),
          const SizedBox(height: 32),
          ...List.generate(
            chapters.length,
            (index) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                'Chương ${index + 1}.  ${chapters[index].title}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: textColor,
                  fontSize: fontSize + 1,
                  fontFamily: 'serif',
                  fontFamilyFallback: const ['Noto Serif'],
                  height: 1.25,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChapterPage extends StatelessWidget {
  const _ChapterPage({
    required this.page,
    required this.textColor,
    required this.bodyStyle,
  });

  final _ReaderPageData page;
  final Color textColor;
  final TextStyle bodyStyle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(45, 40, 38, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.center,
            child: Text(
              '${(page.chapterIndex ?? 0) + 1}.',
              style: TextStyle(
                color: textColor,
                fontSize: bodyStyle.fontSize! + 9,
                fontFamily: 'serif',
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.center,
            child: Text(
              '➜➜➜➜➜➜➜➜',
              style: TextStyle(
                color: textColor.withValues(alpha: 0.48),
                fontSize: 13,
                letterSpacing: -1,
              ),
            ),
          ),
          const SizedBox(height: 28),
          Text(
            page.title,
            style: TextStyle(
              color: textColor,
              fontSize: bodyStyle.fontSize! + 7,
              height: 1.15,
              fontFamily: 'serif',
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              child: Text(
                page.text,
                textAlign: TextAlign.justify,
                style: bodyStyle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TextPage extends StatelessWidget {
  const _TextPage({
    required this.text,
    required this.textColor,
    required this.bodyStyle,
  });

  final String text;
  final Color textColor;
  final TextStyle bodyStyle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(45, 46, 38, 34),
      child: Text(
        text,
        textAlign: TextAlign.justify,
        style: bodyStyle.copyWith(color: textColor),
      ),
    );
  }
}

class _PreviewEndPage extends StatelessWidget {
  const _PreviewEndPage({required this.textColor, required this.fontSize});

  final Color textColor;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_outline_rounded, color: textColor, size: 48),
            const SizedBox(height: 18),
            Text(
              'Bạn đã đọc hết nội dung xem trước',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: textColor,
                fontSize: fontSize + 2,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Mua sách hoặc nâng cấp Hội viên để đọc tiếp.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: textColor.withValues(alpha: 0.7),
                fontSize: fontSize - 2,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReaderTopBar extends StatelessWidget {
  const _ReaderTopBar({
    required this.title,
    required this.isBookmarked,
    required this.onBack,
    required this.onBookmark,
    required this.onSettings,
  });

  final String title;
  final bool isBookmarked;
  final VoidCallback onBack;
  final VoidCallback onBookmark;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xF51B1C1F),
      elevation: 8,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              IconButton(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              ),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              IconButton(
                onPressed: onBookmark,
                icon: Icon(
                  isBookmarked
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_border_rounded,
                  color: isBookmarked ? WakaColors.gold : Colors.white,
                ),
              ),
              IconButton(
                onPressed: onSettings,
                icon: const Icon(
                  Icons.text_fields_rounded,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 4),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReaderBottomBar extends StatelessWidget {
  const _ReaderBottomBar({
    required this.currentPage,
    required this.pageCount,
    required this.progress,
    required this.onProgressChanged,
    required this.onContents,
    required this.onSettings,
  });

  final int currentPage;
  final int pageCount;
  final double progress;
  final ValueChanged<double> onProgressChanged;
  final VoidCallback onContents;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xF51B1C1F),
      elevation: 12,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 6, 14, 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text(
                    '${currentPage + 1}/$pageCount',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Expanded(
                    child: Slider(
                      value: progress,
                      activeColor: WakaColors.accent,
                      inactiveColor: Colors.white24,
                      onChanged: onProgressChanged,
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  TextButton.icon(
                    onPressed: onContents,
                    icon: const Icon(Icons.format_list_bulleted_rounded),
                    label: const Text('Mục lục'),
                    style: TextButton.styleFrom(foregroundColor: Colors.white),
                  ),
                  TextButton.icon(
                    onPressed: onSettings,
                    icon: const Icon(Icons.tune_rounded),
                    label: const Text('Hiển thị'),
                    style: TextButton.styleFrom(foregroundColor: Colors.white),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaletteButton extends StatelessWidget {
  const _PaletteButton({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? WakaColors.accent : Colors.white24,
              width: selected ? 3 : 1,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: color.computeLuminance() > 0.5
                  ? Colors.black
                  : Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _ReaderPageData {
  const _ReaderPageData({
    required this.kind,
    this.title = '',
    this.text = '',
    this.chapterIndex,
  });

  final _ReaderPageKind kind;
  final String title;
  final String text;
  final int? chapterIndex;
}

class _ReaderChapter {
  const _ReaderChapter({required this.title, required this.paragraphs});

  final String title;
  final List<String> paragraphs;
}

List<_ReaderPageData> _buildReaderPages(List<_ReaderChapter> chapters) {
  final pages = <_ReaderPageData>[
    const _ReaderPageData(kind: _ReaderPageKind.cover),
    const _ReaderPageData(kind: _ReaderPageKind.contents),
  ];
  for (var chapterIndex = 0; chapterIndex < chapters.length; chapterIndex++) {
    final chapter = chapters[chapterIndex];
    for (
      var paragraphIndex = 0;
      paragraphIndex < chapter.paragraphs.length;
      paragraphIndex++
    ) {
      pages.add(
        _ReaderPageData(
          kind: paragraphIndex == 0
              ? _ReaderPageKind.chapter
              : _ReaderPageKind.text,
          chapterIndex: chapterIndex,
          title: chapter.title,
          text: chapter.paragraphs[paragraphIndex],
        ),
      );
    }
  }
  pages.add(const _ReaderPageData(kind: _ReaderPageKind.previewEnd));
  return pages;
}

List<_ReaderChapter> _sampleChapters(BookDetailData book) {
  final isCreditBook = book.title.toLowerCase().contains('điểm số quyền lực');
  if (!isCreditBook) {
    return [
      _ReaderChapter(
        title: 'Mở đầu',
        paragraphs: [
          '${book.title} bắt đầu từ một câu hỏi đơn giản: điều gì sẽ thay đổi '
              'nếu chúng ta nhìn vấn đề quen thuộc bằng một góc nhìn khác? Nội '
              'dung xem trước này được biên soạn riêng cho Waka Demo và không '
              'phải nội dung nguyên bản của tác phẩm.',
          'Một ý tưởng chỉ trở nên hữu ích khi người đọc có thể liên hệ nó với '
              'một tình huống thực tế. Hãy bắt đầu từ những thay đổi nhỏ, đo '
              'lường kết quả và điều chỉnh theo điều mình học được.',
        ],
      ),
      const _ReaderChapter(
        title: 'Từ hiểu biết đến hành động',
        paragraphs: [
          'Thói quen ghi chú, đặt câu hỏi và xem lại quyết định giúp kiến thức '
              'không dừng ở trang sách mà đi vào đời sống hằng ngày. Mỗi trang '
              'đọc là một cơ hội để dừng lại và suy nghĩ kỹ hơn.',
          'Khi một bài học được lặp lại bằng hành động, nó dần trở thành kinh '
              'nghiệm. Đó là lúc giá trị của việc đọc được thể hiện rõ nhất.',
        ],
      ),
    ];
  }

  return const [
    _ReaderChapter(
      title: 'Một con số vô hình',
      paragraphs: [
        'Trong đời sống tài chính hiện đại, nhiều quyết định được hỗ trợ bởi dữ '
            'liệu. Một hồ sơ tín dụng không kể toàn bộ câu chuyện về một con '
            'người, nhưng nó có thể cho tổ chức cho vay thấy cách các cam kết '
            'tài chính đã được thực hiện trong quá khứ.',
        'Điểm số không xuất hiện từ một giao dịch duy nhất. Nó được hình thành '
            'từ nhiều dấu vết nhỏ: lịch sử thanh toán, khoản vay đang có, thời '
            'gian sử dụng tín dụng và mức độ ổn định của hồ sơ.',
        'Hiểu được điều này giúp chúng ta bớt xem điểm số như một phán quyết. '
            'Nó là tín hiệu có thể quan sát, giải thích và cải thiện bằng những '
            'lựa chọn có kỷ luật.',
      ],
    ),
    _ReaderChapter(
      title: 'Dữ liệu kể câu chuyện gì?',
      paragraphs: [
        'Một lần thanh toán đúng hạn có vẻ rất nhỏ, nhưng chuỗi hành vi ổn định '
            'qua nhiều tháng lại tạo ra thông tin đáng tin cậy. Ngược lại, việc '
            'trễ hạn lặp lại cho thấy rủi ro mà bên cho vay cần cân nhắc.',
        'Không phải mọi loại dữ liệu đều có trọng số như nhau. Mỗi hệ thống có '
            'mô hình đánh giá riêng, vì vậy mục tiêu hợp lý không phải là chạy '
            'theo công thức bí mật mà là xây dựng thói quen tài chính lành mạnh.',
        'Người đọc nên kiểm tra thông tin cá nhân định kỳ, nhận diện sai sót và '
            'chủ động cập nhật khi có dữ liệu chưa chính xác. Một hồ sơ đúng là '
            'điều kiện đầu tiên để việc đánh giá trở nên công bằng.',
      ],
    ),
    _ReaderChapter(
      title: 'Xây dựng hồ sơ bền vững',
      paragraphs: [
        'Bước đầu tiên là lập lịch cho các nghĩa vụ thanh toán và duy trì một '
            'khoản dự phòng. Hệ thống nhắc việc đơn giản thường hiệu quả hơn '
            'những kế hoạch quá phức tạp nhưng khó thực hiện lâu dài.',
        'Bước tiếp theo là cân nhắc khả năng chi trả trước khi mở thêm nghĩa vụ '
            'mới. Khả năng vay không đồng nghĩa với việc khoản vay đó phù hợp '
            'với mục tiêu và dòng tiền của bạn.',
        'Cuối cùng, hãy xem lịch sử tín dụng như một phần của sức khỏe tài '
            'chính. Nó cần thời gian, sự đều đặn và những quyết định có chủ '
            'đích, chứ không có đường tắt giúp thay đổi chỉ sau một đêm.',
      ],
    ),
  ];
}
