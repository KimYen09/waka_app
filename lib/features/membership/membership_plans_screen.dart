import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/services/auth_api_service.dart';
import '../../core/services/commerce_api_service.dart';
import '../../core/theme/app_theme.dart';
import '../shop/shop_checkout_screen.dart';
import '../shop/shop_vnpay_payment_screen.dart';

class MembershipPlansScreen extends StatefulWidget {
  const MembershipPlansScreen({super.key});

  @override
  State<MembershipPlansScreen> createState() => _MembershipPlansScreenState();
}

class _MembershipPlansScreenState extends State<MembershipPlansScreen> {
  _PlanChannel _channel = _PlanChannel.card;
  List<_MembershipPlan> _plans = const [];
  UserMembership? _activeMembership;
  UserMembership? _pendingMembership;
  Timer? _countdownTimer;
  bool _isBuying = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      const service = CommerceApiService();
      final plansFuture = service.getMembershipPlans();
      final membershipsFuture = AuthSession.isSignedIn
          ? service.getMyMemberships()
          : Future<List<UserMembership>>.value(const []);
      final plans = await plansFuture;
      final memberships = await membershipsFuture;
      UserMembership? membership;
      UserMembership? pending;
      for (final item in memberships) {
        if (membership == null && item.isActive) membership = item;
        if (pending == null && item.status == 'pending') pending = item;
      }
      if (!mounted) return;
      setState(() {
        if (plans.isNotEmpty) {
          _plans = plans.map(_MembershipPlan.fromApi).toList();
        }
        _activeMembership = membership;
        _pendingMembership = pending;
      });
      _startCountdown();
    } on Object {
      // Local data keeps the plan screen usable before the demo API is started.
    }
  }

  Future<void> _buyPlan(_MembershipPlan plan) async {
    if (_isBuying) return;
    if (_pendingMembership != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Gói đang chờ admin duyệt, bạn chưa thể tạo giao dịch khác.',
          ),
        ),
      );
      return;
    }
    if (_activeMembership case final active?) {
      if (plan.amount < active.price) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Bạn chỉ có thể gia hạn hoặc nâng cấp lên gói cao hơn.',
            ),
          ),
        );
        return;
      }
    }
    if (!AuthSession.isSignedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng đăng nhập để mua gói cước.')),
      );
      return;
    }
    if (plan.id <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hãy chạy backend để hoàn tất mua gói demo.'),
        ),
      );
      return;
    }
    if (plan.channel != 'card') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Thanh toán SMS chưa được kết nối nhà mạng. Vui lòng chọn '
            'Chuyển khoản / Thẻ.',
          ),
        ),
      );
      return;
    }
    final method = await _chooseCardPaymentMethod();
    if (method == null || !mounted) return;
    try {
      setState(() => _isBuying = true);
      if (method == _CardPaymentMethod.vnpay) {
        await _purchaseWithVnpay(plan);
      } else {
        await _purchaseWithBankTransfer(plan);
      }
    } on Object catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) setState(() => _isBuying = false);
    }
  }

  /// Chuyển khoản QR: admin phải kiểm tra tiền về rồi mới duyệt.
  Future<void> _purchaseWithBankTransfer(_MembershipPlan plan) async {
    final transactionRef = 'WAKAGOI${DateTime.now().millisecondsSinceEpoch}';
    final transferred = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => ShopQrPaymentScreen(
          amount: plan.amount.round(),
          orderCode: transactionRef,
          paymentPurpose: plan.title,
          requiresReview: true,
        ),
      ),
    );
    if (transferred != true || !mounted) return;
    final result = await const CommerceApiService().purchaseMembership(
      plan.id,
      transactionRef: transactionRef,
    );
    if (!mounted) return;
    setState(() => _pendingMembership = result.membership);
    _startCountdown();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Đã gửi xác nhận chuyển khoản ${plan.title}. Vui lòng chờ admin '
          'duyệt để kích hoạt và mở khóa nội dung.',
        ),
      ),
    );
  }

  /// VNPay: gói tự kích hoạt khi IPN báo về, không cần admin duyệt.
  Future<void> _purchaseWithVnpay(_MembershipPlan plan) async {
    final result = await const CommerceApiService().purchaseMembership(
      plan.id,
      paymentMethod: 'vnpay',
    );
    final paymentUrl = result.paymentUrl;
    if (!mounted) return;
    if (paymentUrl == null || paymentUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Backend chưa trả về liên kết VNPay. Kiểm tra VNP_TMN_CODE và '
            'VNP_HASH_SECRET.',
          ),
        ),
      );
      return;
    }
    setState(() => _pendingMembership = result.membership);
    await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => ShopVnpayPaymentScreen(paymentUrl: paymentUrl),
      ),
    );
    // Trình duyệt ngoài không trả kết quả về app, và IPN cũng chạy bất đồng
    // bộ, nên trạng thái thật chỉ có ở backend — đọc lại vài nhịp.
    for (var attempt = 0; attempt < 4; attempt++) {
      if (attempt > 0) {
        await Future<void>.delayed(const Duration(milliseconds: 1200));
      }
      if (!mounted) return;
      await _loadData();
      if (!mounted) return;
      if (_activeMembership?.isActive == true) break;
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _activeMembership?.isActive == true
              ? 'Gói ${plan.title} đã được kích hoạt.'
              : 'Đang chờ VNPay xác nhận giao dịch. Gói sẽ tự kích hoạt ngay '
                    'khi thanh toán được ghi nhận.',
        ),
      ),
    );
  }

  Future<_CardPaymentMethod?> _chooseCardPaymentMethod() {
    return showModalBottomSheet<_CardPaymentMethod>(
      context: context,
      backgroundColor: WakaColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 18, 20, 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Chọn hình thức thanh toán',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(
                Icons.credit_card_rounded,
                color: WakaColors.gold,
              ),
              title: const Text(
                'Cổng VNPay',
                style: TextStyle(color: Colors.white),
              ),
              subtitle: const Text(
                'Kích hoạt tự động ngay sau khi thanh toán',
                style: TextStyle(color: Colors.white54),
              ),
              onTap: () =>
                  Navigator.pop(sheetContext, _CardPaymentMethod.vnpay),
            ),
            ListTile(
              leading: const Icon(
                Icons.account_balance_rounded,
                color: WakaColors.accent,
              ),
              title: const Text(
                'Chuyển khoản QR',
                style: TextStyle(color: Colors.white),
              ),
              subtitle: const Text(
                'Admin kiểm tra và duyệt thủ công',
                style: TextStyle(color: Colors.white54),
              ),
              onTap: () =>
                  Navigator.pop(sheetContext, _CardPaymentMethod.bankTransfer),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Future<void> _cancelMembership() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hủy đăng ký?'),
        content: const Text(
          'Thao tác kiểm thử này sẽ hủy cả gói đang hoạt động và giao dịch đang chờ duyệt.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('GIỮ LẠI'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('HỦY ĐĂNG KÝ'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await const CommerceApiService().cancelMembership();
      if (!mounted) return;
      setState(() {
        _activeMembership = null;
        _pendingMembership = null;
      });
      _countdownTimer?.cancel();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã hủy đăng ký để kiểm thử.')),
      );
    } on Object catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    }
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    if (_activeMembership?.isActive != true) return;
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_activeMembership?.isActive != true) {
        _countdownTimer?.cancel();
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final source = _plans.isEmpty ? _fallbackPlans : _plans;
    final plans = source
        .where(
          (plan) =>
              plan.channel == (_channel == _PlanChannel.card ? 'card' : 'sms'),
        )
        .toList(growable: false);
    return Scaffold(
      backgroundColor: WakaColors.background,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 16, 6),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: 'Quay lại',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                        color: Colors.white,
                      ),
                    ),
                    const Expanded(
                      child: Text(
                        'Gói hội viên',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 21,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: _MembershipIntro()),
            if (_activeMembership case final membership?)
              SliverToBoxAdapter(
                child: _ActiveMembershipCard(
                  membership: membership,
                  onCancel: _cancelMembership,
                ),
              ),
            if (_pendingMembership case final membership?)
              SliverToBoxAdapter(
                child: _PendingMembershipCard(
                  membership: membership,
                  onCancel: _cancelMembership,
                ),
              ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 22, 16, 16),
                child: _ChannelSelector(
                  selected: _channel,
                  onChanged: (value) => setState(() => _channel = value),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              sliver: SliverList.separated(
                itemCount: plans.length,
                separatorBuilder: (_, _) => const SizedBox(height: 16),
                itemBuilder: (context, index) => _PlanCard(
                  plan: plans[index],
                  isBuying: _isBuying,
                  onBuy: () => _buyPlan(plans[index]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MembershipIntro extends StatelessWidget {
  const _MembershipIntro();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
    child: Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A4950), Color(0xFF17334E)],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.workspace_premium_rounded,
            color: WakaColors.gold,
            size: 32,
          ),
          SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Đọc không giới hạn',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Nghe và đọc hơn 20.000 nội dung thuộc Kho sách Hội viên.',
                  style: TextStyle(color: Colors.white70, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

enum _PlanChannel { card, sms }

/// Hai cách trả tiền cho kênh "Chuyển khoản / Thẻ": VNPay xác nhận tự động
/// qua IPN, chuyển khoản QR cần admin duyệt tay.
enum _CardPaymentMethod { vnpay, bankTransfer }

class _ChannelSelector extends StatelessWidget {
  const _ChannelSelector({required this.selected, required this.onChanged});
  final _PlanChannel selected;
  final ValueChanged<_PlanChannel> onChanged;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: _ChannelButton(
          label: 'Chuyển khoản / Thẻ',
          icon: Icons.credit_card_rounded,
          selected: selected == _PlanChannel.card,
          onTap: () => onChanged(_PlanChannel.card),
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: _ChannelButton(
          label: 'Thanh toán SMS',
          icon: Icons.sms_rounded,
          selected: selected == _PlanChannel.sms,
          onTap: () => onChanged(_PlanChannel.sms),
        ),
      ),
    ],
  );
}

class _ChannelButton extends StatelessWidget {
  const _ChannelButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      height: 66,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: selected ? WakaColors.accent : WakaColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: selected ? Colors.white : Colors.white70, size: 20),
          const SizedBox(width: 7),
          Flexible(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: selected ? Colors.white : Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.onBuy,
    required this.isBuying,
  });
  final _MembershipPlan plan;
  final VoidCallback onBuy;
  final bool isBuying;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: WakaColors.surface,
      borderRadius: BorderRadius.circular(16),
      border: plan.highlighted
          ? Border.all(color: WakaColors.gold, width: 1.4)
          : null,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (plan.badge.isNotEmpty)
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFFF5C8D),
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(
                plan.badge,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        Text(
          plan.title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 19,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 5),
        Text(plan.subtitle, style: const TextStyle(color: Colors.white60)),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              plan.price,
              style: const TextStyle(
                color: WakaColors.gold,
                fontSize: 25,
                fontWeight: FontWeight.w900,
              ),
            ),
            if (plan.oldPrice.isNotEmpty) ...[
              const SizedBox(width: 9),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  plan.oldPrice,
                  style: const TextStyle(
                    color: Colors.white38,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
              ),
            ],
            const Spacer(),
            FilledButton(
              onPressed: isBuying ? null : onBuy,
              child: Text(isBuying ? 'Đang xử lý…' : 'Mua/Gia hạn'),
            ),
          ],
        ),
        if (plan.gift.isNotEmpty) ...[
          const Divider(color: Colors.white12, height: 24),
          Row(
            children: [
              const Icon(
                Icons.card_giftcard_rounded,
                color: WakaColors.accent,
                size: 18,
              ),
              const SizedBox(width: 7),
              Text(
                plan.gift,
                style: const TextStyle(
                  color: WakaColors.accent,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ],
    ),
  );
}

class _ActiveMembershipCard extends StatelessWidget {
  const _ActiveMembershipCard({
    required this.membership,
    required this.onCancel,
  });

  final UserMembership membership;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final remaining = membership.remaining;
    final days = remaining.inDays;
    final hours = remaining.inHours.remainder(24);
    final minutes = remaining.inMinutes.remainder(60);
    final seconds = remaining.inSeconds.remainder(60);
    final countdown = membership.isActive
        ? '$days ngày ${hours.toString().padLeft(2, '0')}:'
              '${minutes.toString().padLeft(2, '0')}:'
              '${seconds.toString().padLeft(2, '0')}'
        : 'Đã hết hạn';
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 18, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF173F35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: WakaColors.accent),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.verified_rounded,
            color: WakaColors.accent,
            size: 34,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  membership.isActive
                      ? 'Gói đã mua đang hoạt động'
                      : 'Gói đã mua',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  membership.planTitle,
                  style: const TextStyle(color: WakaColors.gold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Thời hạn còn lại: $countdown',
                  style: const TextStyle(color: Colors.white70),
                ),
                TextButton(
                  onPressed: onCancel,
                  child: const Text('HỦY ĐĂNG KÝ (TEST)'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PendingMembershipCard extends StatelessWidget {
  const _PendingMembershipCard({
    required this.membership,
    required this.onCancel,
  });
  final UserMembership membership;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.fromLTRB(16, 18, 16, 0),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFF493A18),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: WakaColors.gold),
    ),
    child: Row(
      children: [
        const Icon(Icons.hourglass_top_rounded, color: WakaColors.gold),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Đang chờ admin kiểm tra chuyển khoản',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                membership.planTitle,
                style: const TextStyle(color: Colors.white70),
              ),
              TextButton(
                onPressed: onCancel,
                child: const Text('HỦY ĐĂNG KÝ (TEST)'),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _MembershipPlan {
  const _MembershipPlan({
    this.id = 0,
    required this.title,
    required this.subtitle,
    required this.price,
    this.amount = 0,
    this.oldPrice = '',
    this.badge = '',
    this.gift = '',
    this.highlighted = false,
    this.channel = 'card',
  });
  factory _MembershipPlan.fromApi(MembershipPlan plan) => _MembershipPlan(
    id: plan.id,
    title: plan.title,
    subtitle: plan.description,
    price: _formatPrice(plan.price),
    amount: plan.price,
    oldPrice: plan.listPrice > 0 ? _formatPrice(plan.listPrice) : '',
    badge:
        plan.bonusDescription.startsWith('TIẾT') ||
            plan.bonusDescription.startsWith('ƯU')
        ? plan.bonusDescription
        : '',
    gift: plan.bonusDescription.startsWith('Tặng') ? plan.bonusDescription : '',
    highlighted: plan.durationDays >= 365,
    channel: plan.paymentChannel,
  );
  final int id;
  final String title;
  final String subtitle;
  final String price;
  final num amount;
  final String oldPrice;
  final String badge;
  final String gift;
  final bool highlighted;
  final String channel;
}

const _fallbackPlans = <_MembershipPlan>[
  _MembershipPlan(
    title: 'WAKA 3 THÁNG',
    subtitle: '90 ngày đọc/nghe sách',
    price: '199.000đ',
    oldPrice: '207.000đ',
    badge: 'TIẾT KIỆM 10%',
  ),
  _MembershipPlan(
    title: 'WAKA 6 THÁNG',
    subtitle: '183 ngày đọc/nghe sách',
    price: '399.000đ',
    oldPrice: '414.000đ',
  ),
  _MembershipPlan(
    title: 'WAKA 12 THÁNG',
    subtitle: '365 ngày đọc/nghe sách',
    price: '499.000đ',
    oldPrice: '828.000đ',
    badge: 'ƯU ĐÃI NHẤT 40%',
    gift: 'Tặng thêm 02 tháng',
    highlighted: true,
  ),
  _MembershipPlan(
    title: 'WAKA 1 NGÀY',
    subtitle: 'Gia hạn sau 1 ngày',
    price: '5.000đ',
    gift: 'Tặng 300MB DATA',
    channel: 'sms',
  ),
  _MembershipPlan(
    title: 'WAKA 7 NGÀY',
    subtitle: 'Gia hạn sau 7 ngày',
    price: '20.000đ',
    gift: 'Tặng 1GB DATA',
    channel: 'sms',
  ),
];

String _formatPrice(num value) {
  final text = value.round().toString();
  final buffer = StringBuffer();
  for (var index = 0; index < text.length; index++) {
    buffer.write(text[index]);
    final remaining = text.length - index - 1;
    if (remaining > 0 && remaining % 3 == 0) buffer.write('.');
  }
  return '$bufferđ';
}
