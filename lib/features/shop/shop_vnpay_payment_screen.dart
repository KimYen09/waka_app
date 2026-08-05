import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../core/theme/app_theme.dart';

/// Mở trang thanh toán VNPay trong WebView và tự đóng khi phát hiện trình
/// duyệt điều hướng tới URL kết quả (`GET /api/payments/vnpay/return`).
///
/// Trả về:
/// - `true` nếu VNPay báo `vnp_ResponseCode=00` (khả năng thành công),
/// - `false` nếu VNPay báo mã lỗi khác,
/// - `null` nếu người dùng tự đóng màn hình trước khi hoàn tất.
///
/// Đây chỉ là tín hiệu hiển thị tạm thời — xác nhận thật do IPN xử lý ở
/// backend, nên màn hình gọi widget này cần tự làm mới trạng thái đơn hàng
/// sau đó thay vì tin tuyệt đối vào giá trị trả về.
class ShopVnpayPaymentScreen extends StatefulWidget {
  const ShopVnpayPaymentScreen({
    super.key,
    required this.paymentUrl,
    required this.returnUrlPrefix,
  });

  final String paymentUrl;
  final String returnUrlPrefix;

  @override
  State<ShopVnpayPaymentScreen> createState() =>
      _ShopVnpayPaymentScreenState();
}

class _ShopVnpayPaymentScreenState extends State<ShopVnpayPaymentScreen> {
  late final WebViewController _controller;
  bool _finished = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(WakaColors.background)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) setState(() => _loading = true);
          },
          onPageFinished: (url) {
            if (mounted) setState(() => _loading = false);
            _maybeFinish(url);
          },
          onNavigationRequest: (request) {
            if (request.url.startsWith(widget.returnUrlPrefix)) {
              _maybeFinish(request.url);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.paymentUrl));
  }

  void _maybeFinish(String url) {
    if (_finished || !url.startsWith(widget.returnUrlPrefix)) return;
    _finished = true;
    final responseCode = Uri.tryParse(url)?.queryParameters['vnp_ResponseCode'];
    Navigator.of(context).pop(responseCode == '00');
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
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_loading)
            const LinearProgressIndicator(
              minHeight: 2,
              color: WakaColors.accent,
            ),
        ],
      ),
    );
  }
}
