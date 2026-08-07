import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; // <-- THÊM IMPORT NÀY ĐỂ MỞ WEB

import '../../core/services/auth_api_service.dart';
import '../../core/services/commerce_api_service.dart';
import '../../core/theme/app_theme.dart';
import '../shop/shop_address_store.dart';

// Hàm hỗ trợ mở URL
// Thay thế hàm _launchUrl cũ bằng hàm này:
Future<void> _launchUrl(String urlString) async {
  final uri = Uri.parse(urlString);
  try {
    // Ép mở luôn, không cần hỏi (canLaunchUrl) nữa
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (e) {
    debugPrint('Lỗi không thể mở link: $e');
  }
}

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
// Thông tin chung — bản clone theo ảnh (nhóm mục có icon vuông bo góc)
// ---------------------------------------------------------------------------

/// Mô tả 1 dòng cài đặt: icon (nền màu), tiêu đề, và hành động khi bấm.
class _SettingsRowData {
  const _SettingsRowData({
    required this.icon,
    required this.iconBg,
    required this.title,
    this.onTap,
  });

  final IconData icon;
  final Color iconBg;
  final String title;
  final VoidCallback? onTap;
}

/// Một nhóm mục, có tiêu đề nhóm (ví dụ "Cài đặt chung").
class _SettingsSectionData {
  const _SettingsSectionData({required this.title, required this.rows});

  final String title;
  final List<_SettingsRowData> rows;
}

class GeneralInfoScreen extends StatelessWidget {
  const GeneralInfoScreen({super.key});

  // Danh sách nhóm mục, khớp với thứ tự trong ảnh mẫu.
  List<_SettingsSectionData> _sections(BuildContext context) => [
    _SettingsSectionData(
      title: 'Cài đặt chung',
      rows: [
        _SettingsRowData(
          icon: Icons.favorite,
          iconBg: const Color(0xFFEF5350),
          title: 'Thể loại sách yêu thích',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const FavoriteCategoryScreen(
                kind: FavoriteCategoryKind.books,
              ),
            ),
          ),
        ),
        _SettingsRowData(
          icon: Icons.favorite,
          iconBg: const Color(0xFF29B6F6),
          title: 'Thể loại truyện tranh yêu thích',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const FavoriteCategoryScreen(
                kind: FavoriteCategoryKind.comics,
              ),
            ),
          ),
        ),
        const _SettingsRowData(
          icon: Icons.notifications,
          iconBg: Color(0xFFEF5350),
          title: 'Cài đặt nhận thông báo',
        ),
      ],
    ),
    _SettingsSectionData(
      title: 'Thông tin chung',
      rows: [
        _SettingsRowData(
          icon: Icons.description,
          iconBg: const Color(0xFF5C6BC0),
          title: 'Thỏa thuận sử dụng dịch vụ',
          // Gắn link Thỏa thuận
          onTap: () =>
              _launchUrl('https://waka.vn/thoa-thuan-su-dung-dich-vu-waka-ios'),
        ),
        _SettingsRowData(
          icon: Icons.assignment,
          iconBg: const Color(0xFF8E24AA),
          title: 'Chính sách quyền riêng tư',
          // Gắn link Quyền riêng tư
          onTap: () =>
              _launchUrl('https://waka.vn/thoa-thuan-su-dung-dich-vu-waka-ios'),
        ),
        _SettingsRowData(
          icon: Icons.wb_sunny,
          iconBg: const Color(0xFF29B6F6),
          title: 'Tiếp nhận đánh giá, phản ánh tổ chức xã hội',
          // Mở màn hình form tiếp nhận
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const FeedbackSubmitScreen()),
          ),
        ),
        _SettingsRowData(
          icon: Icons.assignment_turned_in,
          iconBg: const Color(0xFFEF5350),
          title: 'Danh sách đánh giá, phản ảnh tổ chức xã hội',
          // Mở màn hình danh sách
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const FeedbackListScreen()),
          ),
        ),
      ],
    ),
    _SettingsSectionData(
      title: 'Hỗ trợ khách hàng',
      rows: [
        _SettingsRowData(
          icon: Icons.cached,
          iconBg: const Color(0xFFFFA726),
          title: 'Chính sách đổi trả',
          onTap: () => _launchUrl('https://waka.vn/chinh-sach-doi-tra'),
        ),
        _SettingsRowData(
          icon: Icons.attach_money,
          iconBg: const Color(0xFFFFCA28),
          title: 'Chính sách thanh toán',
          onTap: () => _launchUrl('https://waka.vn/chinh-sach-thanh-toan'),
        ),
        _SettingsRowData(
          icon: Icons.report_problem,
          iconBg: const Color(0xFF26A69A),
          title: 'Giải quyết khiếu nại',
          onTap: () => _launchUrl('https://waka.vn/giai-quyet-khieu-nai'),
        ),
        _SettingsRowData(
          // <-- THÊM MỤC NÀY
          icon: Icons.do_not_disturb_alt,
          iconBg: const Color(0xFF9E9E9E),
          title: 'Quy định hàng hóa cấm',
          onTap: () => _launchUrl('https://waka.vn/quy-dinh-hang-hoa-cam'),
        ),
        _SettingsRowData(
          icon: Icons.event_busy,
          iconBg: const Color(0xFFEF5350),
          title: 'Chính sách xác nhận/hủy',
          onTap: () =>
              _launchUrl('https://waka.vn/chinh-sach-xac-nhan-huy-don'),
        ),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final sections = _sections(context);
    return _DetailScaffold(
      title: 'Thông tin chung',
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        itemCount: sections.length,
        separatorBuilder: (_, _) => const SizedBox(height: 22),
        itemBuilder: (context, index) {
          final section = sections[index];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 12, left: 2),
                child: Text(
                  section.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: WakaColors.surface,
                  borderRadius: BorderRadius.circular(14),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    for (var i = 0; i < section.rows.length; i++) ...[
                      _SettingsRowTile(data: section.rows[i]),
                      if (i != section.rows.length - 1)
                        const Divider(
                          height: 1,
                          thickness: 0.7,
                          color: Color(0xFF2E2E31),
                          indent: 68,
                        ),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SettingsRowTile extends StatelessWidget {
  const _SettingsRowTile({required this.data});

  final _SettingsRowData data;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: data.onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: data.iconBg,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(data.icon, color: Colors.white, size: 19),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Text(
                data.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white38, size: 22),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// TIẾP NHẬN ĐÁNH GIÁ (GIAO DIỆN FORM TỪ ẢNH)
// ---------------------------------------------------------------------------
class FeedbackSubmitScreen extends StatelessWidget {
  const FeedbackSubmitScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF141517), // Màu nền tối theo ảnh
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const SizedBox.shrink(),
        leadingWidth: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white, size: 28),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 10),
              const Text(
                'Tiếp nhận đánh giá, phản ánh, kiến nghị của tổ chức xã hội',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 30),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildInputField(
                        'Tên tổ chức xã hội',
                        'Nhập tên tổ chức xã hội',
                        required: true,
                      ),
                      const SizedBox(height: 20),
                      _buildInputField(
                        'Số quyết định thành lập',
                        'Nhập số quyết định thành lập',
                        required: true,
                      ),
                      const SizedBox(height: 20),
                      _buildInputField(
                        'Nội dung',
                        'Nhập nội dung',
                        required: true,
                        maxLines: 5,
                      ),
                    ],
                  ),
                ),
              ),

              // Nút Submit
              Padding(
                padding: const EdgeInsets.only(bottom: 24, top: 16),
                child: ElevatedButton(
                  onPressed: () {
                    // Xử lý gửi form ở đây
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: WakaColors.accent, // Màu xanh lá Waka
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Gửi yêu cầu',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField(
    String label,
    String hint, {
    bool required = false,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
            children: [
              if (required)
                const TextSpan(
                  text: ' *',
                  style: TextStyle(color: Colors.red),
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          maxLines: maxLines,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white38),
            filled: true,
            fillColor: const Color(0xFF1E1E20), // Màu nền input
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// DANH SÁCH ĐÁNH GIÁ (GIAO DIỆN TỪ ẢNH)
// ---------------------------------------------------------------------------
class FeedbackListScreen extends StatelessWidget {
  const FeedbackListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Data giả lập dựa theo ảnh chụp
    final dummyData = [
      {
        'time': '23:39 23/04/2026',
        'name': '687/8',
        'decision': '79',
        'content': '67',
      },
      {
        'time': '05:55 14/01/2026',
        'name': 'e',
        'decision': 'e',
        'content': 'e',
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF141517),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const SizedBox.shrink(),
        leadingWidth: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white, size: 28),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 10),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Danh sách đánh giá, phản ánh, kiến nghị của tổ chức xã hội',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 24),

            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                itemCount: dummyData.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final item = dummyData[index];
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E20),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoRow('Thời gian gửi:', item['time']!),
                        const SizedBox(height: 4),
                        _buildInfoRow('Tên tổ chức:', item['name']!),
                        const SizedBox(height: 4),
                        _buildInfoRow('Số quyết định:', item['decision']!),
                        const SizedBox(height: 4),
                        _buildInfoRow('Nội dung:', item['content']!),
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

  Widget _buildInfoRow(String label, String value) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 15, color: Colors.white, height: 1.5),
        children: [
          TextSpan(text: '$label '),
          TextSpan(text: value),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Thông báo (Giữ nguyên)
// ---------------------------------------------------------------------------

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<UserNotification> _items = const [];
  bool _loading = true;
  String _error = '';
  Timer? _refreshTimer;
  bool _refreshing = false;

  @override
  void initState() {
    super.initState();
    _load();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _load(silent: true),
    );
  }

  Future<void> _load({bool silent = false}) async {
    if (_refreshing) return;
    _refreshing = true;
    if (!AuthSession.isSignedIn) {
      if (mounted) setState(() => _loading = false);
      _refreshing = false;
      return;
    }
    try {
      const service = CommerceApiService();
      final items = await service.getNotifications();
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
        _error = '';
      });
      for (final item in items.where((item) => !item.isRead)) {
        await service.markNotificationRead(item.id);
      }
    } on Object catch (error) {
      if (!mounted) return;
      if (!silent) {
        setState(() {
          _loading = false;
          _error = error.toString();
        });
      }
    } finally {
      _refreshing = false;
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _DetailScaffold(
      title: 'Thông báo',
      child: _loading
          ? const Center(
              child: CircularProgressIndicator(color: WakaColors.accent),
            )
          : _error.isNotEmpty
          ? Center(
              child: Text(
                _error,
                style: const TextStyle(color: Colors.white70),
              ),
            )
          : _items.isEmpty
          ? const Center(
              child: Text(
                'Chưa có thông báo.',
                style: TextStyle(color: Colors.white54),
              ),
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                itemCount: _items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final item = _items[index];
                  final approved = item.type == 'membership_approved';
                  final color = approved ? WakaColors.accent : WakaColors.gold;
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
                          backgroundColor: color.withValues(alpha: 0.16),
                          child: Icon(
                            approved
                                ? Icons.verified_rounded
                                : Icons.info_outline_rounded,
                            color: color,
                            size: 22,
                          ),
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
                                _notificationTime(item.createdAt),
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
            ),
    );
  }
}

String _notificationTime(DateTime? value) {
  if (value == null) return '';
  final difference = DateTime.now().difference(value.toLocal());
  if (difference.inMinutes < 1) return 'Vừa xong';
  if (difference.inHours < 1) return '${difference.inMinutes} phút trước';
  if (difference.inDays < 1) return '${difference.inHours} giờ trước';
  return '${difference.inDays} ngày trước';
}

// ---------------------------------------------------------------------------
// Địa chỉ nhận hàng - đọc từ bộ nhớ thiết bị theo tài khoản đang đăng nhập
// ---------------------------------------------------------------------------

class AddressBookScreen extends StatefulWidget {
  const AddressBookScreen({
    super.key,
    this.store = const SecureShopAddressStore(),
  });

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
      var address = await widget.store.read(ownerKey);
      if (address == null) {
        final orders = await const CommerceApiService().getOrders();
        for (final order in orders) {
          if (order.shippingAddress.trim().isEmpty) continue;
          address = ShopShippingAddress(
            recipient: order.shippingRecipient,
            phone: order.shippingPhone,
            provinceCode: 0,
            province: '',
            districtCode: 0,
            district: '',
            wardCode: 0,
            ward: '',
            streetAddress: order.shippingAddress,
          );
          try {
            await widget.store.write(ownerKey, address);
          } on Object {
            // Vẫn hiển thị địa chỉ từ đơn hàng nếu lưu local thất bại.
          }
          break;
        }
      }
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
          'Vào Cá nhân → Đăng ký làm tác giả, điền hồ sơ và tác phẩm mẫu. '
          'Sau khi quản trị viên duyệt, tài khoản sẽ được cấp quyền tác giả.',
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
            style: const TextStyle(color: WakaColors.mutedText, height: 1.45),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Thể loại yêu thích — lưới chọn nhiều, dùng chung cho "Sách" và "Truyện tranh"
// ---------------------------------------------------------------------------

enum FavoriteCategoryKind { books, comics }

class _CategoryItem {
  const _CategoryItem(this.emoji, this.label);
  final String emoji;
  final String label;
}

const _bookCategories = [
  _CategoryItem('📜', 'Thơ - Tản văn'),
  _CategoryItem('🧭', 'Trinh thám - Kinh dị'),
  _CategoryItem('📊', 'Marketing - Bán hàng'),
  _CategoryItem('🧑‍🤝‍🧑', 'Quản trị - Lãnh đạo'),
  _CategoryItem('💰', 'Tài chính cá nhân'),
  _CategoryItem('🔤', 'Phát triển cá nhân'),
  _CategoryItem('📈', 'Doanh nhân - Bài học kinh doanh'),
  _CategoryItem('🌌', 'Chữa lành'),
  _CategoryItem('📐', 'Học tập - Hướng nghiệp'),
  _CategoryItem('💗', 'Sức khỏe - Làm đẹp'),
  _CategoryItem('📐', 'Khoa học - Công nghệ'),
  _CategoryItem('💡', 'Tư duy sáng tạo'),
  _CategoryItem('📊', 'Chứng khoán - Bất động sản - Đầu tư'),
  _CategoryItem('🏛️', 'Giáo dục - Văn hóa & Xã hội'),
  _CategoryItem('🧘', 'Nghệ thuật sống'),
  _CategoryItem('🛕', 'Tâm linh - Tôn giáo'),
  _CategoryItem('🌱', 'Sách Ngoại văn'),
  _CategoryItem('💵', 'Kinh doanh - Làm giàu'),
  _CategoryItem('💔', 'Ngôn tình'),
  _CategoryItem('⭐', 'Tác phẩm kinh điển'),
];

const _comicCategories = [
  _CategoryItem('👨', 'Nam'),
  _CategoryItem('👩', 'Nữ'),
  _CategoryItem('👬', 'BL'),
  _CategoryItem('🥚', 'Linh dị'),
  _CategoryItem('⏱️', 'Xuyên không'),
  _CategoryItem('👻', 'Truyện ma'),
  _CategoryItem('🪷', 'Tu chân'),
  _CategoryItem('🛸', 'Hiện đại'),
  _CategoryItem('🌱', 'Thơ thiếu nhi'),
  _CategoryItem('🏛️', 'Cổ đại'),
  _CategoryItem('⚛️', 'Kĩ năng cho trẻ'),
  _CategoryItem('📗', 'Hài hước'),
  _CategoryItem('⚛️', 'Giáo dục - khoa học'),
  _CategoryItem('💓', 'Tình cảm'),
  _CategoryItem('⚔️', 'Hành động'),
  _CategoryItem('🪭', 'Dân gian Việt Nam'),
  _CategoryItem('👒', 'Ngụ ngôn'),
  _CategoryItem('💗', 'Manhua'),
  _CategoryItem('✨', 'Cổ tích - thần thoại'),
  _CategoryItem('🏮', 'Truyện Việt'),
];

class FavoriteCategoryScreen extends StatefulWidget {
  const FavoriteCategoryScreen({
    super.key,
    required this.kind,
    this.initialSelected = const {},
    this.onSubmit,
  });

  final FavoriteCategoryKind kind;
  final Set<String> initialSelected;
  final ValueChanged<Set<String>>? onSubmit;

  @override
  State<FavoriteCategoryScreen> createState() => _FavoriteCategoryScreenState();
}

class _FavoriteCategoryScreenState extends State<FavoriteCategoryScreen> {
  late final Set<String> _selected = {...widget.initialSelected};

  bool get _isBooks => widget.kind == FavoriteCategoryKind.books;

  @override
  Widget build(BuildContext context) {
    final items = _isBooks ? _bookCategories : _comicCategories;
    final title = _isBooks ? 'Sách yêu thích' : 'Truyện tranh yêu thích';
    final subtitle = _isBooks
        ? 'Dưới đây là thể loại Sách điện tử / Sách nói bạn yêu thích'
        : 'Lựa chọn thể loại truyện tranh yêu thích của bạn';

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
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Text(
                subtitle,
                style: const TextStyle(
                  color: WakaColors.mutedText,
                  fontSize: 14.5,
                ),
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
                itemCount: items.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 1.05,
                ),
                itemBuilder: (context, index) {
                  final item = items[index];
                  final selected = _selected.contains(item.label);
                  return _CategoryTile(
                    item: item,
                    selected: selected,
                    onTap: () {
                      setState(() {
                        if (selected) {
                          _selected.remove(item.label);
                        } else {
                          _selected.add(item.label);
                        }
                      });
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: SizedBox(
          height: 52,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _selected.isEmpty
                  ? const Color(0xFF3A3A3D)
                  : WakaColors.accent,
              foregroundColor: Colors.white,
              disabledBackgroundColor: const Color(0xFF3A3A3D),
              disabledForegroundColor: Colors.white38,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            onPressed: _selected.isEmpty
                ? null
                : () {
                    widget.onSubmit?.call(_selected);
                    Navigator.of(context).pop(_selected);
                  },
            child: const Text(
              'CẬP NHẬT',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final _CategoryItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? WakaColors.accent : const Color(0xFF3A3A3D),
            width: selected ? 1.6 : 1,
          ),
          color: selected
              ? WakaColors.accent.withValues(alpha: 0.08)
              : Colors.transparent,
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(item.emoji, style: const TextStyle(fontSize: 34)),
                  const SizedBox(height: 10),
                  Text(
                    item.label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              const Positioned(
                top: 2,
                right: 2,
                child: Icon(
                  Icons.check_circle,
                  color: WakaColors.accent,
                  size: 18,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
