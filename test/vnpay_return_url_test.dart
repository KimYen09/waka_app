import 'package:flutter_test/flutter_test.dart';
import 'package:waka_demo/core/constants/api_endpoints.dart';

/// WebView phải nhận ra trang kết quả VNPay theo path. Trước đây nó so khớp
/// nguyên URL với `apiBaseUrl`, nên khi backend công bố `VNP_RETURN_URL` qua
/// tunnel công khai (host khác hẳn) thì WebView không bao giờ tự đóng và mọi
/// giao dịch đều hiện "đang chờ xác nhận" dù đã thanh toán thành công.
void main() {
  group('ApiEndpoints.isVnpayReturnUrl', () {
    test('nhận ra URL trả về qua tunnel công khai khác host với app', () {
      expect(
        ApiEndpoints.isVnpayReturnUrl(
          'https://dressing-johns-maintaining-constantly.trycloudflare.com'
          '/api/payments/vnpay/return?vnp_ResponseCode=00&vnp_TxnRef=WAKA1',
        ),
        isTrue,
      );
    });

    test('nhận ra URL trả về khi backend chạy local ở cổng bất kỳ', () {
      for (final url in [
        'http://10.0.2.2:3000/api/payments/vnpay/return?vnp_ResponseCode=00',
        'http://127.0.0.1:3900/api/payments/vnpay/return',
        'https://waka.example.com/api/payments/vnpay/return',
      ]) {
        expect(ApiEndpoints.isVnpayReturnUrl(url), isTrue, reason: url);
      }
    });

    test('không nhầm với trang cổng VNPay hay endpoint IPN', () {
      for (final url in [
        'https://sandbox.vnpayment.vn/paymentv2/vpcpay.html?vnp_Amount=100',
        'https://sandbox.vnpayment.vn/Transaction/PaymentMethod.html',
        'http://127.0.0.1:3000/api/payments/vnpay/ipn?vnp_ResponseCode=00',
        'http://127.0.0.1:3000/api/orders',
      ]) {
        expect(ApiEndpoints.isVnpayReturnUrl(url), isFalse, reason: url);
      }
    });

    test('không vỡ với URL rỗng hoặc không phải http', () {
      expect(ApiEndpoints.isVnpayReturnUrl(''), isFalse);
      expect(ApiEndpoints.isVnpayReturnUrl('about:blank'), isFalse);
    });
  });
}
