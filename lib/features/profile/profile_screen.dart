import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../shared/widgets/icons/acorn_icon.dart';
import 'profile_constants.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SafeArea(
          bottom: false,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              const SliverToBoxAdapter(child: _ProfileHeader()),
              const SliverToBoxAdapter(child: SizedBox(height: 30)),
              const SliverToBoxAdapter(child: _UserRow()),
              const SliverToBoxAdapter(child: SizedBox(height: 30)),
              const SliverToBoxAdapter(child: _RewardCard()),
              const SliverToBoxAdapter(child: SizedBox(height: 26)),
              SliverToBoxAdapter(
                child: _ProfileSectionTitle(
                  title: 'Đơn hàng',
                  action: 'Chi tiết đơn hàng',
                  onTap: () {},
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 14)),
              const SliverToBoxAdapter(child: _OrderCard()),
              const SliverToBoxAdapter(child: SizedBox(height: 30)),
              const SliverToBoxAdapter(
                child: _ProfileSectionTitle(title: 'Lịch sử đọc sách'),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
              const SliverToBoxAdapter(child: _ReadingHistoryCard()),
              const SliverToBoxAdapter(child: SizedBox(height: 30)),
              const SliverToBoxAdapter(child: _WakaMap()),
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
              const SliverToBoxAdapter(child: _ProfileMenuCard()),
              const SliverToBoxAdapter(child: SizedBox(height: 14)),
              const SliverToBoxAdapter(child: _LogoutButton()),
              const SliverToBoxAdapter(child: SizedBox(height: 96)),
            ],
          ),
        ),
        const Positioned(
          right: 18,
          bottom: ProfileLayout.supportBottom,
          child: _SupportBubble(),
        ),
      ],
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        ProfileLayout.headerHorizontalPadding,
        10,
        ProfileLayout.headerHorizontalPadding,
        0,
      ),
      child: Row(
        children: [
          Text(
            'Hồ sơ cá nhân',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const Spacer(),
          const Icon(Icons.qr_code_2_rounded, color: Colors.white, size: 30),
        ],
      ),
    );
  }
}

class _UserRow extends StatelessWidget {
  const _UserRow();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: ProfileLayout.horizontalPadding,
      ),
      child: Row(
        children: [
          Container(
            width: ProfileLayout.avatarSize,
            height: ProfileLayout.avatarSize,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF71FFDC), Color(0xFF18C58E)],
              ),
            ),
            child: const Icon(Icons.person, color: Color(0xCCFFFFFF), size: 48),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tên tài khoản',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: ProfileFontSizes.username,
                    fontWeight: FontWeight.w900,
                    height: 1.08,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'Xem thông tin tài khoản',
                  style: TextStyle(
                    color: WakaColors.mutedText,
                    fontSize: ProfileFontSizes.accountSubtitle,
                    fontWeight: FontWeight.w500,
                    height: 1.12,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: WakaColors.mutedText,
            size: 30,
          ),
        ],
      ),
    );
  }
}

class _RewardCard extends StatelessWidget {
  const _RewardCard();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: ProfileLayout.horizontalPadding,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: WakaColors.surface,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Container(
              height: ProfileLayout.rewardHeaderHeight,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: WakaColors.elevatedSoft,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Tài khoản thường',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: ProfileFontSizes.rewardTitle,
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                      ),
                    ),
                  ),
                  Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFD625), Color(0xFFFFA810)],
                      ),
                    ),
                    child: const Text(
                      'NÂNG CẤP GÓI',
                      style: TextStyle(
                        color: Color(0xFF4F3B00),
                        fontSize: ProfileFontSizes.upgradeButton,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: ProfileLayout.rewardBodyHeight,
              child: Row(
                children: const [
                  Expanded(
                    child: _RewardItem(
                      label: 'Điểm',
                      icon: Icons.attach_money_rounded,
                      color: Color(0xFFFF2F6E),
                    ),
                  ),
                  _VerticalDivider(),
                  Expanded(
                    child: _RewardItem(
                      label: 'Sồi',
                      customIcon: AcornIcon(color: WakaColors.gold),
                      color: WakaColors.gold,
                    ),
                  ),
                  _VerticalDivider(),
                  Expanded(
                    child: _RewardItem(
                      label: 'Lá xanh',
                      icon: Icons.eco_outlined,
                      color: Color(0xFF72BF48),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RewardItem extends StatelessWidget {
  const _RewardItem({
    required this.label,
    required this.color,
    this.icon,
    this.customIcon,
  });

  final String label;
  final Color color;
  final IconData? icon;
  final Widget? customIcon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: ProfileLayout.horizontalPadding,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$label  ›',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: WakaColors.mutedText,
                    fontSize: 15.5,
                    fontWeight: FontWeight.w500,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  '0',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
          customIcon ?? Icon(icon, color: color, size: 28),
        ],
      ),
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  const _VerticalDivider();

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 48, color: const Color(0xFF3A3A3D));
  }
}

class _ProfileSectionTitle extends StatelessWidget {
  const _ProfileSectionTitle({required this.title, this.action, this.onTap});

  final String title;
  final String? action;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: ProfileFontSizes.sectionTitle,
                fontWeight: FontWeight.w900,
                height: 1.08,
              ),
            ),
          ),
          if (action != null)
            GestureDetector(
              onTap: onTap,
              child: Text(
                '$action ›',
                style: const TextStyle(
                  color: WakaColors.accent,
                  fontSize: ProfileFontSizes.sectionAction,
                  fontWeight: FontWeight.w500,
                  height: 1,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: ProfileLayout.horizontalPadding,
      ),
      child: Container(
        height: ProfileLayout.orderCardHeight,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: WakaColors.surface,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          children: [
            _OrderItem(
              icon: Icons.receipt_long_outlined,
              label: 'Chờ xác nhận',
            ),
            _OrderItem(icon: Icons.inventory_2_outlined, label: 'Chờ lấy hàng'),
            _OrderItem(
              icon: Icons.local_shipping_outlined,
              label: 'Đang giao hàng',
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderItem extends StatelessWidget {
  const _OrderItem({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: ProfileLayout.orderIconSize,
            height: ProfileLayout.orderIconSize,
            decoration: const BoxDecoration(
              color: Color(0xFF0C0C0D),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 30),
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              label,
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: WakaColors.mutedText,
                fontSize: ProfileFontSizes.orderLabel,
                fontWeight: FontWeight.w500,
                height: 1.22,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReadingHistoryCard extends StatelessWidget {
  const _ReadingHistoryCard();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: ProfileLayout.horizontalPadding,
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: WakaColors.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Container(
              height: 78,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFF4B4B4E)),
              ),
              child: Row(
                children: const [
                  Expanded(
                    child: _HistoryMetric(
                      label: 'Phút đọc hôm nay',
                      value: '0',
                    ),
                  ),
                  _VerticalDivider(),
                  Expanded(
                    child: _HistoryMetric(
                      label: 'Phút nghe hôm nay',
                      value: '0',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            Container(
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFF0E0E0F),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.local_library_outlined,
                    color: WakaColors.accent,
                    size: 26,
                  ),
                  SizedBox(width: 10),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'THIẾT LẬP MỤC TIÊU ĐỌC SÁCH',
                        style: TextStyle(
                          color: WakaColors.accent,
                          fontSize: 16.5,
                          fontWeight: FontWeight.w700,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryMetric extends StatelessWidget {
  const _HistoryMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              maxLines: 2,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: WakaColors.mutedText,
                fontSize: ProfileFontSizes.historyLabel,
                fontWeight: FontWeight.w500,
                height: 1.08,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: ProfileFontSizes.historyValue,
            fontWeight: FontWeight.w800,
            height: 1,
          ),
        ),
      ],
    );
  }
}

class _WakaMap extends StatelessWidget {
  const _WakaMap();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: ProfileLayout.horizontalPadding,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Bản đồ Waka',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: ProfileFontSizes.sectionTitle,
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: WakaColors.elevatedSoft,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Bảng xếp hạng',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: ProfileFontSizes.sectionAction,
                    fontWeight: FontWeight.w500,
                    height: 1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            height: ProfileLayout.mapCardHeight,
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
            decoration: BoxDecoration(
              color: WakaColors.surface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Stack(
              children: [
                Positioned(
                  right: 10,
                  top: 42,
                  child: Icon(
                    Icons.workspace_premium_outlined,
                    color: Colors.white.withValues(alpha: 0.035),
                    size: 128,
                  ),
                ),
                const Positioned(
                  left: 0,
                  top: 0,
                  child: Icon(
                    Icons.workspace_premium_outlined,
                    color: WakaColors.accent,
                    size: 30,
                  ),
                ),
                const Positioned(right: 42, top: 76, child: _MapToast()),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 26,
                  child: SizedBox(
                    height: 148,
                    child: CustomPaint(painter: _MapChartPainter()),
                  ),
                ),
                const Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: _MapLegend(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MapToast extends StatelessWidget {
  const _MapToast();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.48),
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Text(
        'Chưa tìm thấy bạn :(',
        style: TextStyle(
          color: Colors.black,
          fontSize: ProfileFontSizes.mapToast,
          fontWeight: FontWeight.w400,
          height: 1,
        ),
      ),
    );
  }
}

class _MapLegend extends StatelessWidget {
  const _MapLegend();

  @override
  Widget build(BuildContext context) {
    const items = [
      (Color(0xFF69BE45), 'Vua Mọt'),
      (Color(0xFFFFDA3A), 'Mọt Thông Thái'),
      (Color(0xFFFF9E11), 'Mọt Sách'),
      (Color(0xFFFF2BB4), 'Mọt'),
    ];

    return SizedBox(
      height: 24,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final (color, label) = items[index];
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(
                  color: WakaColors.mutedText,
                  fontSize: ProfileFontSizes.mapLegend,
                  fontWeight: FontWeight.w500,
                  height: 1,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MapChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final baseline = size.height - 6;
    final curve = Path()
      ..moveTo(0, 0)
      ..cubicTo(
        size.width * 0.16,
        size.height * 0.46,
        size.width * 0.42,
        size.height * 0.64,
        size.width,
        baseline,
      )
      ..lineTo(0, baseline)
      ..close();

    final segmentPaint = Paint()..style = PaintingStyle.fill;
    final segments = [
      (0.00, 0.05, const Color(0xFF69BE45)),
      (0.05, 0.37, const Color(0xFFFFDA3A)),
      (0.37, 0.65, const Color(0xFFFF9E11)),
      (0.65, 1.00, const Color(0xFFFF4A25)),
    ];
    for (final (start, end, color) in segments) {
      canvas.save();
      canvas.clipRect(
        Rect.fromLTRB(size.width * start, 0, size.width * end, baseline),
      );
      segmentPaint.color = color;
      canvas.drawPath(curve, segmentPaint);
      canvas.restore();
    }

    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.28)
      ..strokeWidth = 1;
    for (var i = 1; i < 20; i++) {
      final x = size.width * i / 20;
      canvas.drawLine(Offset(x, 14), Offset(x, baseline), gridPaint);
    }

    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    final labels = [(0.015, '0%'), (0.20, '17%'), (0.48, '12%'), (0.68, '71%')];
    for (final (xFactor, text) in labels) {
      textPainter.text = TextSpan(
        text: text,
        style: const TextStyle(
          color: Color(0xDD0E0F0F),
          fontSize: ProfileFontSizes.mapToast,
          fontWeight: FontWeight.w500,
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(size.width * xFactor, baseline - 26));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ProfileMenuCard extends StatelessWidget {
  const _ProfileMenuCard();

  static const _items = [
    (Icons.history_rounded, 'Lịch sử giao dịch'),
    (Icons.notifications_none_rounded, 'Thông báo'),
    (Icons.location_on_outlined, 'Địa chỉ'),
    (Icons.settings_outlined, 'Thông tin chung'),
    (Icons.help_outline_rounded, 'Trợ giúp và góp ý'),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: ProfileLayout.horizontalPadding,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: WakaColors.surface,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            for (var i = 0; i < _items.length; i++) ...[
              _ProfileMenuItem(icon: _items[i].$1, title: _items[i].$2),
              if (i != _items.length - 1)
                const Divider(
                  height: 1,
                  thickness: 0.7,
                  color: Color(0xFF2E2E31),
                  indent: 14,
                  endIndent: 14,
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ProfileMenuItem extends StatelessWidget {
  const _ProfileMenuItem({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: ProfileLayout.menuItemHeight,
      child: Row(
        children: [
          const SizedBox(width: 14),
          Icon(icon, color: WakaColors.accent, size: 30),
          const SizedBox(width: 18),
          Expanded(
            child: FittedBox(
              alignment: Alignment.centerLeft,
              fit: BoxFit.scaleDown,
              child: Text(
                title,
                maxLines: 1,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: ProfileFontSizes.menuItem,
                  fontWeight: FontWeight.w500,
                  height: 1,
                ),
              ),
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: WakaColors.mutedText,
            size: 28,
          ),
          const SizedBox(width: 14),
        ],
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  const _LogoutButton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: ProfileLayout.horizontalPadding,
      ),
      child: Container(
        height: ProfileLayout.logoutButtonHeight,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: WakaColors.surface,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text(
          'Đăng xuất',
          style: TextStyle(
            color: WakaColors.accent,
            fontSize: ProfileFontSizes.logout,
            fontWeight: FontWeight.w500,
            height: 1,
          ),
        ),
      ),
    );
  }
}

class _SupportBubble extends StatelessWidget {
  const _SupportBubble();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Transform.translate(
          offset: const Offset(-8, 0),
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFF17191A),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF33383A)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(
                  Icons.support_agent_rounded,
                  color: WakaColors.accent,
                  size: 28,
                ),
                Text(
                  'Hỗ trợ',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
