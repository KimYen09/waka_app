import 'package:flutter/material.dart';

import '../../core/services/book_reviews_service.dart';
import '../../core/services/rest_api_client.dart';
import '../../core/theme/app_theme.dart';

class BookReviewsPreview extends StatefulWidget {
  const BookReviewsPreview({
    super.key,
    required this.bookId,
    required this.bookTitle,
  });
  final int bookId;
  final String bookTitle;
  @override
  State<BookReviewsPreview> createState() => _BookReviewsPreviewState();
}

class _BookReviewsPreviewState extends State<BookReviewsPreview> {
  static const _service = BookReviewsService();
  BookReviewSummary? _summary;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (widget.bookId <= 0) return;
    try {
      final value = await _service.getReviews(widget.bookId);
      if (mounted) setState(() => _summary = value);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final summary =
        _summary ??
        const BookReviewSummary(averageRating: 0, reviewCount: 0, reviews: []);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Độc giả đánh giá',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 18),
        _Summary(
          summary: summary,
          onReview: () async {
            await showBookReviewComposer(context, widget.bookId);
            await _load();
          },
        ),
        if (summary.reviews.isNotEmpty) ...[
          const SizedBox(height: 16),
          SizedBox(
            height: 190,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: summary.reviews.take(5).length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (_, i) => SizedBox(
                width: 285,
                child: _ReviewCard(review: summary.reviews[i]),
              ),
            ),
          ),
        ],
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: widget.bookId <= 0
                ? null
                : () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BookReviewsScreen(
                        bookId: widget.bookId,
                        bookTitle: widget.bookTitle,
                      ),
                    ),
                  ),
            child: const Text('Xem tất cả đánh giá'),
          ),
        ),
      ],
    );
  }
}

class BookReviewsScreen extends StatefulWidget {
  const BookReviewsScreen({
    super.key,
    required this.bookId,
    required this.bookTitle,
  });
  final int bookId;
  final String bookTitle;
  @override
  State<BookReviewsScreen> createState() => _BookReviewsScreenState();
}

class _BookReviewsScreenState extends State<BookReviewsScreen> {
  static const _service = BookReviewsService();
  BookReviewSummary? _summary;
  String? _error;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final v = await _service.getReviews(widget.bookId);
      if (mounted) {
        setState(() {
          _summary = v;
          _error = null;
        });
      }
    } on RestApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = _summary;
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0E),
      appBar: AppBar(title: const Text('Đánh giá')),
      body: s == null
          ? Center(
              child: _error == null
                  ? const CircularProgressIndicator()
                  : Text(
                      _error!,
                      style: const TextStyle(color: Colors.white70),
                    ),
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text(
                    widget.bookTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white54),
                  ),
                  const SizedBox(height: 20),
                  _Summary(
                    summary: s,
                    onReview: () async {
                      await showBookReviewComposer(context, widget.bookId);
                      await _load();
                    },
                  ),
                  const SizedBox(height: 22),
                  if (s.reviews.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 50),
                      child: Center(
                        child: Text(
                          'Chưa có đánh giá. Hãy là người đầu tiên!',
                          style: TextStyle(color: Colors.white54),
                        ),
                      ),
                    )
                  else
                    for (final r in s.reviews) ...[
                      _ReviewCard(review: r),
                      const SizedBox(height: 12),
                    ],
                ],
              ),
            ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.summary, required this.onReview});
  final BookReviewSummary summary;
  final VoidCallback onReview;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  summary.reviewCount == 0
                      ? '0.0'
                      : summary.averageRating.toStringAsFixed(1),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 38,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(width: 8),
                ...List.generate(
                  5,
                  (i) => Icon(
                    Icons.star_rounded,
                    color: i < summary.averageRating.round()
                        ? Colors.amber
                        : Colors.white24,
                    size: 16,
                  ),
                ),
              ],
            ),
            Text(
              '${summary.reviewCount} đánh giá',
              style: const TextStyle(color: Colors.white54, fontSize: 18),
            ),
          ],
        ),
      ),
      OutlinedButton.icon(
        onPressed: onReview,
        icon: const Icon(Icons.edit_outlined),
        label: const Text('Đánh giá'),
      ),
    ],
  );
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.review});
  final BookReview review;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFF1B1B1E),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              backgroundColor: WakaColors.accent.withValues(alpha: .18),
              child: Icon(
                review.isAnonymous
                    ? Icons.visibility_off_outlined
                    : Icons.person_outline,
                color: WakaColors.accent,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                review.displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Text(
              _date(review.createdAt),
              style: const TextStyle(color: Colors.white54),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: List.generate(
            5,
            (i) => Icon(
              Icons.star_rounded,
              size: 19,
              color: i < review.rating ? Colors.amber : Colors.white24,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          review.comment,
          maxLines: 4,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            height: 1.4,
          ),
        ),
      ],
    ),
  );
}

Future<void> showBookReviewComposer(BuildContext context, int bookId) async {
  if (bookId <= 0) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sách mẫu chưa thể đánh giá.')),
    );
    return;
  }
  var rating = 5;
  var anonymous = false;
  var comment = '';
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: const Color(0xFF202023),
    builder: (sheetContext) => StatefulBuilder(
      builder: (context, setState) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          20 + MediaQuery.viewInsetsOf(context).bottom,
        ),
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
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                5,
                (i) => IconButton(
                  onPressed: () => setState(() => rating = i + 1),
                  icon: Icon(
                    i < rating ? Icons.star_rounded : Icons.star_border_rounded,
                    color: Colors.amber,
                    size: 34,
                  ),
                ),
              ),
            ),
            TextField(
              onChanged: (value) => comment = value,
              maxLength: 1500,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Chia sẻ cảm nhận của bạn...',
              ),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: anonymous,
              onChanged: (v) => setState(() => anonymous = v),
              title: const Text('Bình luận ẩn danh'),
              subtitle: const Text(
                'Tên và tài khoản của bạn không hiển thị với độc giả khác.',
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () async {
                  try {
                    await const BookReviewsService().saveReview(
                      bookId,
                      rating: rating,
                      comment: comment,
                      isAnonymous: anonymous,
                    );
                    if (sheetContext.mounted) {
                      Navigator.pop(sheetContext);
                    }
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Đã gửi đánh giá.')),
                      );
                    }
                  } on RestApiException catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text(e.message)));
                    }
                  }
                },
                child: const Text('GỬI ĐÁNH GIÁ'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

String _date(DateTime? value) => value == null
    ? ''
    : '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
