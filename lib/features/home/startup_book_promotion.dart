import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../core/services/local_banners_service.dart';
import '../../core/services/waka_api_store.dart';
import '../../core/services/waka_scraper_service.dart';
import '../../core/theme/app_theme.dart';
import '../reader/book_detail_screen.dart';

Future<void> showStartupBookPromotion(BuildContext context) async {
  final results = await Future.wait([
    const LocalBannersService().loadHomeBanners(),
    WakaApiStore().getAllBooks(maxPagesPerCategory: 1),
  ]);
  final banners = results[0] as List<WakaHomeBanner>;
  final books = results[1] as List<WakaScrapedBook>;
  if (!context.mounted || banners.isEmpty || books.isEmpty) return;

  const storage = FlutterSecureStorage();
  final previousId = await storage.read(key: 'last_startup_promotion_id');
  final candidates = banners.length > 1
      ? banners.where((item) => item.id != previousId).toList()
      : banners;
  final banner =
      candidates[DateTime.now().millisecondsSinceEpoch % candidates.length];
  await storage.write(key: 'last_startup_promotion_id', value: banner.id);

  final eligibleBooks = books
      .where((item) => item.imageUrl.trim().isNotEmpty && item.id > 0)
      .toList();
  final book = eligibleBooks.isNotEmpty
      ? eligibleBooks[banners.indexOf(banner) % eligibleBooks.length]
      : books.firstWhere(
          (item) => item.imageUrl.trim().isNotEmpty && item.id > 0,
          orElse: () => books.firstWhere(
            (item) => item.imageUrl.trim().isNotEmpty,
            orElse: () => books.first,
          ),
        );

  if (!context.mounted) return;

  final shouldOpen = await showGeneralDialog<bool>(
    context: context,
    barrierDismissible: false,
    barrierLabel: 'Sách nổi bật',
    barrierColor: Colors.black.withValues(alpha: 0.84),
    transitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (dialogContext, animation, secondaryAnimation) =>
        _StartupBookPromotionDialog(banner: banner),
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutBack,
        reverseCurve: Curves.easeIn,
      );
      return FadeTransition(
        opacity: animation,
        child: ScaleTransition(scale: curved, child: child),
      );
    },
  );

  if (shouldOpen != true || !context.mounted) return;
  await Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => BookDetailScreen(book: _detailData(book)),
    ),
  );
}

BookDetailData _detailData(WakaScrapedBook book) => BookDetailData(
  bookId: book.id,
  title: book.title,
  author: 'Waka Books',
  imageUrl: book.imageUrl,
  sourceUrl: book.url,
  price: book.price > 0 ? '${book.price}đ' : '99.000đ',
  section: book.section.isEmpty ? 'Sách điện tử' : book.section,
  colors: const [Color(0xFFEEE9D9), Color(0xFF173B45)],
  icon: Icons.auto_stories_rounded,
);

class _StartupBookPromotionDialog extends StatelessWidget {
  const _StartupBookPromotionDialog({required this.banner});

  final WakaHomeBanner banner;

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    final cardWidth = (screen.width - 115).clamp(235.0, 310.0);
    final imageHeight = (cardWidth * 1.46).clamp(345.0, 455.0);
    return PopScope(
      canPop: false,
      child: Material(
        type: MaterialType.transparency,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 18),
              child: SizedBox(
                width: cardWidth,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      key: const ValueKey('startup-promotion-open'),
                      onTap: () => Navigator.pop(context, true),
                      child: Container(
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          color: const Color(0xFF242A3A),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black54,
                              blurRadius: 26,
                              offset: Offset(0, 13),
                            ),
                          ],
                        ),
                        child: SizedBox(
                          height: imageHeight,
                          width: double.infinity,
                          child: Image.network(
                            banner.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => const Center(
                              child: Icon(
                                Icons.campaign_rounded,
                                color: WakaColors.accent,
                                size: 72,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    IconButton.filled(
                      key: const ValueKey('startup-promotion-close'),
                      onPressed: () => Navigator.pop(context, false),
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFF343438),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(50, 50),
                      ),
                      icon: const Icon(Icons.close_rounded, size: 29),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
