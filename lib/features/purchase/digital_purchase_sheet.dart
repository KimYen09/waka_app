import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../core/services/auth_api_service.dart';
import '../../core/theme/app_theme.dart';

class DigitalPurchaseItem {
  const DigitalPurchaseItem({
    required this.productId,
    required this.title,
    required this.price,
    required this.colors,
    required this.icon,
    this.imageUrl = '',
    this.includedTitles = const [],
  });

  final String productId;
  final String title;
  final String price;
  final String imageUrl;
  final List<Color> colors;
  final IconData icon;
  final List<String> includedTitles;
}

String digitalProductIdForBook(String title) {
  var value = title
      .toLowerCase()
      .replaceAll(RegExp('[àáạảãâầấậẩẫăằắặẳẵ]'), 'a')
      .replaceAll(RegExp('[èéẹẻẽêềếệểễ]'), 'e')
      .replaceAll(RegExp('[ìíịỉĩ]'), 'i')
      .replaceAll(RegExp('[òóọỏõôồốộổỗơờớợởỡ]'), 'o')
      .replaceAll(RegExp('[ùúụủũưừứựửữ]'), 'u')
      .replaceAll(RegExp('[ỳýỵỷỹ]'), 'y')
      .replaceAll('đ', 'd')
      .replaceAll(RegExp('[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'^_+|_+$'), '');
  if (value.isEmpty) value = 'book';
  if (value.length > 28) value = value.substring(0, 28);
  return 'waka_ebook_$value';
}

Future<void> showDigitalBookPurchase(
  BuildContext context,
  DigitalPurchaseItem item,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: const Color(0xFF111111),
    barrierColor: Colors.black.withValues(alpha: 0.72),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => FractionallySizedBox(
      heightFactor: 0.86,
      child: DigitalPurchaseSheet(item: item),
    ),
  );
}

class DigitalPurchaseSheet extends StatefulWidget {
  const DigitalPurchaseSheet({super.key, required this.item});

  final DigitalPurchaseItem item;

  @override
  State<DigitalPurchaseSheet> createState() => _DigitalPurchaseSheetState();
}

class _DigitalPurchaseSheetState extends State<DigitalPurchaseSheet> {
  final _billing = GooglePlayBillingService.instance;
  StreamSubscription<DigitalPurchaseEvent>? _eventSubscription;
  ProductDetails? _storeProduct;
  String? _storeMessage;
  bool _isLoading = true;
  bool _isBuying = false;
  bool _isOwned = false;

  @override
  void initState() {
    super.initState();
    _eventSubscription = _billing.events.listen(_handlePurchaseEvent);
    _loadProduct();
  }

  @override
  void dispose() {
    _eventSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadProduct() async {
    final isOwned = await _billing.isOwned(widget.item.productId);
    final result = await _billing.loadProduct(widget.item.productId);
    if (!mounted) return;
    setState(() {
      _isOwned = isOwned;
      _storeProduct = result.product;
      _storeMessage = result.message;
      _isLoading = false;
    });
  }

  void _handlePurchaseEvent(DigitalPurchaseEvent event) {
    if (!mounted || event.productId != widget.item.productId) return;
    setState(() {
      _isBuying = event.status == DigitalPurchaseStatus.pending;
      if (event.status == DigitalPurchaseStatus.purchased) {
        _isOwned = true;
      }
      _storeMessage = event.message;
    });
  }

  Future<void> _buy() async {
    if (_isOwned) {
      Navigator.of(context).pop();
      return;
    }
    final product = _storeProduct;
    if (product == null) {
      _showSetupDialog();
      return;
    }
    setState(() => _isBuying = true);
    final launched = await _billing.buy(widget.item, product);
    if (!mounted) return;
    if (!launched) {
      setState(() => _isBuying = false);
    }
  }

  void _showSetupDialog() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF242424),
        title: const Text(
          'Chưa kết nối Google Play',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Hãy tạo sản phẩm “${widget.item.productId}” trong Play Console, '
          'phát hành ứng dụng ở Internal testing và cài ứng dụng từ Google '
          'Play. Sau đó cửa sổ thanh toán hệ thống sẽ tự xuất hiện.',
          style: const TextStyle(color: Colors.white70, height: 1.45),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('ĐÃ HIỂU'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final account = AuthSession.current?.user.identifier;
    final displayedPrice = _storeProduct?.price ?? widget.item.price;

    return Container(
      key: const ValueKey('digital-purchase-sheet'),
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white30,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Mua sách điện tử',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                ),
              ],
            ),
            if (account != null && account.isNotEmpty)
              Text(
                'Tài khoản Waka: $account',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white54, fontSize: 14),
              ),
            const SizedBox(height: 22),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _PurchaseBookCover(item: widget.item),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.item.title,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          height: 1.2,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 7),
                      const Text(
                        'Waka · Sách điện tử',
                        style: TextStyle(color: Colors.white54, fontSize: 15),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        displayedPrice,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 23,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (widget.item.includedTitles.isNotEmpty) ...[
              const SizedBox(height: 18),
              const Text(
                'Sách có trong combo',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              for (final title in widget.item.includedTitles)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        size: 17,
                        color: WakaColors.accent,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
            const SizedBox(height: 22),
            const Divider(color: Colors.white12, height: 1),
            const SizedBox(height: 10),
            const ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: Color(0xFF2A2A2E),
                child: Icon(Icons.account_balance_wallet_outlined),
              ),
              title: Text(
                'Thanh toán qua Google Play',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              subtitle: Text(
                'Phương thức thanh toán do tài khoản Google Play quản lý',
                style: TextStyle(color: Colors.white54),
              ),
              trailing: Icon(
                Icons.chevron_right_rounded,
                color: Colors.white54,
              ),
            ),
            const SizedBox(height: 8),
            if (_isLoading)
              const LinearProgressIndicator(
                minHeight: 2,
                color: WakaColors.accent,
                backgroundColor: Colors.white12,
              )
            else if (_storeMessage != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1D1D20),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white12),
                ),
                child: Text(
                  _storeMessage!,
                  style: TextStyle(
                    color: _isOwned ? WakaColors.accent : Colors.white60,
                    height: 1.35,
                  ),
                ),
              ),
            const SizedBox(height: 24),
            const Text(
              'Giá và phương thức thanh toán cuối cùng sẽ hiển thị trong cửa '
              'sổ bảo mật của Google Play.',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 14),
            FilledButton(
              key: const ValueKey('digital-purchase-continue'),
              onPressed: _isLoading || _isBuying ? null : _buy,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(56),
                backgroundColor: const Color(0xFFA8C7FA),
                foregroundColor: const Color(0xFF09244A),
                disabledBackgroundColor: Colors.white12,
                shape: const StadiumBorder(),
              ),
              child: _isBuying
                  ? const SizedBox.square(
                      dimension: 24,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    )
                  : Text(
                      _isOwned
                          ? 'ĐÃ SỞ HỮU · ĐÓNG'
                          : 'TIẾP TỤC VỚI GOOGLE PLAY',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PurchaseBookCover extends StatelessWidget {
  const _PurchaseBookCover({required this.item});

  final DigitalPurchaseItem item;

  @override
  Widget build(BuildContext context) {
    final fallback = DecoratedBox(
      decoration: BoxDecoration(gradient: LinearGradient(colors: item.colors)),
      child: Center(child: Icon(item.icon, color: Colors.white, size: 34)),
    );
    return Container(
      width: 76,
      height: 106,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFF242424),
        borderRadius: BorderRadius.circular(9),
      ),
      child: item.imageUrl.isEmpty
          ? fallback
          : Image.network(
              item.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => fallback,
            ),
    );
  }
}

enum DigitalPurchaseStatus { pending, purchased, canceled, error }

class DigitalPurchaseEvent {
  const DigitalPurchaseEvent({
    required this.productId,
    required this.status,
    required this.message,
  });

  final String productId;
  final DigitalPurchaseStatus status;
  final String message;
}

class StoreProductLookup {
  const StoreProductLookup({this.product, this.message});

  final ProductDetails? product;
  final String? message;
}

class GooglePlayBillingService {
  GooglePlayBillingService._();

  static final instance = GooglePlayBillingService._();

  static const _ownedProductsKey = 'waka_owned_digital_products';
  final _store = InAppPurchase.instance;
  final _secureStorage = const FlutterSecureStorage();
  final _events = StreamController<DigitalPurchaseEvent>.broadcast();
  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;

  Stream<DigitalPurchaseEvent> get events => _events.stream;

  void _ensureListening() {
    _purchaseSubscription ??= _store.purchaseStream.listen(
      _handlePurchaseUpdates,
      onError: (Object error) {
        _events.add(
          DigitalPurchaseEvent(
            productId: '',
            status: DigitalPurchaseStatus.error,
            message: 'Google Play trả về lỗi: $error',
          ),
        );
      },
    );
  }

  Future<StoreProductLookup> loadProduct(String productId) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return StoreProductLookup(
        message: kIsWeb
            ? 'Bản web chỉ xem trước giao diện. Thanh toán ebook bằng Google '
                  'Play cần chạy bản Android.'
            : 'Luồng này hiện được cấu hình cho Google Play trên Android.',
      );
    }
    try {
      _ensureListening();
      if (!await _store.isAvailable().timeout(const Duration(seconds: 12))) {
        return const StoreProductLookup(
          message: 'Google Play Billing chưa sẵn sàng trên thiết bị này.',
        );
      }
      final response = await _store
          .queryProductDetails({productId})
          .timeout(const Duration(seconds: 12));
      if (response.error != null) {
        return StoreProductLookup(message: response.error!.message);
      }
      if (response.productDetails.isEmpty) {
        return StoreProductLookup(
          message: 'Chưa tìm thấy sản phẩm $productId trên Play Console.',
        );
      }
      return StoreProductLookup(product: response.productDetails.first);
    } on TimeoutException {
      return const StoreProductLookup(
        message: 'Google Play phản hồi quá lâu. Hãy kiểm tra mạng rồi thử lại.',
      );
    } catch (error) {
      return StoreProductLookup(
        message: 'Chưa thể kết nối Google Play Billing: $error',
      );
    }
  }

  Future<bool> buy(DigitalPurchaseItem item, ProductDetails product) async {
    try {
      _ensureListening();
      final launched = await _store
          .buyNonConsumable(
            purchaseParam: PurchaseParam(productDetails: product),
          )
          .timeout(const Duration(seconds: 15));
      if (!launched) {
        _events.add(
          DigitalPurchaseEvent(
            productId: item.productId,
            status: DigitalPurchaseStatus.error,
            message: 'Google Play chưa thể mở cửa sổ thanh toán.',
          ),
        );
      }
      return launched;
    } catch (error) {
      _events.add(
        DigitalPurchaseEvent(
          productId: item.productId,
          status: DigitalPurchaseStatus.error,
          message: 'Không thể bắt đầu giao dịch: $error',
        ),
      );
      return false;
    }
  }

  Future<bool> isOwned(String productId) async {
    final products = await _readOwnedProducts();
    return products.contains(productId);
  }

  Future<void> _handlePurchaseUpdates(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (purchase.status == PurchaseStatus.pending) {
        _emit(
          purchase.productID,
          DigitalPurchaseStatus.pending,
          'Đang chờ Google Play xác nhận thanh toán…',
        );
        continue;
      }
      if (purchase.status == PurchaseStatus.error) {
        _emit(
          purchase.productID,
          DigitalPurchaseStatus.error,
          purchase.error?.message ?? 'Giao dịch không thành công.',
        );
        continue;
      }
      if (purchase.status == PurchaseStatus.canceled) {
        _emit(
          purchase.productID,
          DigitalPurchaseStatus.canceled,
          'Bạn đã hủy giao dịch.',
        );
        continue;
      }
      if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        try {
          await _rememberOwnedProduct(purchase.productID);
          if (purchase.pendingCompletePurchase) {
            await _store.completePurchase(purchase);
          }
          _emit(
            purchase.productID,
            DigitalPurchaseStatus.purchased,
            'Thanh toán thành công. Quyền sở hữu sách đã được lưu.',
          );
        } catch (error) {
          _emit(
            purchase.productID,
            DigitalPurchaseStatus.error,
            'Chưa thể lưu quyền sở hữu sách: $error',
          );
        }
      }
    }
  }

  void _emit(String productId, DigitalPurchaseStatus status, String message) {
    _events.add(
      DigitalPurchaseEvent(
        productId: productId,
        status: status,
        message: message,
      ),
    );
  }

  Future<Set<String>> _readOwnedProducts() async {
    try {
      final raw = await _secureStorage.read(key: _ownedProductsKey);
      if (raw == null || raw.isEmpty) return <String>{};
      final decoded = jsonDecode(raw);
      if (decoded is! List) return <String>{};
      return decoded.whereType<String>().toSet();
    } catch (_) {
      return <String>{};
    }
  }

  Future<void> _rememberOwnedProduct(String productId) async {
    final products = await _readOwnedProducts();
    products.add(productId);
    await _secureStorage.write(
      key: _ownedProductsKey,
      value: jsonEncode(products.toList()..sort()),
    );
  }
}
