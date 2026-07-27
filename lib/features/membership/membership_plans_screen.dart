import 'package:flutter/material.dart';

import '../../core/services/auth_api_service.dart';
import '../../core/services/commerce_api_service.dart';
import '../../core/theme/app_theme.dart';

class MembershipPlansScreen extends StatefulWidget {
  const MembershipPlansScreen({super.key});

  @override
  State<MembershipPlansScreen> createState() => _MembershipPlansScreenState();
}

class _MembershipPlansScreenState extends State<MembershipPlansScreen> {
  _PlanChannel _channel = _PlanChannel.card;
  List<_MembershipPlan> _plans = const [];

  @override
  void initState() {
    super.initState();
    _loadPlans();
  }

  Future<void> _loadPlans() async {
    try {
      final plans = await const CommerceApiService().getMembershipPlans();
      if (!mounted || plans.isEmpty) return;
      setState(() => _plans = plans.map(_MembershipPlan.fromApi).toList());
    } on Object {
      // Local data keeps the plan screen usable before the demo API is started.
    }
  }

  Future<void> _buyPlan(_MembershipPlan plan) async {
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
    try {
      await const CommerceApiService().purchaseMembership(plan.id);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Đã kích hoạt ${plan.title}.')));
    } on Object catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
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
  const _PlanCard({required this.plan, required this.onBuy});
  final _MembershipPlan plan;
  final VoidCallback onBuy;

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
            FilledButton(onPressed: onBuy, child: const Text('Mua gói')),
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

class _MembershipPlan {
  const _MembershipPlan({
    this.id = 0,
    required this.title,
    required this.subtitle,
    required this.price,
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
