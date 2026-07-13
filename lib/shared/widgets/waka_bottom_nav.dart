import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class WakaBottomNav extends StatelessWidget {
  const WakaBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onChanged,
  });

  final int selectedIndex;
  final ValueChanged<int> onChanged;

  static const _items = [
    _NavItem(Icons.home_outlined, Icons.home_rounded, 'Trang chủ'),
    _NavItem(Icons.local_mall_outlined, Icons.local_mall, 'Waka Shop'),
    _NavItem(Icons.discount_outlined, Icons.discount, 'Ưu đãi'),
    _NavItem(Icons.explore_outlined, Icons.explore, 'Khám phá'),
    _NavItem(Icons.menu_book_outlined, Icons.menu_book, 'Thư viện'),
    _NavItem(Icons.person_outline, Icons.person, 'Cá nhân'),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        height: WakaLayout.bottomNavHeight,
        decoration: const BoxDecoration(
          color: WakaColors.navBackground,
          border: Border(top: BorderSide(color: WakaColors.darkDivider)),
        ),
        child: Row(
          children: [
            for (var i = 0; i < _items.length; i++)
              Expanded(
                child: _NavButton(
                  item: _items[i],
                  active: selectedIndex == i,
                  onTap: () => onChanged(i),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.item,
    required this.active,
    required this.onTap,
  });

  final _NavItem item;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? WakaColors.accent : WakaColors.mutedText;

    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            active ? item.activeIcon : item.icon,
            color: color,
            size: WakaIconSizes.nav,
          ),
          const SizedBox(height: WakaSpacing.xs),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              item.label,
              maxLines: 1,
              style: WakaTextStyles.navLabel.copyWith(
                color: color,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem {
  const _NavItem(this.icon, this.activeIcon, this.label);

  final IconData icon;
  final IconData activeIcon;
  final String label;
}