import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_theme.dart';

/// Mở trang thanh toán VNPay bằng **trình duyệt ngoài** rồi chờ người dùng
/// quay lại app.
///
/// Trước đây màn này nhúng WebView, nhưng WebView trên máy/emulator cũ hay
/// render hỏng trang VNPay (màn trắng) và không cập nhật được như trình duyệt
/// hệ thống. VNPay cũng khuyến nghị dùng trình duyệt thật.
///
/// Đánh đổi: trình duyệt ngoài không trả kết quả về app được, nên màn này chỉ
/// trả `true` khi người dùng bấm "Tôi đã thanh toán xong" — đó là *tín hiệu để
/// đi kiểm tra*, không phải kết luận. Xác nhận thật vẫn do IPN xử lý ở backend,
/// nên nơi gọi phải tự đọc lại trạng thái đơn/gói sau đó.
///
/// Trả về:
/// - `true`  nếu người dùng báo đã thanh toán xong,
/// - `null`  nếu người dùng bỏ dở.
class ShopVnpayPaymentScreen extends StatefulWidget {
  const ShopVnpayPaymentScreen({super.key, required this.paymentUrl});

  final String paymentUrl;

  @override
  State<ShopVnpayPaymentScreen> createState() => _ShopVnpayPaymentScreenState();
}

class _ShopVnpayPaymentScreenState extends State<ShopVnpayPaymentScreen> {
  bool _opening = false;
  bool _hasOpened = false;
  String _error = '';

  @override
  void initState() {
    super.initState();
    // Mở luôn để người dùng không phải bấm thêm một nhịp nữa.
    WidgetsBinding.instance.addPostFrameCallback((_) => _openBrowser());
  }

  Future<void> _openBrowser() async {
    if (_opening) return;
    setState(() {
      _opening = true;
      _error = '';
    });
    try {
      final uri = Uri.parse(widget.paymentUrl);
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!mounted) return;
      setState(() {
        _hasOpened = launched;
        if (!launched) {
          _error = 'Không mở được trình duyệt trên thiết bị này.';
        }
      });
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _error = 'Không mở được trình duyệt: $error');
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WakaColors.background,
      appBar: AppBar(
        backgroundColor: WakaColors.background,
        title: const Text('Thanh toán VNPay'),
        leading: IconButton(
          tooltip: 'Đóng',
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Spacer(),
            Icon(
              _error.isNotEmpty
                  ? Icons.error_outline_rounded
                  : Icons.open_in_browser_rounded,
              size: 56,
              color: _error.isNotEmpty ? Colors.redAccent : WakaColors.accent,
            ),
            const SizedBox(height: 18),
            Text(
              _error.isNotEmpty
                  ? 'Không mở được trình duyệt'
                  : 'Đang thanh toán trên trình duyệt',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 19,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _error.isNotEmpty
                  ? _error
                  : 'Hoàn tất thanh toán ở trình duyệt vừa mở, sau đó quay lại '
                        'đây và bấm nút bên dưới để cập nhật trạng thái.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white60, height: 1.4),
            ),
            const Spacer(),
            if (_hasOpened && _error.isEmpty)
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('TÔI ĐÃ THANH TOÁN XONG'),
              ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: _opening ? null : _openBrowser,
              child: Text(
                _opening
                    ? 'ĐANG MỞ…'
                    : _hasOpened
                    ? 'MỞ LẠI TRÌNH DUYỆT'
                    : 'THỬ LẠI',
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('HỦY THANH TOÁN'),
            ),
          ],
        ),
      ),
    );
  }
}
