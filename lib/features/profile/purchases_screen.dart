import 'package:flutter/material.dart';

import '../../core/services/auth_api_service.dart';
import '../../core/services/commerce_api_service.dart';
import '../../core/theme/app_theme.dart';

class PurchasesScreen extends StatelessWidget {
  const PurchasesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    if (!AuthSession.isSignedIn) {
      return const _PurchaseScaffold(
        child: Center(
          child: Text(
            'Đăng nhập để xem đơn hàng và gói cước đã mua.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
        ),
      );
    }
    return _PurchaseScaffold(
      child: FutureBuilder<_PurchaseData>(
        future: _loadPurchases(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(
              child: CircularProgressIndicator(color: WakaColors.accent),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Text(
                  snapshot.error.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
            );
          }
          final data = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
            children: [
              const _SectionLabel('Gói hội viên'),
              const SizedBox(height: 10),
              if (data.memberships.isEmpty)
                const _EmptyCard('Bạn chưa mua gói hội viên nào.')
              else
                ...data.memberships.map(_MembershipHistoryCard.new),
              const SizedBox(height: 24),
              const _SectionLabel('Đơn hàng'),
              const SizedBox(height: 10),
              if (data.orders.isEmpty)
                const _EmptyCard('Bạn chưa có đơn hàng nào.')
              else
                ...data.orders.map(_OrderHistoryCard.new),
            ],
          );
        },
      ),
    );
  }

  Future<_PurchaseData> _loadPurchases() async {
    const service = CommerceApiService();
    final memberships = await service.getMyMemberships();
    final orders = await service.getOrders();
    return _PurchaseData(memberships: memberships, orders: orders);
  }
}

class _PurchaseScaffold extends StatelessWidget {
  const _PurchaseScaffold({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: WakaColors.background,
    body: SafeArea(
      child: Column(
        children: [
          SizedBox(
            height: 58,
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    color: Colors.white,
                  ),
                ),
                const Expanded(
                  child: Text(
                    'Dữ liệu đã lưu',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
          ),
          Expanded(child: child),
        ],
      ),
    ),
  );
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      color: Colors.white,
      fontSize: 19,
      fontWeight: FontWeight.w900,
    ),
  );
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard(this.message);
  final String message;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: WakaColors.surface,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(message, style: const TextStyle(color: Colors.white60)),
  );
}

class _MembershipHistoryCard extends StatelessWidget {
  const _MembershipHistoryCard(this.membership);
  final UserMembership membership;
  @override
  Widget build(BuildContext context) => _HistoryCard(
    icon: Icons.workspace_premium_rounded,
    title: membership.planTitle,
    subtitle: 'Hiệu lực đến ${_dateLabel(membership.expiresAt)}',
    status: membership.status == 'active' ? 'Đang hoạt động' : 'Đã hết hạn',
    active: membership.status == 'active',
  );
}

class _OrderHistoryCard extends StatelessWidget {
  const _OrderHistoryCard(this.order);
  final CommerceOrder order;
  @override
  Widget build(BuildContext context) => _HistoryCard(
    icon: Icons.receipt_long_outlined,
    title: 'Đơn hàng #${order.id}',
    subtitle:
        '${order.itemCount} sản phẩm · ${_money(order.total)} · ${_dateLabel(order.createdAt)}',
    status: order.status == 'paid' ? 'Đã thanh toán' : 'Chờ thanh toán',
    active: order.status == 'paid',
  );
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.status,
    required this.active,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final String status;
  final bool active;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: WakaColors.surface,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        CircleAvatar(
          backgroundColor: const Color(0x2233DDB2),
          child: Icon(icon, color: WakaColors.accent),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                subtitle,
                style: const TextStyle(color: Colors.white60, fontSize: 12),
              ),
            ],
          ),
        ),
        Text(
          status,
          style: TextStyle(
            color: active ? WakaColors.accent : Colors.white54,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

class _PurchaseData {
  const _PurchaseData({required this.memberships, required this.orders});
  final List<UserMembership> memberships;
  final List<CommerceOrder> orders;
}

String _dateLabel(DateTime? date) {
  if (date == null) return 'Chưa xác định';
  return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}

String _money(num value) {
  final text = value.round().toString();
  final buffer = StringBuffer();
  for (var index = 0; index < text.length; index++) {
    buffer.write(text[index]);
    final remaining = text.length - index - 1;
    if (remaining > 0 && remaining % 3 == 0) buffer.write('.');
  }
  return '$bufferđ';
}
