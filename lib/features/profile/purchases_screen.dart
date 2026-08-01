import 'package:flutter/material.dart';

import '../../core/services/auth_api_service.dart';
import '../../core/services/commerce_api_service.dart';
import '../../core/theme/app_theme.dart';

class PurchasesScreen extends StatefulWidget {
  const PurchasesScreen({super.key});

  @override
  State<PurchasesScreen> createState() => _PurchasesScreenState();
}

class _PurchasesScreenState extends State<PurchasesScreen> {
  late Future<_PurchaseData> _purchases;

  @override
  void initState() {
    super.initState();
    _purchases = _loadPurchases();
  }

  Future<void> _refresh() async {
    final next = _loadPurchases();
    setState(() => _purchases = next);
    await next;
  }

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
        future: _purchases,
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
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
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
            ),
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
  Widget build(BuildContext context) {
    final status = _orderStatusLabel(order.status);
    final payment = _paymentLabel(order.paymentMethod, order.paymentStatus);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: WakaColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        key: ValueKey('order-history-${order.id}'),
        leading: const CircleAvatar(
          backgroundColor: Color(0x2233DDB2),
          child: Icon(Icons.local_shipping_outlined, color: WakaColors.accent),
        ),
        title: Text(
          'Đơn hàng #${order.id}',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              '${order.itemCount} sản phẩm · ${_money(order.total)}',
              style: const TextStyle(color: Colors.white60, fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(
              '$payment · $status',
              style: TextStyle(
                color: order.status == 'cancelled'
                    ? const Color(0xFFFF7585)
                    : WakaColors.accent,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          const Divider(color: Colors.white12),
          if (order.shippingAddress.isNotEmpty)
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${order.shippingRecipient}\n${order.shippingAddress}',
                style: const TextStyle(color: Colors.white60, height: 1.4),
              ),
            ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              order.status == 'payment_review'
                  ? 'ĐANG CHỜ ADMIN XÁC NHẬN THANH TOÁN'
                  : 'TIẾN TRÌNH GIAO HÀNG',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (order.shippingEvents.isEmpty)
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Chưa có cập nhật mới.',
                style: TextStyle(color: Colors.white54),
              ),
            )
          else
            for (var index = 0; index < order.shippingEvents.length; index++)
              _ShippingEventRow(
                event: order.shippingEvents[index],
                isLast: index == order.shippingEvents.length - 1,
              ),
        ],
      ),
    );
  }
}

class _ShippingEventRow extends StatelessWidget {
  const _ShippingEventRow({required this.event, required this.isLast});

  final CommerceShippingEvent event;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 22,
            child: Column(
              children: [
                Container(
                  width: 11,
                  height: 11,
                  decoration: BoxDecoration(
                    color: isLast ? WakaColors.accent : Colors.white38,
                    shape: BoxShape.circle,
                  ),
                ),
                if (!isLast)
                  Expanded(child: Container(width: 2, color: Colors.white12)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _orderStatusLabel(event.status),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (event.location.isNotEmpty)
                    Text(
                      event.location,
                      style: const TextStyle(color: WakaColors.accent),
                    ),
                  if (event.description.isNotEmpty)
                    Text(
                      event.description,
                      style: const TextStyle(
                        color: Colors.white54,
                        height: 1.35,
                      ),
                    ),
                  Text(
                    _dateTimeLabel(event.createdAt),
                    style: const TextStyle(color: Colors.white30, fontSize: 11),
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

String _dateTimeLabel(DateTime? date) {
  if (date == null) return 'Chưa xác định';
  final local = date.toLocal();
  String two(int value) => value.toString().padLeft(2, '0');
  return '${two(local.hour)}:${two(local.minute)} · '
      '${two(local.day)}/${two(local.month)}/${local.year}';
}

String _orderStatusLabel(String status) => switch (status) {
  'payment_review' => 'Chờ xác nhận thanh toán',
  'confirmed' => 'Đã xác nhận đơn hàng',
  'packing' => 'Đang chuẩn bị hàng',
  'in_transit' => 'Đang vận chuyển',
  'at_hub' => 'Đã đến kho vận',
  'out_for_delivery' => 'Đang giao đến bạn',
  'delivered' => 'Giao hàng thành công',
  'cancelled' => 'Đơn hàng đã hủy',
  _ => 'Đang xử lý',
};

String _paymentLabel(String method, String status) {
  if (method == 'cod') {
    return status == 'paid' ? 'COD · Đã thu tiền' : 'COD · Thu tiền khi nhận';
  }
  return switch (status) {
    'proof_submitted' => 'QR · Chờ admin xác nhận',
    'paid' => 'QR · Đã xác nhận tiền',
    'failed' => 'QR · Không xác nhận được',
    'refunded' => 'QR · Đã hoàn tiền',
    _ => 'QR · Chờ chuyển khoản',
  };
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
