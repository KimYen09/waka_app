import 'package:flutter/material.dart';

import '../../core/services/local_books_service.dart';
import '../../core/services/waka_scraper_service.dart';
import '../../core/theme/app_theme.dart';
import 'shop_category_screen.dart';
import 'shop_constants.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  final _searchController = TextEditingController();
  final _booksService = const LocalBooksService();
  List<ShopProduct> _shopProducts = const [];
  String _searchText = '';

  List<ShopCategory> get _filteredCategories {
    if (_searchText.isEmpty) return shopCategories;
    return shopCategories
        .where((category) => _matches(category.label, _searchText))
        .toList();
  }

  List<ShopSeller> get _filteredSellers {
    if (_searchText.isEmpty) return shopSellers;
    return shopSellers
        .where(
          (seller) => _matches('${seller.name} ${seller.logo}', _searchText),
        )
        .toList();
  }

  List<ShopProduct> get _filteredTopProducts {
    final products = _topProducts;
    if (_searchText.isEmpty) return products;
    return products.where((product) => _matchesProduct(product)).toList();
  }

  List<ShopProduct> get _filteredSuggestedProducts {
    final products = _suggestedProducts;
    if (_searchText.isEmpty) return products;
    return products.where((product) => _matchesProduct(product)).toList();
  }

  List<ShopProduct> get _topProducts {
    if (_shopProducts.isEmpty) return topProducts;
    return _shopProducts.take(10).toList(growable: false);
  }

  List<ShopProduct> get _suggestedProducts {
    if (_shopProducts.isEmpty) return suggestedProducts;
    return _shopProducts.skip(10).take(24).toList(growable: false);
  }

  bool get _hasResults {
    return _filteredCategories.isNotEmpty ||
        _filteredSellers.isNotEmpty ||
        _filteredTopProducts.isNotEmpty ||
        _filteredSuggestedProducts.isNotEmpty;
  }

  bool _matchesProduct(ShopProduct product) {
    return _matches(
      '${product.title} ${product.price} ${product.oldPrice} '
      '${product.discount} ${product.sold} ${product.url}',
      _searchText,
    );
  }

  @override
  void initState() {
    super.initState();
    _loadShopBooks();
  }

  Future<void> _loadShopBooks() async {
    try {
      final result = await _booksService.loadBooks();
      final products = _mapBooksToShopProducts(result.books);
      if (!mounted || products.isEmpty) return;
      setState(() => _shopProducts = products);
    } on Object {
      // Keep the static fallback products when local data cannot be loaded.
    }
  }

  void _onSearchChanged(String value) {
    setState(() => _searchText = value.trim());
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() => _searchText = '');
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: WakaColors.background,
      child: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: _ShopHeader(
                controller: _searchController,
                hasSearchText: _searchText.isNotEmpty,
                onChanged: _onSearchChanged,
                onClear: _clearSearch,
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 18)),
            if (!_hasResults)
              const SliverToBoxAdapter(child: _EmptySearchResult())
            else ...[
              if (_filteredCategories.isNotEmpty) ...[
                const SliverToBoxAdapter(
                  child: _ShopSectionTitle(
                    title: 'Danh mục',
                    opensCategoryScreen: true,
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 14)),
                SliverToBoxAdapter(
                  child: _CategoryList(categories: _filteredCategories),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 34)),
              ],
              if (_searchText.isEmpty) ...[
                const SliverToBoxAdapter(
                  child: _ShopSectionTitle(title: 'Mã khuyến mại HOT'),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 12)),
                const SliverToBoxAdapter(child: _CouponList()),
                const SliverToBoxAdapter(child: SizedBox(height: 36)),
              ],
              if (_filteredSellers.isNotEmpty) ...[
                const SliverToBoxAdapter(
                  child: _ShopSectionTitle(title: 'Nhà bán nổi bật'),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 14)),
                SliverToBoxAdapter(
                  child: _SellerList(sellers: _filteredSellers),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 38)),
              ],
              if (_filteredTopProducts.isNotEmpty) ...[
                const SliverToBoxAdapter(
                  child: _ShopSectionTitle(title: 'Top bán chạy'),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 12)),
                const SliverToBoxAdapter(child: _ProductFilterChips()),
                const SliverToBoxAdapter(child: SizedBox(height: 12)),
                SliverToBoxAdapter(
                  child: _TopProductList(products: _filteredTopProducts),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 34)),
              ],
              if (_filteredSuggestedProducts.isNotEmpty) ...[
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: ShopLayout.horizontalPadding,
                    ),
                    child: Text(
                      'Sản phẩm gợi ý',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: ShopFontSizes.sectionTitle,
                        fontWeight: FontWeight.w900,
                        height: 1.08,
                      ),
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 16)),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: ShopLayout.horizontalPadding,
                  ),
                  sliver: _SuggestedGrid(products: _filteredSuggestedProducts),
                ),
              ],
            ],
            const SliverToBoxAdapter(child: SizedBox(height: 96)),
          ],
        ),
      ),
    );
  }
}

List<ShopProduct> _mapBooksToShopProducts(List<WakaScrapedBook> books) {
  final seenUrls = <String>{};
  final uniqueBooks = <WakaScrapedBook>[];
  for (final book in books) {
    final key = book.url.isNotEmpty ? book.url : _normalize(book.title);
    if (seenUrls.add(key) && book.imageUrl.isNotEmpty) {
      uniqueBooks.add(book);
    }
  }

  return [
    for (var index = 0; index < uniqueBooks.length; index++)
      _bookToShopProduct(uniqueBooks[index], index),
  ];
}

ShopProduct _bookToShopProduct(WakaScrapedBook book, int index) {
  final basePrice = 99000 + (index % 7) * 20000;
  final discount = [26, 15, 20, 21, 9, 18, 12][index % 7];
  final oldPrice = (basePrice / (1 - discount / 100)).round();

  return ShopProduct(
    title: 'Sách - ${book.title}',
    price: _formatVnd(basePrice),
    oldPrice: _formatVnd(oldPrice),
    discount: '-$discount%',
    sold: index < 10 ? 'Đã bán ${1424 - index * 37}' : '',
    rank: index < 3 ? index + 1 : null,
    colors: _productColorsForTitle(book.title),
    imageUrl: book.imageUrl,
    url: book.url,
  );
}

String _formatVnd(int value) {
  final text = value.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < text.length; i++) {
    final fromEnd = text.length - i;
    buffer.write(text[i]);
    if (fromEnd > 1 && fromEnd % 3 == 1) buffer.write('.');
  }
  return '$bufferđ';
}

List<Color> _productColorsForTitle(String title) {
  final normalized = _normalize(title);
  if (normalized.contains('world cup') || normalized.contains('bong da')) {
    return const [Color(0xFF1B4E8C), Color(0xFF0B1D35)];
  }
  if (normalized.contains('tien') || normalized.contains('dau tu')) {
    return const [Color(0xFFD8A21B), Color(0xFF111111)];
  }
  if (normalized.contains('yeu') || normalized.contains('tinh')) {
    return const [Color(0xFF44204B), Color(0xFFB05CA8)];
  }
  return const [Color(0xFF1D293B), Color(0xFF334155)];
}

bool _matches(String source, String query) {
  return _normalize(source).contains(_normalize(query));
}

String _normalize(String value) {
  return value
      .toLowerCase()
      .replaceAll('\n', ' ')
      .replaceAll(RegExp('[àáạảãâầấậẩẫăằắặẳẵ]'), 'a')
      .replaceAll(RegExp('[èéẹẻẽêềếệểễ]'), 'e')
      .replaceAll(RegExp('[ìíịỉĩ]'), 'i')
      .replaceAll(RegExp('[òóọỏõôồốộổỗơờớợởỡ]'), 'o')
      .replaceAll(RegExp('[ùúụủũưừứựửữ]'), 'u')
      .replaceAll(RegExp('[ỳýỵỷỹ]'), 'y')
      .replaceAll('đ', 'd');
}

class _EmptySearchResult extends StatelessWidget {
  const _EmptySearchResult();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        ShopLayout.horizontalPadding,
        92,
        ShopLayout.horizontalPadding,
        0,
      ),
      child: Column(
        children: const [
          Icon(Icons.search_off_rounded, color: WakaColors.mutedText, size: 64),
          SizedBox(height: 18),
          Text(
            'Không tìm thấy sản phẩm',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              height: 1.15,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Thử nhập tên sách, nhà bán hoặc mức giá khác',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: WakaColors.mutedText,
              fontSize: 16,
              fontWeight: FontWeight.w500,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _ShopHeader extends StatelessWidget {
  const _ShopHeader({
    required this.controller,
    required this.hasSearchText,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final bool hasSearchText;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: ShopLayout.headerHeight,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => _openCategoryScreen(context),
              child: const Icon(
                Icons.grid_view_rounded,
                color: Colors.white,
                size: 31,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Container(
                height: ShopLayout.searchHeight,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F2F3),
                  borderRadius: BorderRadius.circular(26),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.search_rounded,
                      color: Color(0xFF9FA0A4),
                      size: 26,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: TextField(
                        controller: controller,
                        onChanged: onChanged,
                        cursorColor: WakaColors.accent,
                        textInputAction: TextInputAction.search,
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 21,
                          fontWeight: FontWeight.w400,
                          height: 1,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Nhập tên sản phẩm',
                          hintStyle: TextStyle(
                            color: Color(0xFF9FA0A4),
                            fontSize: 21,
                            fontWeight: FontWeight.w400,
                            height: 1,
                          ),
                          border: InputBorder.none,
                          isCollapsed: true,
                        ),
                      ),
                    ),
                    if (hasSearchText)
                      GestureDetector(
                        onTap: onClear,
                        child: const Icon(
                          Icons.cancel_rounded,
                          color: Color(0xFF9FA0A4),
                          size: 22,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 20),
            const Icon(
              Icons.add_shopping_cart_rounded,
              color: Colors.white,
              size: 30,
            ),
            const SizedBox(width: 20),
            const Icon(
              Icons.chat_bubble_outline_rounded,
              color: Colors.white,
              size: 30,
            ),
          ],
        ),
      ),
    );
  }
}

class _ShopSectionTitle extends StatelessWidget {
  const _ShopSectionTitle({
    required this.title,
    this.opensCategoryScreen = false,
  });

  final String title;
  final bool opensCategoryScreen;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: opensCategoryScreen ? () => _openCategoryScreen(context) : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: ShopLayout.horizontalPadding,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: ShopFontSizes.sectionTitle,
                  fontWeight: FontWeight.w900,
                  height: 1.08,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Colors.white,
              size: 36,
            ),
          ],
        ),
      ),
    );
  }
}

void _openCategoryScreen(BuildContext context) {
  Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(builder: (_) => const ShopCategoryScreen()));
}

class _CategoryList extends StatelessWidget {
  const _CategoryList({required this.categories});

  final List<ShopCategory> categories;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 176,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(
          horizontal: ShopLayout.horizontalPadding,
        ),
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 26),
        itemBuilder: (context, index) => _CategoryItem(categories[index]),
      ),
    );
  }
}

class _CategoryItem extends StatelessWidget {
  const _CategoryItem(this.category);

  final ShopCategory category;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 88,
      child: Column(
        children: [
          Container(
            width: ShopLayout.categoryAvatarSize,
            height: ShopLayout.categoryAvatarSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: category.colors,
              ),
            ),
            child: Center(
              child: Transform.rotate(
                angle: -0.03,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: Container(
                    width: 42,
                    height: 62,
                    decoration: BoxDecoration(
                      color: category.bookColor,
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black38,
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Image.asset(
                      ShopAssets.bookIllustration,
                      fit: BoxFit.cover,
                      alignment: Alignment.topCenter,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            category.label,
            maxLines: 4,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: ShopFontSizes.categoryLabel,
              fontWeight: FontWeight.w500,
              height: 1.12,
            ),
          ),
        ],
      ),
    );
  }
}

class _CouponList extends StatelessWidget {
  const _CouponList();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: ShopLayout.couponHeight,
      child: ListView.separated(
        padding: EdgeInsets.zero,
        scrollDirection: Axis.horizontal,
        itemCount: 3,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) => _CouponCard(index: index),
      ),
    );
  }
}

class _CouponCard extends StatelessWidget {
  const _CouponCard({required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300,
      child: Row(
        children: [
          Container(
            width: 86,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFF7E90), Color(0xFFFF5969)],
              ),
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.local_shipping_outlined,
                  color: Colors.white,
                  size: 34,
                ),
                SizedBox(height: 10),
                Text(
                  'MÃ VẬN\nCHUYỂN',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    height: 1.12,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              height: double.infinity,
              padding: const EdgeInsets.fromLTRB(18, 18, 14, 12),
              color: WakaColors.elevatedSoft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    index == 0
                        ? 'Giảm 20K phí vận\nchuyển, đơn tối thi...'
                        : 'Giảm phí vận\nchuyển toàn quốc',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      height: 1.12,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    index == 0 ? 'Đã dùng 2%' : 'Ngày hết hạn\n06/01',
                    maxLines: 2,
                    style: const TextStyle(
                      color: WakaColors.mutedText,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      height: 1.12,
                    ),
                  ),
                  const Spacer(),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      minHeight: 7,
                      value: index == 0 ? 0.02 : 0.2,
                      color: const Color(0xFFFF2B6C),
                      backgroundColor: const Color(0xFF111113),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SellerList extends StatelessWidget {
  const _SellerList({required this.sellers});

  final List<ShopSeller> sellers;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 152,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(
          horizontal: ShopLayout.horizontalPadding,
        ),
        scrollDirection: Axis.horizontal,
        itemCount: sellers.length,
        separatorBuilder: (_, _) => const SizedBox(width: 18),
        itemBuilder: (context, index) => _SellerItem(sellers[index]),
      ),
    );
  }
}

class _SellerItem extends StatelessWidget {
  const _SellerItem(this.seller);

  final ShopSeller seller;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 86,
      child: Column(
        children: [
          Container(
            width: ShopLayout.sellerAvatarSize,
            height: ShopLayout.sellerAvatarSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: seller.colors),
            ),
            alignment: Alignment.center,
            child: Text(
              seller.logo,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: seller.logo.contains('eve')
                    ? const Color(0xFFD52C72)
                    : WakaColors.accent,
                fontSize: seller.logo.length > 7 ? 13 : 19,
                fontWeight: FontWeight.w900,
                height: 0.95,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            seller.name,
            maxLines: 3,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: ShopFontSizes.sellerLabel,
              fontWeight: FontWeight.w500,
              height: 1.12,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductFilterChips extends StatelessWidget {
  const _ProductFilterChips();

  static const filters = ['Tất cả', 'Sách giấy', 'Sách điện tử', 'Sách nói'];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(
          horizontal: ShopLayout.horizontalPadding,
        ),
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final selected = index == 0;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? Colors.white : WakaColors.elevated,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Text(
              filters[index],
              style: TextStyle(
                color: selected ? Colors.black : Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w500,
                height: 1,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TopProductList extends StatelessWidget {
  const _TopProductList({required this.products});

  final List<ShopProduct> products;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: ShopLayout.topProductListHeight,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(
          horizontal: ShopLayout.horizontalPadding,
        ),
        scrollDirection: Axis.horizontal,
        itemCount: products.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) => SizedBox(
          width: ShopLayout.topProductWidth,
          child: _ProductCard(product: products[index], compact: true),
        ),
      ),
    );
  }
}

class _SuggestedGrid extends StatelessWidget {
  const _SuggestedGrid({required this.products});

  final List<ShopProduct> products;

  @override
  Widget build(BuildContext context) {
    return SliverGrid.builder(
      itemCount: products.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 22,
        crossAxisSpacing: 10,
        mainAxisExtent: ShopLayout.suggestedProductCardHeight,
      ),
      itemBuilder: (context, index) =>
          _ProductCard(product: products[index], compact: false),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product, required this.compact});

  final ShopProduct product;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ProductImage(
          product: product,
          height: compact
              ? ShopLayout.topProductImageHeight
              : ShopLayout.suggestedImageHeight,
        ),
        const SizedBox(height: 12),
        Text(
          product.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: ShopFontSizes.productTitle,
            fontWeight: FontWeight.w500,
            height: 1.14,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          product.price,
          maxLines: 1,
          style: const TextStyle(
            color: Color(0xFFFF2F6E),
            fontSize: ShopFontSizes.price,
            fontWeight: FontWeight.w800,
            height: 1,
          ),
        ),
        if (product.oldPrice.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            product.oldPrice,
            style: const TextStyle(
              color: Colors.white,
              fontSize: ShopFontSizes.oldPrice,
              fontWeight: FontWeight.w500,
              decoration: TextDecoration.lineThrough,
              decorationColor: Colors.white,
              height: 1,
            ),
          ),
        ],
        if (product.sold.isNotEmpty) ...[
          const SizedBox(height: 14),
          Text(
            product.sold,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: WakaColors.mutedText,
              fontSize: ShopFontSizes.sold,
              fontWeight: FontWeight.w500,
              height: 1,
            ),
          ),
        ],
      ],
    );
  }
}

class _ProductImage extends StatelessWidget {
  const _ProductImage({required this.product, required this.height});

  final ShopProduct product;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            height: height,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                _ShopProductArtwork(product: product),
                CustomPaint(painter: _ProductMockPainter(product.rank)),
              ],
            ),
          ),
        ),
        if (product.discount.isNotEmpty)
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
              decoration: const BoxDecoration(
                color: Color(0xFF2F73F6),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(3),
                  topRight: Radius.circular(4),
                ),
              ),
              child: Text(
                product.discount,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w500,
                  height: 1,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ShopProductArtwork extends StatelessWidget {
  const _ShopProductArtwork({required this.product});

  final ShopProduct product;

  @override
  Widget build(BuildContext context) {
    if (product.imageUrl.isEmpty) return _FallbackShopProductArt(product);

    return Image.network(
      product.imageUrl,
      fit: BoxFit.cover,
      alignment: Alignment.topCenter,
      errorBuilder: (_, _, _) => _FallbackShopProductArt(product),
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return _FallbackShopProductArt(product);
      },
    );
  }
}

class _FallbackShopProductArt extends StatelessWidget {
  const _FallbackShopProductArt(this.product);

  final ShopProduct product;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          ShopAssets.bookIllustration,
          fit: BoxFit.cover,
          alignment: product.rank == null
              ? Alignment.center
              : Alignment.topCenter,
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: product.colors
                  .map((color) => color.withValues(alpha: 0.36))
                  .toList(),
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black.withValues(alpha: 0.18),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ProductMockPainter extends CustomPainter {
  const _ProductMockPainter(this.rank);

  final int? rank;

  @override
  void paint(Canvas canvas, Size size) {
    if (rank != null) {
      final textPainter = TextPainter(textDirection: TextDirection.ltr)
        ..text = TextSpan(
          text: '$rank',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.86),
            fontSize: 52,
            fontWeight: FontWeight.w900,
            height: 1,
          ),
        )
        ..layout();
      textPainter.paint(canvas, Offset(8, size.height - 58));
    }
  }

  @override
  bool shouldRepaint(covariant _ProductMockPainter oldDelegate) {
    return oldDelegate.rank != rank;
  }
}
