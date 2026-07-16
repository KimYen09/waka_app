import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_theme.dart';
import '../../shared/navigation/app_navigation.dart';
import 'shop_constants.dart';

final ValueNotifier<List<ShopProduct>> shopCartProducts = ValueNotifier(
  const <ShopProduct>[],
);

void addShopProductToCart(ShopProduct product) {
  final current = shopCartProducts.value;
  final exists = current.any(
    (item) => product.url.isNotEmpty
        ? item.url == product.url
        : item.title == product.title,
  );
  if (exists) return;
  shopCartProducts.value = [...current, product];
}

void removeShopProductFromCart(ShopProduct product) {
  shopCartProducts.value = shopCartProducts.value
      .where(
        (item) => product.url.isNotEmpty
            ? item.url != product.url
            : item.title != product.title,
      )
      .toList(growable: false);
}

class ShopProductCategoryScreen extends StatefulWidget {
  const ShopProductCategoryScreen({
    super.key,
    required this.category,
    required this.products,
  });

  final ShopCategory category;
  final List<ShopProduct> products;

  @override
  State<ShopProductCategoryScreen> createState() =>
      _ShopProductCategoryScreenState();
}

class _ShopProductCategoryScreenState extends State<ShopProductCategoryScreen> {
  final _searchController = TextEditingController();
  String _search = '';
  int _subcategory = 0;
  int _sortMode = 0;

  List<String> get _subcategories {
    final title = _cleanLabel(widget.category.label).toLowerCase();
    if (title.contains('văn học')) {
      return const [
        'Tất cả',
        'Truyện dài',
        'Truyện ngắn',
        'Trinh thám',
        'Truyện tranh',
        'Light Novel',
      ];
    }
    if (title.contains('kinh tế')) {
      return const ['Tất cả', 'Kinh doanh', 'Đầu tư', 'Tài chính', 'Marketing'];
    }
    return const ['Tất cả', 'Sách mới', 'Bán chạy', 'Giảm giá', 'Đề xuất'];
  }

  List<ShopProduct> get _products {
    final source = widget.products.isEmpty
        ? suggestedProducts
        : widget.products;
    final filtered = source
        .where((product) {
          if (_search.trim().isEmpty) return true;
          return _normalizeShopText(
            product.title,
          ).contains(_normalizeShopText(_search));
        })
        .toList(growable: false);
    final sorted = [...filtered];
    if (_sortMode == 1) {
      sorted.sort(
        (a, b) => _priceValue(a.price).compareTo(_priceValue(b.price)),
      );
    } else if (_sortMode == 2) {
      sorted.sort(
        (a, b) => _priceValue(b.price).compareTo(_priceValue(a.price)),
      );
    } else if (_sortMode == 3) {
      sorted.sort((a, b) => b.discount.compareTo(a.discount));
    }
    return sorted;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _share() async {
    await Clipboard.setData(
      ClipboardData(text: 'Danh mục ${_cleanLabel(widget.category.label)}'),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã sao chép liên kết danh mục.')),
    );
  }

  void _showFilters() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: WakaColors.elevated,
      showDragHandle: true,
      builder: (sheetContext) {
        const labels = [
          'Mặc định',
          'Giá thấp đến cao',
          'Giá cao đến thấp',
          'Giảm giá nhiều nhất',
        ];
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(
              labels.length,
              (index) => ListTile(
                leading: Icon(
                  _sortMode == index
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_off_rounded,
                  color: _sortMode == index
                      ? WakaColors.accent
                      : Colors.white54,
                ),
                title: Text(
                  labels[index],
                  style: const TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  setState(() => _sortMode = index);
                },
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WakaColors.background,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: _FlowHeader(
                title: _cleanLabel(widget.category.label),
                trailing: IconButton(
                  onPressed: _share,
                  icon: const Icon(Icons.share_rounded, color: Colors.white),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: _FlowSearchField(
                        controller: _searchController,
                        hint: 'Nhập tên sản phẩm',
                        onChanged: (value) => setState(() => _search = value),
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: _showFilters,
                      borderRadius: BorderRadius.circular(8),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 8,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.tune_rounded,
                              color: WakaColors.accent,
                              size: 20,
                            ),
                            SizedBox(width: 3),
                            Text(
                              'Lọc',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 88,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  scrollDirection: Axis.horizontal,
                  itemCount: _subcategories.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 15),
                  itemBuilder: (context, index) {
                    final selected = _subcategory == index;
                    return GestureDetector(
                      onTap: () => setState(() => _subcategory = index),
                      child: SizedBox(
                        width: 58,
                        child: Column(
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: widget.category.colors,
                                ),
                                border: selected
                                    ? Border.all(
                                        color: WakaColors.accent,
                                        width: 2.5,
                                      )
                                    : null,
                              ),
                              child: Icon(
                                _subcategoryIcon(index),
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              _subcategories[index],
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: selected
                                    ? WakaColors.accent
                                    : Colors.white,
                                fontSize: 10.5,
                                height: 1.05,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            if (_products.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Text(
                    'Không tìm thấy sản phẩm',
                    style: TextStyle(color: Colors.white60, fontSize: 18),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 30),
                sliver: SliverGrid.builder(
                  itemCount: _products.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 18,
                    mainAxisExtent: 330,
                  ),
                  itemBuilder: (context, index) =>
                      ShopProductTile(product: _products[index]),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class ShopSellerScreen extends StatelessWidget {
  const ShopSellerScreen({super.key, required this.sellers});

  final List<ShopSeller> sellers;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WakaColors.background,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _FlowHeader(
                title: 'Nhà sách Online',
                trailing: IconButton(
                  onPressed: () => _openCart(context),
                  icon: const Icon(
                    Icons.shopping_cart_outlined,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
              sliver: SliverGrid.builder(
                itemCount: sellers.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 24,
                  mainAxisExtent: 135,
                ),
                itemBuilder: (context, index) {
                  final seller = sellers[index];
                  return InkWell(
                    onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Đang mở ${_cleanLabel(seller.name)}'),
                      ),
                    ),
                    borderRadius: BorderRadius.circular(50),
                    child: Column(
                      children: [
                        ShopSellerLogo(seller: seller, size: 82),
                        const SizedBox(height: 9),
                        Text(
                          _cleanLabel(seller.name),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            height: 1.1,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ShopRankingScreen extends StatefulWidget {
  const ShopRankingScreen({super.key, required this.products});

  final List<ShopProduct> products;

  @override
  State<ShopRankingScreen> createState() => _ShopRankingScreenState();
}

class _ShopRankingScreenState extends State<ShopRankingScreen> {
  int _selectedType = 0;
  String _period = 'Tất cả';

  List<ShopProduct> get _products {
    final source = widget.products.isEmpty ? topProducts : widget.products;
    if (_selectedType == 0) return source;
    final type = const [
      'Sách giấy',
      'Sách điện tử',
      'Sách nói',
    ][_selectedType - 1];
    final filtered = source.where((product) => product.type == type).toList();
    return filtered.isEmpty ? source : filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WakaColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _FlowHeader(
              title: 'Bảng Xếp hạng',
              trailing: IconButton(
                onPressed: () => _openCart(context),
                icon: const Icon(
                  Icons.shopping_cart_outlined,
                  color: Colors.white,
                ),
              ),
            ),
            _TypeTabs(
              selectedIndex: _selectedType,
              onChanged: (value) => setState(() => _selectedType = value),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _period,
                    dropdownColor: WakaColors.elevated,
                    style: const TextStyle(color: Colors.white),
                    items: const ['Tất cả', 'Tuần này', 'Tháng này']
                        .map(
                          (value) => DropdownMenuItem(
                            value: value,
                            child: Text(value),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) setState(() => _period = value);
                    },
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(12, 6, 12, 24),
                itemCount: _products.length,
                separatorBuilder: (_, _) =>
                    const Divider(color: Colors.white10, height: 12),
                itemBuilder: (context, index) =>
                    _RankingItem(product: _products[index], rank: index + 1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ShopCouponScreen extends StatelessWidget {
  const ShopCouponScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WakaColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const _FlowHeader(title: 'Mã khuyến mại'),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(14),
                itemCount: 4,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) => _VoucherCard(index: index),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ShopChatScreen extends StatelessWidget {
  const ShopChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WakaColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const _FlowHeader(title: 'Trò chuyện'),
            const Padding(
              padding: EdgeInsets.fromLTRB(14, 4, 14, 10),
              child: _StaticSearchField(hint: 'Tìm kiếm'),
            ),
            const ListTile(
              leading: CircleAvatar(
                backgroundColor: WakaColors.accent,
                child: Icon(Icons.support_agent_rounded, color: Colors.white),
              ),
              title: Text(
                'Trợ lý Waka',
                style: TextStyle(
                  color: WakaColors.accent,
                  fontWeight: FontWeight.w800,
                ),
              ),
              subtitle: Text(
                'Xin chào, bạn cần trợ giúp gì?',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            const Divider(color: Colors.white12),
            const Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.forum_rounded,
                      color: Color(0xFF7EA5FF),
                      size: 72,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Bạn chưa có cuộc trò chuyện nào',
                      style: TextStyle(color: Colors.white70, fontSize: 16),
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

class ShopCartScreen extends StatelessWidget {
  const ShopCartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WakaColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const _FlowHeader(title: 'Giỏ hàng'),
            Expanded(
              child: ValueListenableBuilder<List<ShopProduct>>(
                valueListenable: shopCartProducts,
                builder: (context, products, _) {
                  if (products.isEmpty) return const _EmptyCart();
                  return _CartContent(products: products);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyCart extends StatelessWidget {
  const _EmptyCart();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.shopping_cart_outlined, color: Colors.white38, size: 72),
          SizedBox(height: 14),
          Text(
            'Giỏ hàng đang trống',
            style: TextStyle(color: Colors.white70, fontSize: 18),
          ),
        ],
      ),
    );
  }
}

class _CartContent extends StatelessWidget {
  const _CartContent({required this.products});

  final List<ShopProduct> products;

  @override
  Widget build(BuildContext context) {
    final total = products.fold<int>(
      0,
      (sum, product) => sum + _priceValue(product.price),
    );
    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 18),
            itemCount: products.length,
            separatorBuilder: (_, _) => const Divider(color: Colors.white12),
            itemBuilder: (context, index) {
              final product = products[index];
              return SizedBox(
                height: 92,
                child: Row(
                  children: [
                    SizedBox(
                      width: 62,
                      child: ShopProductArtwork(product: product),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 7),
                          Text(
                            product.price,
                            style: const TextStyle(
                              color: Color(0xFFFF3B7A),
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Xóa khỏi giỏ',
                      onPressed: () => removeShopProductFromCart(product),
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        color: Colors.white60,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
          decoration: const BoxDecoration(
            color: WakaColors.elevated,
            border: Border(top: BorderSide(color: Colors.white12)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tổng thanh toán',
                      style: TextStyle(color: Colors.white60),
                    ),
                    Text(
                      _formatShopPrice(total),
                      style: const TextStyle(
                        color: Color(0xFFFF3B7A),
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              FilledButton(
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Vui lòng đăng nhập để thanh toán.'),
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: WakaColors.accent,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Thanh toán'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class ShopProductTile extends StatelessWidget {
  const ShopProductTile({super.key, required this.product});

  final ShopProduct product;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => showShopProductSheet(context, product),
      borderRadius: BorderRadius.circular(6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: ShopProductArtwork(product: product)),
          const SizedBox(height: 8),
          Text(
            product.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14.5,
              height: 1.15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  product.price,
                  style: const TextStyle(
                    color: Color(0xFFFF3B7A),
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (product.sold.isNotEmpty)
                Text(
                  product.sold,
                  style: const TextStyle(color: Colors.white60, fontSize: 11),
                ),
            ],
          ),
          if (product.oldPrice.isNotEmpty)
            Text(
              product.oldPrice,
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 12,
                decoration: TextDecoration.lineThrough,
              ),
            ),
        ],
      ),
    );
  }
}

class ShopProductArtwork extends StatelessWidget {
  const ShopProductArtwork({super.key, required this.product});

  final ShopProduct product;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: product.imageAsset.isNotEmpty
              ? Image.asset(
                  product.imageAsset,
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                  errorBuilder: (_, _, _) => _FallbackProduct(product: product),
                )
              : product.imageUrl.isNotEmpty
              ? Image.network(
                  product.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => _FallbackProduct(product: product),
                )
              : _FallbackProduct(product: product),
        ),
        if (product.discount.isNotEmpty)
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: const BoxDecoration(
                color: Color(0xFF397CFA),
                borderRadius: BorderRadius.only(bottomLeft: Radius.circular(4)),
              ),
              child: Text(
                product.discount,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class ShopSellerLogo extends StatelessWidget {
  const ShopSellerLogo({super.key, required this.seller, required this.size});

  final ShopSeller seller;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(colors: seller.colors),
      ),
      alignment: Alignment.center,
      child: seller.logo.isEmpty
          ? const Icon(
              Icons.local_florist_rounded,
              color: Colors.white,
              size: 32,
            )
          : Text(
              seller.logo,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: seller.logo.toLowerCase().contains('eve')
                    ? const Color(0xFFD52C72)
                    : WakaColors.accent,
                fontSize: seller.logo.length > 8 ? 11 : 15,
                fontWeight: FontWeight.w900,
                height: 0.95,
              ),
            ),
    );
  }
}

class ShopPromoVideoCard extends StatelessWidget {
  const ShopPromoVideoCard({super.key, required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
      child: Stack(
        children: [
          Container(
            height: 155,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              gradient: const LinearGradient(
                colors: [Color(0xFFE5F6FF), Color(0xFFB8ECFF)],
              ),
            ),
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'WAKA SHOP',
                    style: TextStyle(
                      color: Color(0xFF1576A1),
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Chọn sách hay · Nhận ưu đãi lớn',
                    style: TextStyle(color: Color(0xFF24566C)),
                  ),
                  SizedBox(height: 12),
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Color(0x99157CA7),
                    child: Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 38,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: IconButton(
              onPressed: onClose,
              icon: const Icon(Icons.close_rounded, color: Colors.white),
              style: IconButton.styleFrom(backgroundColor: Colors.black45),
            ),
          ),
        ],
      ),
    );
  }
}

class _FlowHeader extends StatelessWidget {
  const _FlowHeader({required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 58,
      child: Row(
        children: [
          IconButton(
            onPressed: () => AppNavigation.goBackOrExit(context),
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          ),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          SizedBox(width: 48, child: trailing),
        ],
      ),
    );
  }
}

class _FlowSearchField extends StatelessWidget {
  const _FlowSearchField({
    required this.controller,
    required this.hint,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF273149),
        borderRadius: BorderRadius.circular(5),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          icon: const Icon(
            Icons.search_rounded,
            color: Colors.white54,
            size: 20,
          ),
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
          border: InputBorder.none,
          isDense: true,
        ),
      ),
    );
  }
}

class _StaticSearchField extends StatelessWidget {
  const _StaticSearchField({required this.hint});

  final String hint;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF273149),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, color: Colors.white54, size: 20),
          const SizedBox(width: 8),
          Text(hint, style: const TextStyle(color: Colors.white38)),
        ],
      ),
    );
  }
}

class _TypeTabs extends StatelessWidget {
  const _TypeTabs({required this.selectedIndex, required this.onChanged});

  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    const labels = ['Tất cả', 'Sách giấy', 'Sách điện tử', 'Sách nói'];
    return SizedBox(
      height: 42,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        scrollDirection: Axis.horizontal,
        itemCount: labels.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final selected = selectedIndex == index;
          return ChoiceChip(
            selected: selected,
            onSelected: (_) => onChanged(index),
            label: Text(labels[index]),
            labelPadding: const EdgeInsets.symmetric(horizontal: 3),
            padding: const EdgeInsets.symmetric(horizontal: 5),
            visualDensity: VisualDensity.compact,
            selectedColor: Colors.white,
            backgroundColor: WakaColors.elevated,
            labelStyle: TextStyle(
              color: selected ? Colors.black : Colors.white,
            ),
            showCheckmark: false,
          );
        },
      ),
    );
  }
}

class _RankingItem extends StatelessWidget {
  const _RankingItem({required this.product, required this.rank});

  final ShopProduct product;
  final int rank;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 92,
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              '$rank',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: rank <= 3 ? const Color(0xFFFF2F6E) : Colors.white70,
                fontSize: rank <= 3 ? 30 : 20,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 7),
          SizedBox(width: 58, child: ShopProductArtwork(product: product)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  product.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    height: 1.1,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Nhà sách Waka',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
                if (product.sold.isNotEmpty)
                  Text(
                    product.sold.replaceFirst('Đã bán', '♡'),
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
              ],
            ),
          ),
          FilledButton(
            onPressed: () => showShopProductSheet(context, product),
            style: FilledButton.styleFrom(
              backgroundColor: WakaColors.accent,
              foregroundColor: Colors.white,
              visualDensity: VisualDensity.compact,
            ),
            child: const Text('Mua ngay'),
          ),
        ],
      ),
    );
  }
}

class _VoucherCard extends StatelessWidget {
  const _VoucherCard({required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 112,
      decoration: BoxDecoration(
        color: WakaColors.elevatedSoft,
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          Container(
            width: 92,
            color: const Color(0xFFFF5D83),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.local_shipping_outlined, color: Colors.white),
                SizedBox(height: 6),
                Text(
                  'MÃ VẬN\nCHUYỂN',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    index.isEven
                        ? 'Giảm 20K phí vận chuyển'
                        : 'Freeship đơn từ 199K',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Áp dụng cho sản phẩm đủ điều kiện',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      const Expanded(
                        child: LinearProgressIndicator(
                          value: 0.24,
                          color: Color(0xFFFF2F6E),
                          backgroundColor: Colors.black26,
                        ),
                      ),
                      const SizedBox(width: 12),
                      TextButton(
                        onPressed: () =>
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Đã lưu mã.')),
                            ),
                        child: const Text('Lưu'),
                      ),
                    ],
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

class _FallbackProduct extends StatelessWidget {
  const _FallbackProduct({required this.product});

  final ShopProduct product;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: product.colors),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(ShopAssets.bookIllustration, fit: BoxFit.cover),
          ColoredBox(color: product.colors.first.withValues(alpha: 0.28)),
        ],
      ),
    );
  }
}

void showShopProductSheet(BuildContext context, ShopProduct product) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: WakaColors.elevated,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 4, 18, 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              product.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 19,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              product.price,
              style: const TextStyle(
                color: Color(0xFFFF3B7A),
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: () {
                addShopProductToCart(product);
                Navigator.pop(sheetContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã thêm vào giỏ hàng.')),
                );
              },
              icon: const Icon(Icons.add_shopping_cart_rounded),
              label: const Text('THÊM VÀO GIỎ'),
              style: FilledButton.styleFrom(
                backgroundColor: WakaColors.accent,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

void _openCart(BuildContext context) {
  Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(builder: (_) => const ShopCartScreen()));
}

String _cleanLabel(String value) => value.replaceAll('\n', ' ');

String _normalizeShopText(String value) => value
    .toLowerCase()
    .replaceAll(RegExp('[àáạảãâầấậẩẫăằắặẳẵ]'), 'a')
    .replaceAll(RegExp('[èéẹẻẽêềếệểễ]'), 'e')
    .replaceAll(RegExp('[ìíịỉĩ]'), 'i')
    .replaceAll(RegExp('[òóọỏõôồốộổỗơờớợởỡ]'), 'o')
    .replaceAll(RegExp('[ùúụủũưừứựửữ]'), 'u')
    .replaceAll(RegExp('[ỳýỵỷỹ]'), 'y')
    .replaceAll('đ', 'd');

int _priceValue(String value) =>
    int.tryParse(value.replaceAll(RegExp('[^0-9]'), '')) ?? 0;

String _formatShopPrice(int value) {
  final text = value.toString();
  final buffer = StringBuffer();
  for (var index = 0; index < text.length; index++) {
    buffer.write(text[index]);
    final remaining = text.length - index - 1;
    if (remaining > 0 && remaining % 3 == 0) buffer.write('.');
  }
  return '${buffer.toString()}đ';
}

IconData _subcategoryIcon(int index) {
  const icons = [
    Icons.auto_stories_rounded,
    Icons.menu_book_rounded,
    Icons.short_text_rounded,
    Icons.travel_explore_rounded,
    Icons.photo_library_rounded,
    Icons.lightbulb_outline_rounded,
  ];
  return icons[index % icons.length];
}
