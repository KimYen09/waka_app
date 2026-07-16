import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../shared/navigation/app_navigation.dart';
import 'shop_constants.dart';
import 'shop_flow_screens.dart';

class ShopCategoryScreen extends StatefulWidget {
  const ShopCategoryScreen({super.key});

  @override
  State<ShopCategoryScreen> createState() => _ShopCategoryScreenState();
}

class _ShopCategoryScreenState extends State<ShopCategoryScreen> {
  int _selectedTab = 0;

  List<ShopCategory> get _categories {
    return _selectedTab == 0 ? shopCategories : shopStationeryCategories;
  }

  void _selectTab(int index) {
    setState(() => _selectedTab = index);
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
            SliverToBoxAdapter(child: _CategoryHeader(onHomeTap: _goHome)),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
            SliverToBoxAdapter(
              child: _CategoryTabs(
                selectedIndex: _selectedTab,
                onChanged: _selectTab,
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 30)),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              sliver: SliverGrid.builder(
                itemCount: _categories.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 32,
                  crossAxisSpacing: 18,
                  mainAxisExtent: ShopLayout.categoryScreenItemHeight,
                ),
                itemBuilder: (context, index) {
                  return _CategoryGridItem(
                    category: _categories[index],
                    stationery: _selectedTab == 1,
                    index: index,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => ShopProductCategoryScreen(
                          category: _categories[index],
                          products: const [
                            ...topProducts,
                            ...suggestedProducts,
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 48)),
          ],
        ),
      ),
    );
  }

  void _goHome() {
    Navigator.of(context).pop();
  }
}

class _CategoryHeader extends StatelessWidget {
  const _CategoryHeader({required this.onHomeTap});

  final VoidCallback onHomeTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 18, 14, 0),
      child: Row(
        children: [
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: () => AppNavigation.goBackOrExit(context),
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 6),
          const Expanded(
            child: Text(
              'Danh mục',
              style: TextStyle(
                color: Colors.white,
                fontSize: 31,
                fontWeight: FontWeight.w900,
                height: 1,
              ),
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const ShopCartScreen()),
            ),
            icon: const Icon(
              Icons.add_shopping_cart_rounded,
              color: Colors.white,
              size: 31,
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: onHomeTap,
            icon: const Icon(
              Icons.home_outlined,
              color: Colors.white,
              size: 34,
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryTabs extends StatelessWidget {
  const _CategoryTabs({required this.selectedIndex, required this.onChanged});

  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Row(
          children: [
            _CategoryTabButton(
              label: 'Sách',
              selected: selectedIndex == 0,
              onTap: () => onChanged(0),
            ),
            _CategoryTabButton(
              label: 'Văn phòng phẩm',
              selected: selectedIndex == 1,
              onTap: () => onChanged(1),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryTabButton extends StatelessWidget {
  const _CategoryTabButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 44,
          alignment: Alignment.center,
          color: selected ? WakaColors.accent : WakaColors.elevatedSoft,
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w500,
              height: 1,
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryGridItem extends StatelessWidget {
  const _CategoryGridItem({
    required this.category,
    required this.stationery,
    required this.index,
    required this.onTap,
  });

  final ShopCategory category;
  final bool stationery;
  final int index;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          _CategoryImage(
            category: category,
            stationery: stationery,
            index: index,
          ),
          const SizedBox(height: 12),
          Text(
            category.label,
            maxLines: 4,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: ShopFontSizes.categoryScreenLabel,
              fontWeight: FontWeight.w500,
              height: 1.12,
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryImage extends StatelessWidget {
  const _CategoryImage({
    required this.category,
    required this.stationery,
    required this.index,
  });

  final ShopCategory category;
  final bool stationery;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: ShopLayout.categoryScreenImageSize,
      height: ShopLayout.categoryScreenImageSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: category.colors,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (stationery)
            _StationeryIllustration(index: index, color: category.bookColor)
          else
            Center(
              child: Transform.rotate(
                angle: index.isEven ? -0.02 : 0.02,
                child: Container(
                  width: 48,
                  height: 66,
                  decoration: BoxDecoration(
                    color: category.bookColor,
                    borderRadius: BorderRadius.circular(3),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black38,
                        blurRadius: 10,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Image.asset(
                    category.imageAsset.isEmpty
                        ? ShopAssets.bookIllustration
                        : category.imageAsset,
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                    errorBuilder: (_, _, _) => ColoredBox(
                      color: category.bookColor,
                      child: const Icon(
                        Icons.menu_book_rounded,
                        color: Colors.white70,
                        size: 28,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _StationeryIllustration extends StatelessWidget {
  const _StationeryIllustration({required this.index, required this.color});

  final int index;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final icons = [
      Icons.edit_note_rounded,
      Icons.card_giftcard_rounded,
      Icons.calculate_outlined,
    ];

    return DecoratedBox(
      decoration: BoxDecoration(color: color.withValues(alpha: 0.18)),
      child: Icon(icons[index % icons.length], color: Colors.white, size: 48),
    );
  }
}
