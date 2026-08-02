import 'package:flutter/material.dart';

import '../../core/services/auth_api_service.dart';
import '../../core/theme/app_theme.dart';
import '../shop/shop_address_store.dart';

/// Khung chung cho các màn con mở từ trang Cá nhân.
class _DetailScaffold extends StatelessWidget {
  const _DetailScaffold({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WakaColors.background,
      appBar: AppBar(
        backgroundColor: WakaColors.background,
        surfaceTintColor: Colors.transparent,
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: child,
    );
  }
}

// ---------------------------------------------------------------------------
// Thông báo
// ---------------------------------------------------------------------------

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  /// Nội dung mẫu: backend chưa có bảng thông báo.
  static const _items = [
    (
      icon: Icons.local_shipping_outlined,
      color: WakaColors.accent,
      title: 'Đơn hàng đang được giao',
      body: 'Kiện hàng của bạn đã rời kho Cầu Giấy và đang trên đường tới.',
      time: '2 giờ trước',
    ),
    (
      icon: Icons.workspace_premium_outlined,
      color: WakaColors.gold,
      title: 'Ưu đãi Hội viên 12 tháng',
      body: 'Giảm còn 499.000đ và tặng thêm 02 tháng, áp dụng tới cuối tháng.',
      time: '1 ngày trước',
    ),
    (
      icon: Icons.auto_stories_outlined,
      color: Color(0xFF8EB1FF),
      title: 'Sách mới trong Kho Hội viên',
      body: '12 tựa sách vừa được thêm vào mục Sách mới mỗi ngày.',
      time: '3 ngày trước',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return _DetailScaffold(
      title: 'Thông báo',
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        itemCount: _items.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final item = _items[index];
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: WakaColors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: item.color.withValues(alpha: 0.16),
                  child: Icon(item.icon, color: item.color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        item.body,
                        style: const TextStyle(
                          color: WakaColors.mutedText,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        item.time,
                        style: const TextStyle(
                          color: Colors.white30,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Địa chỉ nhận hàng - đọc từ bộ nhớ thiết bị theo tài khoản đang đăng nhập
// ---------------------------------------------------------------------------

class AddressBookScreen extends StatefulWidget {
  const AddressBookScreen({super.key, this.store = const SecureShopAddressStore()});

  final ShopAddressStore store;

  @override
  State<AddressBookScreen> createState() => _AddressBookScreenState();
}

class _AddressBookScreenState extends State<AddressBookScreen> {
  ShopShippingAddress? _address;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final ownerKey = AuthSession.current?.user.id.toString() ?? 'guest';
      final address = await widget.store.read(ownerKey);
      if (!mounted) return;
      setState(() {
        _address = address;
        _isLoading = false;
      });
    } on Object {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final address = _address;
    return _DetailScaffold(
      title: 'Địa chỉ nhận hàng',
      child: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: WakaColors.accent),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
              children: [
                if (address == null)
                  const _EmptyNote(
                    icon: Icons.location_off_outlined,
                    message:
                        'Chưa có địa chỉ nào được lưu.\nĐịa chỉ sẽ được lưu tự '
                        'động khi bạn đặt hàng lần đầu ở màn Thanh toán.',
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: WakaColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0x5520D5A2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0x2220D5A2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                address.label,
                                style: const TextStyle(
                                  color: WakaColors.accent,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Mặc định',
                              style: TextStyle(
                                color: Colors.white38,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '${address.recipient}  •  ${address.phone}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          address.fullAddress,
                          style: const TextStyle(
                            color: WakaColors.mutedText,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
                const Text(
                  'Muốn đổi địa chỉ, vào giỏ hàng và bấm MUA HÀNG để mở màn '
                  'Thanh toán — địa chỉ mới sẽ được lưu lại cho lần sau.',
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
    );
  }
}

// ---------------------------------------------------------------------------
// Thông tin chung
// ---------------------------------------------------------------------------

class GeneralInfoScreen extends StatelessWidget {
  const GeneralInfoScreen({super.key});

  static const _rows = [
    ('Phiên bản ứng dụng', '1.0.0 (build 1)'),
    ('Nhà phát hành', 'Waka Demo'),
    ('Điều khoản sử dụng', 'Đã chấp nhận'),
    ('Chính sách bảo mật', 'Phiên bản 2026.01'),
    ('Ngôn ngữ', 'Tiếng Việt'),
  ];

  @override
  Widget build(BuildContext context) {
    return _DetailScaffold(
      title: 'Thông tin chung',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          Container(
            decoration: BoxDecoration(
              color: WakaColors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                for (var i = 0; i < _rows.length; i++) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _rows[i].$1,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        Text(
                          _rows[i].$2,
                          style: const TextStyle(color: WakaColors.mutedText),
                        ),
                      ],
                    ),
                  ),
                  if (i != _rows.length - 1)
                    const Divider(
                      height: 1,
                      thickness: 0.7,
                      color: Color(0xFF2E2E31),
                      indent: 16,
                      endIndent: 16,
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Trợ giúp và góp ý
// ---------------------------------------------------------------------------

class HelpFeedbackScreen extends StatelessWidget {
  const HelpFeedbackScreen({super.key});

  static const _faqs = [
    (
      question: 'Làm sao để đọc sách Hội viên?',
      answer:
          'Mua một gói Hội viên trong mục Gói cước ở Trang chủ. Sau khi kích '
          'hoạt, toàn bộ sách gắn nhãn HỘI VIÊN sẽ mở khoá.',
    ),
    (
      question: 'Tôi đã chuyển khoản nhưng đơn chưa được xác nhận?',
      answer:
          'Đơn thanh toán QR cần quản trị viên đối soát với sao kê ngân hàng '
          'rồi mới chuyển sang trạng thái đã thanh toán. Thường mất vài giờ '
          'làm việc.',
    ),
    (
      question: 'Sách đã mua có đọc ngoại tuyến được không?',
      answer:
          'Tính năng tải sách về máy đang được phát triển, hiện chỉ đọc được '
          'khi có kết nối mạng.',
    ),
    (
      question: 'Làm sao trở thành tác giả trên Waka?',
      answer:
          'Tính năng nộp hồ sơ tác giả đang được hoàn thiện. Trong lúc chờ, '
          'bạn có thể liên hệ tổng đài để được hướng dẫn.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return _DetailScaffold(
      title: 'Trợ giúp và góp ý',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1A4950), Color(0xFF17334E)],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.support_agent_rounded,
                  color: WakaColors.accent,
                  size: 32,
                ),
                SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tổng đài hỗ trợ',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '1900 636 111 — 8:00 đến 22:00 hằng ngày',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const Text(
            'Câu hỏi thường gặp',
            style: TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          for (final faq in _faqs)
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: WakaColors.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              clipBehavior: Clip.antiAlias,
              child: Theme(
                data: Theme.of(
                  context,
                ).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  iconColor: WakaColors.accent,
                  collapsedIconColor: Colors.white54,
                  title: Text(
                    faq.question,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        faq.answer,
                        style: const TextStyle(
                          color: WakaColors.mutedText,
                          height: 1.45,
                        ),
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

class _EmptyNote extends StatelessWidget {
  const _EmptyNote({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Icon(icon, color: Colors.white24, size: 54),
          const SizedBox(height: 14),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: WakaColors.mutedText,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}
