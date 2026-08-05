import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/api_endpoints.dart';
import '../../core/services/auth_api_service.dart';
import '../../core/theme/app_theme.dart';
import 'shop_address_store.dart';
import 'shop_constants.dart';
import 'shop_location_service.dart';
import 'shop_vnpay_payment_screen.dart';

typedef ShopOrderSubmitResult = ({int orderId, String? paymentUrl});

typedef ShopOrderSubmit =
    Future<ShopOrderSubmitResult> Function(
      ShopPaymentMethod method,
      ShopCheckoutVoucher? voucher,
      ShopShippingAddress shippingAddress,
      String? orderCode,
    );

class ShopCheckoutLine {
  const ShopCheckoutLine({required this.product, required this.quantity});

  final ShopProduct product;
  final int quantity;

  int get unitPrice => _priceValue(product.price);
  int get total => unitPrice * quantity;
}

enum ShopPaymentMethod {
  cashOnDelivery,
  bankQr,
  atm,
  internationalCard,
  eWallet,
}

class ShopCheckoutVoucher {
  const ShopCheckoutVoucher({
    required this.id,
    required this.title,
    required this.description,
    required this.percent,
    required this.minimumSubtotal,
  });

  final String id;
  final String title;
  final String description;
  final int percent;
  final int minimumSubtotal;

  bool isEligible(int subtotal) => subtotal >= minimumSubtotal;

  int discountFor(int subtotal) =>
      isEligible(subtotal) ? (subtotal * percent / 100).round() : 0;
}

const shopCheckoutVouchers = <ShopCheckoutVoucher>[
  ShopCheckoutVoucher(
    id: 'WAKA10',
    title: 'Giảm 10%',
    description: 'Giảm 10% cho đơn hàng từ 100.000đ',
    percent: 10,
    minimumSubtotal: 100000,
  ),
  ShopCheckoutVoucher(
    id: 'WAKA15',
    title: 'Giảm 15%',
    description: 'Giảm 15% cho đơn hàng từ 250.000đ',
    percent: 15,
    minimumSubtotal: 250000,
  ),
];

extension ShopPaymentMethodView on ShopPaymentMethod {
  String get title => switch (this) {
    ShopPaymentMethod.cashOnDelivery => 'Thanh toán khi nhận hàng',
    ShopPaymentMethod.bankQr => 'Quét QR CODE',
    ShopPaymentMethod.atm => 'Thẻ ATM có Internet Banking',
    ShopPaymentMethod.internationalCard => 'Thẻ quốc tế Visa/Master/JBC',
    ShopPaymentMethod.eWallet => 'Ví điện tử',
  };

  IconData get icon => switch (this) {
    ShopPaymentMethod.cashOnDelivery => Icons.inventory_2_outlined,
    ShopPaymentMethod.bankQr => Icons.qr_code_2_rounded,
    ShopPaymentMethod.atm => Icons.credit_card_rounded,
    ShopPaymentMethod.internationalCard => Icons.payment_rounded,
    ShopPaymentMethod.eWallet => Icons.account_balance_wallet_outlined,
  };

  bool get isAvailable => true;

  /// VNPay xử lý chung một trang cho cả 3 hình thức này.
  bool get isVnpay =>
      this == ShopPaymentMethod.atm ||
      this == ShopPaymentMethod.internationalCard ||
      this == ShopPaymentMethod.eWallet;
}

/// Public receiving-account values used to render a VietQR QuickLink.
///
/// Receiving-account values are public checkout data because they are encoded
/// in the QR. Build-time values can override the store defaults below. API keys
/// and payment-provider secrets must never be placed in Flutter source code.
abstract final class ShopBankTransferConfig {
  static const bankId = String.fromEnvironment(
    'PAYMENT_BANK_ID',
    defaultValue: '970422',
  );
  static const accountNumber = String.fromEnvironment(
    'PAYMENT_ACCOUNT_NUMBER',
    defaultValue: '006002909',
  );
  static const accountName = String.fromEnvironment(
    'PAYMENT_ACCOUNT_NAME',
    defaultValue: 'LE NGO KIM YEN',
  );

  static bool get isConfigured =>
      bankId.trim().isNotEmpty &&
      accountNumber.trim().isNotEmpty &&
      accountName.trim().isNotEmpty;

  static Uri qrImageUri({required int amount, required String orderCode}) {
    return Uri.https(
      'img.vietqr.io',
      '/image/$bankId-$accountNumber-compact2.png',
      {'amount': '$amount', 'addInfo': orderCode, 'accountName': accountName},
    );
  }
}

class ShopCheckoutScreen extends StatefulWidget {
  const ShopCheckoutScreen({
    super.key,
    required this.lines,
    required this.onSubmitOrder,
    this.voucherName,
    this.voucherDiscount = 0,
    this.availableVouchers = shopCheckoutVouchers,
    this.addressStore = const SecureShopAddressStore(),
    this.locationRepository = const ShopLocationService(),
  });

  final List<ShopCheckoutLine> lines;
  final ShopOrderSubmit onSubmitOrder;
  final String? voucherName;
  final int voucherDiscount;
  final List<ShopCheckoutVoucher> availableVouchers;
  final ShopAddressStore addressStore;
  final ShopLocationRepository locationRepository;

  @override
  State<ShopCheckoutScreen> createState() => _ShopCheckoutScreenState();
}

class _ShopCheckoutScreenState extends State<ShopCheckoutScreen> {
  ShopShippingAddress? _shippingAddress;
  ShopCheckoutVoucher? _selectedVoucher;
  int _legacyVoucherDiscount = 0;
  ShopPaymentMethod _paymentMethod = ShopPaymentMethod.cashOnDelivery;
  bool _electronicInvoice = false;
  bool _submitting = false;

  int get _subtotal => widget.lines.fold(0, (sum, line) => sum + line.total);
  int get _itemCount =>
      widget.lines.fold(0, (sum, line) => sum + line.quantity);
  int get _shippingFee => 0;
  int get _voucherDiscount =>
      _selectedVoucher?.discountFor(_subtotal) ?? _legacyVoucherDiscount;

  int get _total {
    final gross = _subtotal + _shippingFee;
    return (gross - _voucherDiscount).clamp(0, gross);
  }

  String get _addressOwnerKey =>
      AuthSession.current?.user.id.toString() ?? 'guest';

  @override
  void initState() {
    super.initState();
    for (final voucher in widget.availableVouchers) {
      if (voucher.title == widget.voucherName) {
        _selectedVoucher = voucher;
        break;
      }
    }
    if (_selectedVoucher == null) {
      _legacyVoucherDiscount = widget.voucherDiscount;
    }
    _loadSavedAddress();
  }

  Future<void> _loadSavedAddress() async {
    try {
      final address = await widget.addressStore.read(_addressOwnerKey);
      if (address != null && mounted) {
        setState(() => _shippingAddress = address);
      }
    } on Object {
      // Checkout remains usable if local persistence is unavailable.
    }
  }

  Future<void> _editAddress() async {
    final address = await showModalBottomSheet<ShopShippingAddress>(
      context: context,
      isScrollControlled: true,
      backgroundColor: WakaColors.elevated,
      showDragHandle: true,
      builder: (_) => _AddressForm(
        initialValue: _shippingAddress,
        locationRepository: widget.locationRepository,
      ),
    );
    if (address != null && mounted) {
      setState(() => _shippingAddress = address);
      try {
        await widget.addressStore.write(_addressOwnerKey, address);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã lưu địa chỉ giao hàng.')),
        );
      } on Object {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã dùng địa chỉ, nhưng chưa thể lưu trên thiết bị.'),
          ),
        );
      }
    }
  }

  Future<void> _chooseVoucher() async {
    final result = await showModalBottomSheet<_VoucherSelection>(
      context: context,
      backgroundColor: WakaColors.elevated,
      showDragHandle: true,
      builder: (_) => _VoucherPicker(
        subtotal: _subtotal,
        vouchers: widget.availableVouchers,
        selectedVoucher: _selectedVoucher,
      ),
    );
    if (result == null || !mounted) return;
    setState(() {
      _selectedVoucher = result.voucher;
      _legacyVoucherDiscount = 0;
    });
  }

  Future<void> _choosePaymentMethod() async {
    final method = await Navigator.of(context).push<ShopPaymentMethod>(
      MaterialPageRoute(
        builder: (_) =>
            ShopPaymentMethodScreen(initialPaymentMethod: _paymentMethod),
      ),
    );
    if (method != null && mounted) {
      setState(() => _paymentMethod = method);
    }
  }

  Future<void> _submit() async {
    if (_shippingAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng thêm địa chỉ nhận hàng.')),
      );
      await _editAddress();
      return;
    }

    String? orderCode;
    if (_paymentMethod == ShopPaymentMethod.bankQr) {
      orderCode = 'WAKA${DateTime.now().millisecondsSinceEpoch}';
      final transferred = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) =>
              ShopQrPaymentScreen(amount: _total, orderCode: orderCode!),
        ),
      );
      if (transferred != true || !mounted) return;
    }

    if (!_paymentMethod.isAvailable || _submitting) return;
    setState(() => _submitting = true);
    try {
      final result = await widget.onSubmitOrder(
        _paymentMethod,
        _selectedVoucher,
        _shippingAddress!,
        orderCode,
      );
      final orderId = result.orderId;

      bool? vnpaySuccess;
      if (_paymentMethod.isVnpay && result.paymentUrl != null) {
        if (!mounted) return;
        vnpaySuccess = await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (_) => ShopVnpayPaymentScreen(
              paymentUrl: result.paymentUrl!,
              returnUrlPrefix: ApiEndpoints.apiVnpayReturn,
            ),
          ),
        );
      }
      if (!mounted) return;

      final isVnpayFlow = _paymentMethod.isVnpay;
      final dialogIcon = isVnpayFlow
          ? (vnpaySuccess == true
                ? Icons.check_circle_outline_rounded
                : Icons.hourglass_top_rounded)
          : (_paymentMethod == ShopPaymentMethod.bankQr
                ? Icons.hourglass_top_rounded
                : Icons.inventory_2_outlined);
      final dialogTitle = isVnpayFlow
          ? (vnpaySuccess == true
                ? 'Thanh toán VNPay thành công'
                : 'Đang chờ xác nhận thanh toán')
          : (_paymentMethod == ShopPaymentMethod.bankQr
                ? 'Chờ xác nhận thanh toán'
                : 'Đặt hàng COD thành công');
      final dialogContent = isVnpayFlow
          ? (vnpaySuccess == true
                ? 'Đơn #$orderId đã thanh toán qua VNPay. Hệ thống đang '
                      'xác nhận và sẽ sớm được xử lý.'
                : 'Đơn #$orderId đang chờ xác nhận từ VNPay. Nếu bạn đã '
                      'thanh toán thành công, đơn sẽ tự cập nhật trong ít phút.')
          : (_paymentMethod == ShopPaymentMethod.bankQr
                ? 'Đơn #$orderId đã được gửi cho quản trị viên kiểm tra. '
                      'Đơn chỉ bắt đầu giao sau khi tiền được xác nhận.'
                : 'Đơn #$orderId đã được tiếp nhận. Bạn sẽ thanh toán khi nhận hàng.');

      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          icon: Icon(dialogIcon, color: WakaColors.accent),
          title: Text(dialogTitle),
          content: Text(dialogContent),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('THEO DÕI TRONG ĐƠN HÀNG'),
            ),
          ],
        ),
      );
      if (mounted) Navigator.of(context).pop(orderId);
    } on Object catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WakaColors.background,
      appBar: AppBar(
        backgroundColor: WakaColors.background,
        title: const Text('Thanh toán'),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _CheckoutSection(
              child: InkWell(
                onTap: _editAddress,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionHeading(
                        icon: Icons.location_on_outlined,
                        title: 'Địa chỉ nhận hàng',
                        action: _shippingAddress == null
                            ? 'Thêm địa chỉ'
                            : 'Thay đổi',
                        onAction: _editAddress,
                      ),
                      const SizedBox(height: 12),
                      if (_shippingAddress == null)
                        const Text(
                          'Chưa có địa chỉ nhận hàng. Vui lòng thêm địa chỉ để đặt hàng',
                          style: TextStyle(
                            color: WakaColors.mutedText,
                            height: 1.45,
                          ),
                        )
                      else ...[
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
                                _shippingAddress!.label,
                                style: const TextStyle(
                                  color: WakaColors.accent,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${_shippingAddress!.recipient}  •  ${_shippingAddress!.phone}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 7),
                        Text(
                          _shippingAddress!.fullAddress,
                          style: const TextStyle(
                            color: WakaColors.mutedText,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: _CheckoutSection(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SectionHeading(
                    icon: Icons.storefront_outlined,
                    title: 'Nhà sách Waka',
                  ),
                  const SizedBox(height: 14),
                  for (var index = 0; index < widget.lines.length; index++) ...[
                    _CheckoutProductLine(line: widget.lines[index]),
                    if (index < widget.lines.length - 1)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Divider(height: 1, color: WakaColors.divider),
                      ),
                  ],
                  const SizedBox(height: 16),
                  const Divider(height: 1, color: WakaColors.divider),
                  const SizedBox(height: 14),
                  const Text(
                    'Tùy chọn giao hàng',
                    style: TextStyle(color: Colors.white, fontSize: 17),
                  ),
                  const SizedBox(height: 12),
                  _LabelValueRow(
                    label: 'Phí vận chuyển',
                    value: _shippingAddress == null
                        ? 'Chưa xác định phí'
                        : 'Miễn phí',
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _shippingAddress == null
                        ? 'Bạn chưa có địa chỉ giao hàng. Vui lòng cập nhật'
                        : 'Vận chuyển tiêu chuẩn đến ${_shippingAddress!.fullAddress}',
                    style: const TextStyle(
                      color: WakaColors.mutedText,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      const Icon(
                        Icons.local_shipping_outlined,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            style: const TextStyle(
                              color: Colors.white,
                              height: 1.35,
                            ),
                            children: [
                              const TextSpan(text: 'Vận chuyển từ '),
                              TextSpan(
                                text: 'Nhà sách Waka',
                                style: const TextStyle(
                                  color: WakaColors.accent,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                              const TextSpan(text: ' đến địa chỉ của bạn'),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _LabelValueRow(
                    label: 'Tổng cộng ($_itemCount sản phẩm):',
                    value: _formatPrice(_subtotal),
                    valueColor: WakaColors.flashPink,
                    emphasize: true,
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: _CheckoutSection(
              child: Column(
                children: [
                  _SectionHeading(
                    icon: Icons.monetization_on_outlined,
                    title: 'Lựa chọn thanh toán',
                    action: 'Xem tất cả',
                    onAction: _choosePaymentMethod,
                  ),
                  const SizedBox(height: 14),
                  InkWell(
                    key: const ValueKey('checkout-payment-method'),
                    onTap: _choosePaymentMethod,
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: WakaColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: WakaColors.accent),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.radio_button_checked_rounded,
                            color: WakaColors.accent,
                          ),
                          const SizedBox(width: 12),
                          _PaymentIcon(method: _paymentMethod),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _paymentMethod.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
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
          ),
          SliverToBoxAdapter(
            child: _CheckoutSection(
              child: SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                value: _electronicInvoice,
                activeTrackColor: WakaColors.accent,
                title: const Text(
                  'Hóa đơn điện tử',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                subtitle: const Text(
                  'Thông tin xuất hóa đơn sẽ được bổ sung sau',
                  style: TextStyle(color: WakaColors.mutedText),
                ),
                onChanged: (value) =>
                    setState(() => _electronicInvoice = value),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: _CheckoutSection(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SectionHeading(
                    icon: Icons.receipt_long_outlined,
                    title: 'Chi tiết thanh toán',
                  ),
                  const SizedBox(height: 14),
                  _LabelValueRow(label: 'Số sản phẩm', value: '$_itemCount'),
                  const SizedBox(height: 10),
                  _LabelValueRow(
                    label: 'Tổng tiền hàng',
                    value: _formatPrice(_subtotal),
                  ),
                  const SizedBox(height: 10),
                  _LabelValueRow(
                    label: 'Phí vận chuyển',
                    value: _formatPrice(_shippingFee),
                  ),
                  const SizedBox(height: 10),
                  _LabelValueRow(
                    label: 'Voucher Waka',
                    value: _voucherDiscount == 0
                        ? '0đ'
                        : '-${_formatPrice(_voucherDiscount)}',
                    valueColor: _voucherDiscount == 0
                        ? Colors.white
                        : WakaColors.accent,
                  ),
                  if (_selectedVoucher != null) ...[
                    const SizedBox(height: 5),
                    Text(
                      _selectedVoucher!.title,
                      style: const TextStyle(
                        color: WakaColors.accent,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: _CheckoutSection(
              child: ListTile(
                key: const ValueKey('checkout-voucher-row'),
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.confirmation_number_outlined,
                  color: WakaColors.flashPink,
                ),
                title: const Text(
                  'Waka Voucher',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                subtitle: Text(
                  _selectedVoucher == null
                      ? 'Chọn mã giảm giá phù hợp với đơn hàng'
                      : '${_selectedVoucher!.title} • Đã giảm ${_formatPrice(_voucherDiscount)}',
                  style: TextStyle(
                    color: _selectedVoucher == null
                        ? WakaColors.mutedText
                        : WakaColors.accent,
                  ),
                ),
                trailing: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Chọn', style: TextStyle(color: WakaColors.accent)),
                    Icon(Icons.chevron_right_rounded, color: Colors.white70),
                  ],
                ),
                onTap: _chooseVoucher,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
          decoration: const BoxDecoration(
            color: WakaColors.background,
            border: Border(top: BorderSide(color: WakaColors.divider)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _LabelValueRow(
                label: 'Tổng thanh toán',
                value: _formatPrice(_total),
                valueColor: WakaColors.flashPink,
                emphasize: true,
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  key: const ValueKey('checkout-submit'),
                  onPressed: _submitting ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: WakaColors.accent,
                    foregroundColor: Colors.white,
                    shape: const StadiumBorder(),
                  ),
                  child: _submitting
                      ? const SizedBox.square(
                          dimension: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          _paymentMethod == ShopPaymentMethod.bankQr
                              ? 'TẠO MÃ QR'
                              : 'ĐẶT HÀNG COD',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ShopPaymentMethodScreen extends StatefulWidget {
  const ShopPaymentMethodScreen({
    super.key,
    required this.initialPaymentMethod,
  });

  final ShopPaymentMethod initialPaymentMethod;

  @override
  State<ShopPaymentMethodScreen> createState() =>
      _ShopPaymentMethodScreenState();
}

class _ShopPaymentMethodScreenState extends State<ShopPaymentMethodScreen> {
  late ShopPaymentMethod _selectedMethod;

  @override
  void initState() {
    super.initState();
    _selectedMethod = widget.initialPaymentMethod;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WakaColors.background,
      appBar: AppBar(
        backgroundColor: WakaColors.background,
        centerTitle: true,
        title: const Text(
          'Lựa chọn thanh toán',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [
          IconButton(
            tooltip: 'Đóng',
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
        itemCount: ShopPaymentMethod.values.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final method = ShopPaymentMethod.values[index];
          final selected = method == _selectedMethod;
          return Opacity(
            opacity: method.isAvailable ? 1 : .52,
            child: InkWell(
              key: ValueKey('payment-method-${method.name}'),
              onTap: method.isAvailable
                  ? () => setState(() => _selectedMethod = method)
                  : () => ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '${method.title} cần kết nối cổng thanh toán.',
                        ),
                      ),
                    ),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                constraints: const BoxConstraints(minHeight: 86),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: WakaColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: selected ? WakaColors.accent : Colors.transparent,
                  ),
                ),
                child: Row(
                  children: [
                    _PaymentIcon(method: method),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            method.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (!method.isAvailable) ...[
                            const SizedBox(height: 4),
                            const Text(
                              'Cần cổng thanh toán',
                              style: TextStyle(
                                color: WakaColors.mutedText,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (selected)
                      const Icon(Icons.check_rounded, color: WakaColors.accent)
                    else if (!method.isAvailable)
                      const Icon(Icons.lock_outline, color: Colors.white54),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 10, 28, 16),
          child: SizedBox(
            height: 52,
            child: FilledButton(
              key: const ValueKey('payment-method-confirm'),
              onPressed: () => Navigator.pop(context, _selectedMethod),
              style: FilledButton.styleFrom(
                backgroundColor: WakaColors.accent,
                shape: const StadiumBorder(),
              ),
              child: const Text(
                'XÁC NHẬN',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ShopQrPaymentScreen extends StatelessWidget {
  const ShopQrPaymentScreen({
    super.key,
    required this.amount,
    required this.orderCode,
    this.paymentPurpose = 'đơn hàng',
    this.requiresReview = true,
  });

  final int amount;
  final String orderCode;
  final String paymentPurpose;
  final bool requiresReview;

  Future<void> _copy(BuildContext context, String value, String label) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Đã sao chép $label.')));
  }

  Future<void> _confirmTransfer(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Xác nhận đã chuyển khoản?'),
        content: Text(
          requiresReview
              ? 'Sau khi xác nhận, $paymentPurpose sẽ chuyển sang trạng thái '
                    'chờ quản trị viên đối soát.'
              : 'Sau khi xác nhận, $paymentPurpose sẽ được kích hoạt trong '
                    'chế độ thanh toán demo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('KIỂM TRA LẠI'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('ĐÃ CHUYỂN KHOẢN'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final configured = ShopBankTransferConfig.isConfigured;
    return Scaffold(
      backgroundColor: WakaColors.background,
      appBar: AppBar(
        backgroundColor: WakaColors.background,
        title: Text('Thanh toán $paymentPurpose bằng QR'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0x2220D5A2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0x5520D5A2)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.verified_user_outlined,
                  color: WakaColors.accent,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Số tiền và nội dung chuyển khoản cho $paymentPurpose đã '
                    'được gắn sẵn vào QR.',
                    style: const TextStyle(color: Colors.white70, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: configured
                ? Image.network(
                    ShopBankTransferConfig.qrImageUri(
                      amount: amount,
                      orderCode: orderCode,
                    ).toString(),
                    key: const ValueKey('bank-transfer-qr'),
                    height: 260,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => const SizedBox(
                      height: 260,
                      child: _QrUnavailable(
                        message:
                            'Không tải được QR. Hãy kiểm tra mạng và mã ngân hàng.',
                      ),
                    ),
                  )
                : const SizedBox(
                    height: 260,
                    child: _QrUnavailable(
                      message:
                          'Chưa cấu hình tài khoản nhận tiền. Xem các biến cần cung cấp ở bên dưới.',
                    ),
                  ),
          ),
          const SizedBox(height: 20),
          _QrInfoRow(label: 'Số tiền', value: _formatPrice(amount)),
          _QrInfoRow(
            label: 'Nội dung',
            value: orderCode,
            onCopy: () => _copy(context, orderCode, 'nội dung chuyển khoản'),
          ),
          if (configured) ...[
            _QrInfoRow(
              label: 'Ngân hàng',
              value: ShopBankTransferConfig.bankId,
            ),
            _QrInfoRow(
              label: 'Số tài khoản',
              value: ShopBankTransferConfig.accountNumber,
              onCopy: () => _copy(
                context,
                ShopBankTransferConfig.accountNumber,
                'số tài khoản',
              ),
            ),
            _QrInfoRow(
              label: 'Chủ tài khoản',
              value: ShopBankTransferConfig.accountName,
            ),
          ] else
            const _PaymentSetupCard(),
          const SizedBox(height: 18),
          SizedBox(
            height: 52,
            child: FilledButton(
              onPressed: configured ? () => _confirmTransfer(context) : null,
              style: FilledButton.styleFrom(
                backgroundColor: WakaColors.accent,
                shape: const StadiumBorder(),
              ),
              child: const Text(
                'TÔI ĐÃ CHUYỂN KHOẢN',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentSetupCard extends StatelessWidget {
  const _PaymentSetupCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: WakaColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: WakaColors.divider),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Cần cấu hình 3 giá trị công khai',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
          ),
          SizedBox(height: 8),
          SelectableText(
            'PAYMENT_BANK_ID\n'
            'PAYMENT_ACCOUNT_NUMBER\n'
            'PAYMENT_ACCOUNT_NAME',
            style: TextStyle(
              color: WakaColors.accent,
              fontFamily: 'monospace',
              height: 1.5,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Đây là thông tin nhận tiền, không phải API key. Khóa bí mật của '
            'cổng thanh toán chỉ được lưu ở backend.',
            style: TextStyle(color: WakaColors.mutedText, height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _QrUnavailable extends StatelessWidget {
  const _QrUnavailable({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      const Icon(Icons.qr_code_2_rounded, size: 116, color: Colors.black26),
      const SizedBox(height: 12),
      Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.black54, height: 1.4),
      ),
    ],
  );
}

class _QrInfoRow extends StatelessWidget {
  const _QrInfoRow({required this.label, required this.value, this.onCopy});

  final String label;
  final String value;
  final VoidCallback? onCopy;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 108,
          child: Text(
            label,
            style: const TextStyle(color: WakaColors.mutedText),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        if (onCopy != null)
          IconButton(
            tooltip: 'Sao chép $label',
            visualDensity: VisualDensity.compact,
            onPressed: onCopy,
            icon: const Icon(Icons.copy_rounded, size: 18),
          ),
      ],
    ),
  );
}

class _VoucherSelection {
  const _VoucherSelection(this.voucher);

  final ShopCheckoutVoucher? voucher;
}

class _VoucherPicker extends StatelessWidget {
  const _VoucherPicker({
    required this.subtotal,
    required this.vouchers,
    required this.selectedVoucher,
  });

  final int subtotal;
  final List<ShopCheckoutVoucher> vouchers;
  final ShopCheckoutVoucher? selectedVoucher;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 4, 18, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Chọn Waka Voucher',
              style: TextStyle(
                color: Colors.white,
                fontSize: 21,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Giá trị đơn hàng: ${_formatPrice(subtotal)}',
              style: const TextStyle(color: WakaColors.mutedText),
            ),
            const SizedBox(height: 14),
            for (final voucher in vouchers) ...[
              _VoucherCard(
                voucher: voucher,
                subtotal: subtotal,
                selected: voucher.id == selectedVoucher?.id,
              ),
              const SizedBox(height: 10),
            ],
            if (selectedVoucher != null)
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  key: const ValueKey('voucher-remove'),
                  onPressed: () =>
                      Navigator.pop(context, const _VoucherSelection(null)),
                  icon: const Icon(Icons.close_rounded),
                  label: const Text('Không dùng voucher'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _VoucherCard extends StatelessWidget {
  const _VoucherCard({
    required this.voucher,
    required this.subtotal,
    required this.selected,
  });

  final ShopCheckoutVoucher voucher;
  final int subtotal;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final eligible = voucher.isEligible(subtotal);
    return Opacity(
      opacity: eligible ? 1 : .5,
      child: InkWell(
        key: ValueKey('checkout-voucher-${voucher.id}'),
        onTap: eligible
            ? () => Navigator.pop(context, _VoucherSelection(voucher))
            : null,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: WakaColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? WakaColors.accent : WakaColors.divider,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0x22FF2D6C),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.confirmation_number_outlined,
                  color: WakaColors.flashPink,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${voucher.id} • ${voucher.title}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      voucher.description,
                      style: const TextStyle(
                        color: WakaColors.mutedText,
                        fontSize: 12,
                      ),
                    ),
                    if (!eligible) ...[
                      const SizedBox(height: 5),
                      Text(
                        'Cần mua thêm ${_formatPrice(voucher.minimumSubtotal - subtotal)}',
                        style: const TextStyle(
                          color: WakaColors.flashPink,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (selected)
                const Icon(Icons.check_circle, color: WakaColors.accent),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddressForm extends StatefulWidget {
  const _AddressForm({this.initialValue, required this.locationRepository});

  final ShopShippingAddress? initialValue;
  final ShopLocationRepository locationRepository;

  @override
  State<_AddressForm> createState() => _AddressFormState();
}

class _AddressFormState extends State<_AddressForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _recipientController;
  late final TextEditingController _phoneController;
  late final TextEditingController _streetController;
  late final TextEditingController _provinceController;
  late final TextEditingController _districtController;
  late final TextEditingController _wardController;
  List<ShopAdministrativeUnit> _provinces = const [];
  List<ShopAdministrativeUnit> _districts = const [];
  List<ShopAdministrativeUnit> _wards = const [];
  int? _provinceCode;
  int? _districtCode;
  int? _wardCode;
  String _addressLabel = 'Nhà riêng';
  bool _loadingLocations = true;
  bool _manualLocation = false;
  String? _locationError;

  @override
  void initState() {
    super.initState();
    _recipientController = TextEditingController(
      text: widget.initialValue?.recipient,
    );
    _phoneController = TextEditingController(text: widget.initialValue?.phone);
    _streetController = TextEditingController(
      text: widget.initialValue?.streetAddress,
    );
    _provinceController = TextEditingController(
      text: widget.initialValue?.province,
    );
    _districtController = TextEditingController(
      text: widget.initialValue?.district,
    );
    _wardController = TextEditingController(text: widget.initialValue?.ward);
    _addressLabel = widget.initialValue?.label ?? 'Nhà riêng';
    _loadLocations();
  }

  @override
  void dispose() {
    _recipientController.dispose();
    _phoneController.dispose();
    _streetController.dispose();
    _provinceController.dispose();
    _districtController.dispose();
    _wardController.dispose();
    super.dispose();
  }

  Future<void> _loadLocations() async {
    try {
      final provinces = await widget.locationRepository.getProvinces();
      final savedProvince = widget.initialValue?.provinceCode;
      final provinceCode = provinces.any((unit) => unit.code == savedProvince)
          ? savedProvince
          : null;
      var districts = const <ShopAdministrativeUnit>[];
      int? districtCode;
      var wards = const <ShopAdministrativeUnit>[];
      int? wardCode;
      if (provinceCode != null) {
        districts = await widget.locationRepository.getDistricts(provinceCode);
        final savedDistrict = widget.initialValue?.districtCode;
        districtCode = districts.any((unit) => unit.code == savedDistrict)
            ? savedDistrict
            : null;
      }
      if (districtCode != null) {
        wards = await widget.locationRepository.getWards(districtCode);
        final savedWard = widget.initialValue?.wardCode;
        wardCode = wards.any((unit) => unit.code == savedWard)
            ? savedWard
            : null;
      }
      if (!mounted) return;
      setState(() {
        _provinces = provinces;
        _districts = districts;
        _wards = wards;
        _provinceCode = provinceCode;
        _districtCode = districtCode;
        _wardCode = wardCode;
        _manualLocation =
            widget.initialValue != null &&
            provinceCode == null &&
            widget.initialValue!.province.isNotEmpty;
        _loadingLocations = false;
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _loadingLocations = false;
        _manualLocation = true;
        _locationError =
            'Không tải được danh mục địa chỉ. Bạn vẫn có thể nhập thủ công.';
      });
    }
  }

  Future<void> _selectProvince(int? code) async {
    setState(() {
      _provinceCode = code;
      _districtCode = null;
      _wardCode = null;
      _districts = const [];
      _wards = const [];
      _loadingLocations = code != null;
      _locationError = null;
    });
    if (code == null) return;
    try {
      final districts = await widget.locationRepository.getDistricts(code);
      if (!mounted || _provinceCode != code) return;
      setState(() {
        _districts = districts;
        _loadingLocations = false;
      });
    } on Object {
      if (mounted) _enableManualLocation();
    }
  }

  Future<void> _selectDistrict(int? code) async {
    setState(() {
      _districtCode = code;
      _wardCode = null;
      _wards = const [];
      _loadingLocations = code != null;
      _locationError = null;
    });
    if (code == null) return;
    try {
      final wards = await widget.locationRepository.getWards(code);
      if (!mounted || _districtCode != code) return;
      setState(() {
        _wards = wards;
        _loadingLocations = false;
      });
    } on Object {
      if (mounted) _enableManualLocation();
    }
  }

  String? _unitName(List<ShopAdministrativeUnit> units, int? code) {
    for (final unit in units) {
      if (unit.code == code) return unit.name;
    }
    return null;
  }

  void _enableManualLocation() {
    _provinceController.text =
        _unitName(_provinces, _provinceCode) ?? _provinceController.text;
    _districtController.text =
        _unitName(_districts, _districtCode) ?? _districtController.text;
    _wardController.text = _unitName(_wards, _wardCode) ?? _wardController.text;
    setState(() {
      _loadingLocations = false;
      _manualLocation = true;
      _locationError =
          'Không tải được hoặc không tìm thấy địa chỉ. Vui lòng nhập thủ công.';
    });
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final province = _manualLocation
        ? _provinceController.text.trim()
        : _unitName(_provinces, _provinceCode) ?? '';
    final district = _manualLocation
        ? _districtController.text.trim()
        : _unitName(_districts, _districtCode) ?? '';
    final ward = _manualLocation
        ? _wardController.text.trim()
        : _unitName(_wards, _wardCode) ?? '';
    Navigator.pop(
      context,
      ShopShippingAddress(
        recipient: _recipientController.text.trim(),
        phone: _phoneController.text.trim(),
        provinceCode: _manualLocation ? 0 : _provinceCode ?? 0,
        province: province,
        districtCode: _manualLocation ? 0 : _districtCode ?? 0,
        district: district,
        wardCode: _manualLocation ? 0 : _wardCode ?? 0,
        ward: ward,
        streetAddress: _streetController.text.trim(),
        label: _addressLabel,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * .88,
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 4, 18, 20),
              children: [
                const Text(
                  'Địa chỉ nhận hàng',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 14),
                _AddressField(
                  controller: _recipientController,
                  label: 'Tên người nhận',
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 12),
                _AddressField(
                  controller: _phoneController,
                  label: 'Số điện thoại',
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    final phone = value?.replaceAll(RegExp(r'\s'), '') ?? '';
                    return RegExp(r'^(0|\+84)[0-9]{9,10}$').hasMatch(phone)
                        ? null
                        : 'Số điện thoại chưa đúng định dạng';
                  },
                ),
                const SizedBox(height: 12),
                if (_loadingLocations)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: LinearProgressIndicator(color: WakaColors.accent),
                  ),
                if (_locationError != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0x22FF2D6C),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _locationError!,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                if (!_loadingLocations && !_manualLocation) ...[
                  _LocationDropdown(
                    key: const ValueKey('address-province'),
                    label: 'Tỉnh/Thành phố',
                    value: _provinceCode,
                    units: _provinces,
                    onChanged: _selectProvince,
                  ),
                  const SizedBox(height: 12),
                  _LocationDropdown(
                    key: const ValueKey('address-district'),
                    label: 'Quận/Huyện',
                    value: _districtCode,
                    units: _districts,
                    onChanged: _provinceCode == null ? null : _selectDistrict,
                  ),
                  const SizedBox(height: 12),
                  _LocationDropdown(
                    key: const ValueKey('address-ward'),
                    label: 'Phường/Xã',
                    value: _wardCode,
                    units: _wards,
                    onChanged: _districtCode == null
                        ? null
                        : (value) => setState(() => _wardCode = value),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _enableManualLocation,
                      child: const Text('Không tìm thấy? Nhập thủ công'),
                    ),
                  ),
                ] else if (_manualLocation) ...[
                  _AddressField(
                    controller: _provinceController,
                    label: 'Tỉnh/Thành phố',
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 12),
                  _AddressField(
                    controller: _districtController,
                    label: 'Quận/Huyện',
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 12),
                  _AddressField(
                    controller: _wardController,
                    label: 'Phường/Xã',
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 12),
                ],
                _AddressField(
                  controller: _streetController,
                  label: 'Số nhà, tên đường',
                  minLines: 2,
                  maxLines: 2,
                  textInputAction: TextInputAction.done,
                ),
                const SizedBox(height: 14),
                const Text(
                  'Loại địa chỉ',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  children: [
                    for (final label in const ['Nhà riêng', 'Văn phòng'])
                      ChoiceChip(
                        label: Text(label),
                        selected: _addressLabel == label,
                        selectedColor: const Color(0x5520D5A2),
                        onSelected: (_) =>
                            setState(() => _addressLabel = label),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                const Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: WakaColors.accent,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Lưu làm địa chỉ mặc định trên thiết bị này',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    onPressed: _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: WakaColors.accent,
                    ),
                    child: const Text('LƯU ĐỊA CHỈ'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LocationDropdown extends StatelessWidget {
  const _LocationDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.units,
    required this.onChanged,
  });

  final String label;
  final int? value;
  final List<ShopAdministrativeUnit> units;
  final ValueChanged<int?>? onChanged;

  @override
  Widget build(BuildContext context) => DropdownButtonFormField<int>(
    initialValue: units.any((unit) => unit.code == value) ? value : null,
    isExpanded: true,
    dropdownColor: WakaColors.elevated,
    decoration: InputDecoration(
      labelText: label,
      filled: true,
      fillColor: WakaColors.surface,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    ),
    items: [
      for (final unit in units)
        DropdownMenuItem(value: unit.code, child: Text(unit.name)),
    ],
    onChanged: onChanged,
    validator: (selected) => selected == null ? 'Vui lòng chọn $label' : null,
  );
}

class _AddressField extends StatelessWidget {
  const _AddressField({
    required this.controller,
    required this.label,
    required this.textInputAction,
    this.keyboardType,
    this.minLines = 1,
    this.maxLines = 1,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final TextInputAction textInputAction;
  final TextInputType? keyboardType;
  final int minLines;
  final int maxLines;
  final FormFieldValidator<String>? validator;

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    keyboardType: keyboardType,
    textInputAction: textInputAction,
    minLines: minLines,
    maxLines: maxLines,
    style: const TextStyle(color: Colors.white),
    decoration: InputDecoration(
      labelText: label,
      filled: true,
      fillColor: WakaColors.surface,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    ),
    validator:
        validator ??
        (value) => value == null || value.trim().isEmpty
            ? 'Vui lòng nhập $label'
            : null,
  );
}

class _CheckoutProductLine extends StatelessWidget {
  const _CheckoutProductLine({required this.line});

  final ShopCheckoutLine line;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(
        width: 76,
        height: 96,
        child: _CheckoutProductArtwork(product: line.product),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              line.product.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              line.product.type,
              style: const TextStyle(color: WakaColors.mutedText),
            ),
            const SizedBox(height: 9),
            Row(
              children: [
                if (line.product.oldPrice.isNotEmpty) ...[
                  Text(
                    line.product.oldPrice,
                    style: const TextStyle(
                      color: Colors.white38,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                  const SizedBox(width: 7),
                ],
                Expanded(
                  child: Text(
                    line.product.price,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Text(
                  'x${line.quantity}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ],
  );
}

class _CheckoutProductArtwork extends StatelessWidget {
  const _CheckoutProductArtwork({required this.product});

  final ShopProduct product;

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: product.colors),
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: const Icon(Icons.menu_book_rounded, color: Colors.white70),
    );
    if (product.imageAsset.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.asset(
          product.imageAsset,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => fallback,
        ),
      );
    }
    if (product.imageUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          product.imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => fallback,
        ),
      );
    }
    return fallback;
  }
}

class _PaymentIcon extends StatelessWidget {
  const _PaymentIcon({required this.method});

  final ShopPaymentMethod method;

  @override
  Widget build(BuildContext context) => Container(
    width: 54,
    height: 54,
    decoration: BoxDecoration(
      color: WakaColors.elevatedSoft,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Icon(
      method.icon,
      color: method.isAvailable ? WakaColors.accent : Colors.white70,
      size: 28,
    ),
  );
}

class _CheckoutSection extends StatelessWidget {
  const _CheckoutSection({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Material(
      color: WakaColors.background,
      child: Padding(padding: const EdgeInsets.all(18), child: child),
    ),
  );
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.icon,
    required this.title,
    this.action,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, color: Colors.white, size: 26),
      const SizedBox(width: 10),
      Expanded(
        child: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 19,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      if (action != null)
        TextButton(
          onPressed: onAction,
          style: TextButton.styleFrom(
            foregroundColor: WakaColors.accent,
            padding: EdgeInsets.zero,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(action!),
              const Icon(Icons.chevron_right_rounded, size: 18),
            ],
          ),
        ),
    ],
  );
}

class _LabelValueRow extends StatelessWidget {
  const _LabelValueRow({
    required this.label,
    required this.value,
    this.valueColor = Colors.white,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final Color valueColor;
  final bool emphasize;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        child: Text(
          label,
          style: TextStyle(
            color: emphasize ? Colors.white : WakaColors.mutedText,
            fontSize: emphasize ? 17 : 15,
            fontWeight: emphasize ? FontWeight.w800 : FontWeight.w400,
          ),
        ),
      ),
      const SizedBox(width: 12),
      Text(
        value,
        textAlign: TextAlign.right,
        style: TextStyle(
          color: valueColor,
          fontSize: emphasize ? 20 : 15,
          fontWeight: emphasize ? FontWeight.w900 : FontWeight.w500,
        ),
      ),
    ],
  );
}

int _priceValue(String value) =>
    int.tryParse(value.replaceAll(RegExp('[^0-9]'), '')) ?? 0;

String _formatPrice(int value) {
  final text = value.toString();
  final buffer = StringBuffer();
  for (var index = 0; index < text.length; index++) {
    buffer.write(text[index]);
    final remaining = text.length - index - 1;
    if (remaining > 0 && remaining % 3 == 0) buffer.write('.');
  }
  return '${buffer.toString()}đ';
}
