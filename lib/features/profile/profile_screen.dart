import 'dart:async';
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/services/auth_api_service.dart';
import '../../core/services/commerce_api_service.dart';
import '../../shared/navigation/app_navigation.dart';
import '../../shared/widgets/icons/acorn_icon.dart';
import '../welcome/welcome_screen.dart';
import '../admin/admin_dashboard_screen.dart';
import '../membership/membership_plans_screen.dart';
import 'account_info_screen.dart';
import 'author_registration_screen.dart';
import 'profile_detail_screens.dart';
import 'purchases_screen.dart';
import 'profile_constants.dart';
import '../ai_assistant/ai_assistant_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const _service = CommerceApiService();

  /// Số đơn theo 3 nhóm hiển thị ở thẻ "Đơn hàng".
  int _awaitingConfirm = 0;
  int _awaitingPickup = 0;
  int _delivering = 0;

  @override
  void initState() {
    super.initState();
    _loadOrderCounts();
  }

  Future<void> _loadOrderCounts() async {
    if (!AuthSession.isSignedIn) return;
    try {
      final orders = await _service.getOrders();
      if (!mounted) return;
      setState(() {
        _awaitingConfirm = orders
            .where((o) => o.status == 'payment_review')
            .length;
        _awaitingPickup = orders
            .where((o) => o.status == 'confirmed' || o.status == 'packing')
            .length;
        _delivering = orders
            .where(
              (o) =>
                  o.status == 'in_transit' ||
                  o.status == 'at_hub' ||
                  o.status == 'out_for_delivery',
            )
            .length;
      });
    } on Object {
      // Giữ nguyên số 0 khi API chưa sẵn sàng, phần còn lại của màn vẫn dùng được.
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthSession.current?.user;
    return Stack(
      children: [
        SafeArea(
          bottom: false,
          child: RefreshIndicator(
            onRefresh: _loadOrderCounts,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              slivers: [
                const SliverToBoxAdapter(child: _ProfileHeader()),
                const SliverToBoxAdapter(child: SizedBox(height: 30)),
                SliverToBoxAdapter(
                  child: _UserRow(
                    name: user?.displayName?.isNotEmpty == true
                        ? user!.displayName!
                        : user?.identifier ?? 'Chưa đăng nhập',
                    subtitle: user == null
                        ? 'Đăng nhập để đồng bộ dữ liệu'
                        : 'Xem thông tin tài khoản',
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 30)),
                const SliverToBoxAdapter(child: _RewardCard()),
                const SliverToBoxAdapter(child: SizedBox(height: 26)),
                SliverToBoxAdapter(
                  child: _ProfileSectionTitle(
                    title: 'Đơn hàng',
                    action: 'Chi tiết đơn hàng',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const PurchasesScreen(),
                      ),
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 14)),
                SliverToBoxAdapter(
                  child: _OrderCard(
                    awaitingConfirm: _awaitingConfirm,
                    awaitingPickup: _awaitingPickup,
                    delivering: _delivering,
                  ),
                ),
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
          InkWell(
            onTap: () => _showAccountQr(context),
            customBorder: const CircleBorder(),
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(
                Icons.qr_code_2_rounded,
                color: Colors.white,
                size: 30,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAccountQr(BuildContext context) {
    final user = AuthSession.current?.user;
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: WakaColors.elevated,
        title: const Text(
          'Mã tài khoản',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 180,
              height: 180,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.qr_code_2_rounded,
                size: 150,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              user == null ? 'Chưa đăng nhập' : 'ID: ${user.id}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (user != null) ...[
              const SizedBox(height: 4),
              Text(
                user.identifier,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: WakaColors.mutedText,
                  fontSize: 13,
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('ĐÓNG'),
          ),
        ],
      ),
    );
  }
}

class _UserRow extends StatelessWidget {
  const _UserRow({required this.name, required this.subtitle});

  final String name;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final user = AuthSession.current?.user;
    final identifier = user?.identifier ?? '';
    final isEmail = identifier.contains('@');
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AccountInfoScreen(
              displayName: user?.displayName?.isNotEmpty == true
                  ? user!.displayName!
                  : 'Chưa cập nhật',
              // identifier có thể là email hoặc số điện thoại tuỳ cách đăng ký.
              phoneNumber: isEmail ? '' : identifier,
              email: isEmail ? identifier : null,
              userId: user?.id.toString() ?? '—',
            ),
          ),
        );
      },
      child: Padding(
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
              child: const Icon(
                Icons.person,
                color: Color(0xCCFFFFFF),
                size: 48,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: ProfileFontSizes.username,
                      fontWeight: FontWeight.w900,
                      height: 1.08,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
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
      ),
    );
  }
}

class _RewardCard extends StatefulWidget {
  const _RewardCard();

  @override
  State<_RewardCard> createState() => _RewardCardState();
}

class _RewardCardState extends State<_RewardCard> {
  UserMembership? _membership;
  Timer? _realtimeTimer;

  @override
  void initState() {
    super.initState();
    _loadMembership();
    _realtimeTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted && AuthSession.isSignedIn) {
        _loadMembership();
      }
    });
  }

  @override
  void dispose() {
    _realtimeTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadMembership() async {
    if (!AuthSession.isSignedIn) return;
    try {
      final membership = await const CommerceApiService().getActiveMembership();
      if (!mounted) return;
      setState(() => _membership = membership);
    } on Object {
      // Không đọc được thì cứ hiển thị "Tài khoản thường".
    }
  }

  /// Số ngày còn lại, làm tròn lên để ngày cuối vẫn hiện "còn 1 ngày".
  String get _remainingLabel {
    final remaining = _membership?.remaining ?? Duration.zero;
    if (remaining <= Duration.zero) return '';
    final days = remaining.inDays;
    if (days >= 1) return 'Còn $days ngày';
    final hours = remaining.inHours;
    if (hours >= 1) return 'Còn $hours giờ';
    return 'Sắp hết hạn';
  }

  @override
  Widget build(BuildContext context) {
    final membership = _membership;
    final hasPlan = membership != null && membership.isActive;
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
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (hasPlan) ...[
                              const Icon(
                                Icons.workspace_premium_rounded,
                                color: WakaColors.gold,
                                size: 18,
                              ),
                              const SizedBox(width: 5),
                            ],
                            Flexible(
                              child: Text(
                                hasPlan
                                    ? membership.planTitle
                                    : 'Tài khoản thường',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: hasPlan
                                      ? WakaColors.gold
                                      : Colors.white,
                                  fontSize: ProfileFontSizes.rewardTitle,
                                  fontWeight: FontWeight.w900,
                                  height: 1.1,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (hasPlan && _remainingLabel.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            _remainingLabel,
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                              height: 1,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    borderRadius: BorderRadius.circular(24),
                    onTap: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const MembershipPlansScreen(),
                        ),
                      );
                      // Quay lại có thể đã mua/gia hạn nên đọc lại trạng thái.
                      await _loadMembership();
                    },
                    child: Container(
                      height: 40,
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFD625), Color(0xFFFFA810)],
                        ),
                      ),
                      child: Text(
                        hasPlan ? 'GIA HẠN' : 'NÂNG CẤP GÓI',
                        style: const TextStyle(
                          color: Color(0xFF4F3B00),
                          fontSize: ProfileFontSizes.upgradeButton,
                          fontWeight: FontWeight.w900,
                          height: 1,
                        ),
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
                      description:
                          'Điểm tích luỹ khi mua sách hoặc gia hạn gói Hội '
                          'viên. Dùng để đổi voucher giảm giá ở màn Thanh toán.',
                    ),
                  ),
                  _VerticalDivider(),
                  Expanded(
                    child: _RewardItem(
                      label: 'Sồi',
                      customIcon: AcornIcon(color: WakaColors.gold),
                      color: WakaColors.gold,
                      description:
                          'Hạt Sồi nhận được khi đọc sách mỗi ngày và hoàn '
                          'thành mục tiêu đọc. Đổi được sách trong Kho Hiệu Sồi.',
                    ),
                  ),
                  _VerticalDivider(),
                  Expanded(
                    child: _RewardItem(
                      label: 'Lá xanh',
                      icon: Icons.eco_outlined,
                      color: Color(0xFF72BF48),
                      description:
                          'Lá xanh thể hiện số giấy đã tiết kiệm khi bạn chọn '
                          'sách điện tử thay vì sách in.',
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
    required this.description,
    this.icon,
    this.customIcon,
  });

  final String label;
  final Color color;

  /// Giải thích hiển thị khi bấm vào — hệ thống điểm thưởng chưa có API.
  final String description;
  final IconData? icon;
  final Widget? customIcon;

  void _showInfo(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: WakaColors.elevated,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  customIcon ?? Icon(icon, color: color, size: 28),
                  const SizedBox(width: 10),
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 21,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                description,
                style: const TextStyle(
                  color: WakaColors.mutedText,
                  height: 1.5,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: WakaColors.surface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: Colors.white38,
                      size: 18,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Số dư hiện là 0 vì hệ thống tích điểm chưa được kết '
                        'nối với máy chủ.',
                        style: TextStyle(color: Colors.white38, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _showInfo(context),
      child: Padding(
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
  const _OrderCard({
    required this.awaitingConfirm,
    required this.awaitingPickup,
    required this.delivering,
  });

  final int awaitingConfirm;
  final int awaitingPickup;
  final int delivering;

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
        child: Row(
          children: [
            _OrderItem(
              icon: Icons.receipt_long_outlined,
              label: 'Chờ xác nhận',
              count: awaitingConfirm,
              onTap: () => _openOrders(context),
            ),
            _OrderItem(
              icon: Icons.inventory_2_outlined,
              label: 'Chờ lấy hàng',
              count: awaitingPickup,
              onTap: () => _openOrders(context),
            ),
            _OrderItem(
              icon: Icons.local_shipping_outlined,
              label: 'Đang giao hàng',
              count: delivering,
              onTap: () => _openOrders(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderItem extends StatelessWidget {
  const _OrderItem({
    required this.icon,
    required this.label,
    required this.count,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
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
                if (count > 0)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      constraints: const BoxConstraints(minWidth: 22),
                      height: 22,
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF2F6E),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Text(
                        count > 99 ? '99+' : '$count',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
              ],
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
      ),
    );
  }
}

void _openOrders(BuildContext context) {
  Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(builder: (_) => const PurchasesScreen()));
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
            InkWell(
              onTap: () => _showReadingGoalSheet(context),
              borderRadius: BorderRadius.circular(24),
              child: Container(
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
            ),
          ],
        ),
      ),
    );
  }
}

/// Mục tiêu đọc chỉ lưu tạm trong phiên vì backend chưa có bảng lưu mục tiêu.
void _showReadingGoalSheet(BuildContext context) {
  var minutes = 20.0;
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: WakaColors.elevated,
    showDragHandle: true,
    builder: (sheetContext) => StatefulBuilder(
      builder: (context, setSheetState) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Mục tiêu đọc mỗi ngày',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Đặt một mục tiêu vừa sức để giữ thói quen đọc đều đặn.',
                style: TextStyle(color: WakaColors.mutedText),
              ),
              const SizedBox(height: 20),
              Center(
                child: Text(
                  '${minutes.round()} phút',
                  style: const TextStyle(
                    color: WakaColors.accent,
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Slider(
                value: minutes,
                min: 5,
                max: 120,
                divisions: 23,
                activeColor: WakaColors.accent,
                onChanged: (value) => setSheetState(() => minutes = value),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () {
                  Navigator.pop(sheetContext);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Đã đặt mục tiêu ${minutes.round()} phút mỗi ngày.',
                      ),
                    ),
                  );
                },
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  backgroundColor: WakaColors.accent,
                  foregroundColor: Colors.black,
                ),
                child: const Text(
                  'LƯU MỤC TIÊU',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
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
              InkWell(
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Bảng xếp hạng độc giả cần backend thống kê số phút '
                      'đọc, hiện chưa có dữ liệu.',
                    ),
                  ),
                ),
                borderRadius: BorderRadius.circular(20),
                child: Container(
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

  @override
  Widget build(BuildContext context) {
    final items = <({IconData icon, String title, VoidCallback? onTap})>[
      if (AuthSession.current?.user.isAdmin ?? false)
        (
          icon: Icons.admin_panel_settings_outlined,
          title: 'Trung tâm quản trị',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const AdminDashboardScreen(),
            ),
          ),
        ),
      (
        icon: Icons.history_rounded,
        title: 'Đơn hàng và vận chuyển',
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const PurchasesScreen()),
        ),
      ),
      (
        icon: Icons.notifications_none_rounded,
        title: 'Thông báo',
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const NotificationsScreen()),
        ),
      ),
      (
        icon: Icons.location_on_outlined,
        title: 'Địa chỉ',
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const AddressBookScreen()),
        ),
      ),
      (
        icon: Icons.edit_note_rounded,
        title: 'Đăng ký làm tác giả',
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const AuthorRegistrationScreen(),
          ),
        ),
      ),
      (
        icon: Icons.settings_outlined,
        title: 'Thông tin chung',
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const GeneralInfoScreen()),
        ),
      ),
      (
        icon: Icons.help_outline_rounded,
        title: 'Trợ giúp và góp ý',
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const HelpFeedbackScreen()),
        ),
      ),
    ];
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
            for (var i = 0; i < items.length; i++) ...[
              _ProfileMenuItem(
                icon: items[i].icon,
                title: items[i].title,
                onTap: items[i].onTap,
              ),
              if (i != items.length - 1)
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
  const _ProfileMenuItem({required this.icon, required this.title, this.onTap});

  final IconData icon;
  final String title;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
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
      child: GestureDetector(
        onTap: () {
          AuthSession.clear();
          AppNavigation.replaceAll(context, const WelcomeScreen());
        },
        behavior: HitTestBehavior.opaque,
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
          child: InkWell(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const AiAssistantScreen(),
              ),
            ),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFF17191A),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF33383A)),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
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
        ),
      ],
    );
  }
}
