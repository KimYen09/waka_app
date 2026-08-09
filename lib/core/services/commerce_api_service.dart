import 'package:flutter/foundation.dart';
import '../constants/api_endpoints.dart';
import 'auth_api_service.dart';
import 'rest_api_client.dart';

class CommercePendingOrderException implements Exception {
  const CommercePendingOrderException({
    required this.message,
    required this.pendingId,
    this.paymentUrl,
    this.expiresAt,
  });

  final String message;
  final int pendingId;
  final String? paymentUrl;
  final String? expiresAt;

  @override
  String toString() => message;
}

class CommerceCartItem {
  const CommerceCartItem({
    required this.bookId,
    required this.quantity,
    required this.title,
    required this.imageUrl,
    required this.sourceUrl,
    required this.price,
    required this.discountPercent,
    required this.unitPrice,
  });

  final int bookId;
  final int quantity;
  final String title;
  final String imageUrl;
  final String sourceUrl;
  final num price;
  final int discountPercent;
  final num unitPrice;
}

class CommerceCart {
  const CommerceCart({required this.items, required this.total});

  final List<CommerceCartItem> items;
  final num total;
}

class MembershipPlan {
  const MembershipPlan({
    required this.id,
    required this.title,
    required this.description,
    required this.durationDays,
    required this.price,
    required this.listPrice,
    required this.paymentChannel,
    required this.bonusDescription,
  });

  final int id;
  final String title;
  final String description;
  final int durationDays;
  final num price;
  final num listPrice;
  final String paymentChannel;
  final String bonusDescription;
}

class UserMembership {
  const UserMembership({
    required this.id,
    required this.status,
    required this.planTitle,
    required this.startedAt,
    required this.expiresAt,
    this.planId = 0,
    this.price = 0,
  });

  final int id;
  final String status;
  final String planTitle;
  final DateTime? startedAt;
  final DateTime? expiresAt;
  final int planId;
  final num price;

  bool get isActive =>
      status == 'active' &&
      expiresAt != null &&
      expiresAt!.isAfter(DateTime.now());

  Duration get remaining =>
      isActive ? expiresAt!.difference(DateTime.now()) : Duration.zero;
}

/// Kết quả `POST /api/memberships/purchase`. [paymentUrl] chỉ có khi thanh
/// toán bằng `vnpay` — mở trong WebView để khách hoàn tất giao dịch.
class MembershipPurchaseResult {
  const MembershipPurchaseResult({required this.membership, this.paymentUrl});

  final UserMembership membership;
  final String? paymentUrl;
}

/// Sách người dùng đã đánh dấu yêu thích (`GET /api/favorites`).
class FavoriteBook {
  const FavoriteBook({
    required this.bookId,
    required this.title,
    required this.author,
    required this.imageUrl,
    required this.price,
    required this.discountPercent,
    required this.createdAt,
  });

  final int bookId;
  final String title;
  final String author;
  final String imageUrl;
  final num price;
  final int discountPercent;
  final DateTime? createdAt;

  /// Giá sau khi trừ phần trăm giảm.
  num get unitPrice => price * (1 - discountPercent / 100);
}

class DownloadedBook {
  const DownloadedBook({
    required this.bookId,
    required this.title,
    required this.author,
    required this.imageUrl,
    required this.sourceUrl,
    required this.downloadedAt,
  });

  final int bookId;
  final String title;
  final String author;
  final String imageUrl;
  final String sourceUrl;
  final DateTime? downloadedAt;
}

class ReadingProgressBook {
  const ReadingProgressBook({
    required this.bookId,
    required this.title,
    required this.author,
    required this.imageUrl,
    required this.sourceUrl,
    required this.currentPage,
    required this.updatedAt,
  });

  final int bookId;
  final String title;
  final String author;
  final String imageUrl;
  final String sourceUrl;
  final int currentPage;
  final DateTime? updatedAt;
}

/// Một dòng sách trong đơn hàng (`items` của `GET /api/orders`).
class CommerceOrderItem {
  const CommerceOrderItem({
    required this.bookId,
    required this.title,
    required this.imageUrl,
    required this.quantity,
    required this.unitPrice,
  });

  final int bookId;
  final String title;
  final String imageUrl;
  final int quantity;
  final num unitPrice;
}

class CommerceOrder {
  const CommerceOrder({
    required this.id,
    required this.status,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.total,
    required this.createdAt,
    required this.itemCount,
    required this.items,
    required this.shippingRecipient,
    required this.shippingPhone,
    required this.shippingAddress,
    required this.shippingEvents,
  });

  final int id;
  final String status;
  final String paymentMethod;
  final String paymentStatus;
  final num total;
  final DateTime? createdAt;
  final int itemCount;
  final List<CommerceOrderItem> items;
  final String shippingRecipient;
  final String shippingPhone;
  final String shippingAddress;
  final List<CommerceShippingEvent> shippingEvents;
}

class CommerceShippingEvent {
  const CommerceShippingEvent({
    required this.status,
    required this.location,
    required this.description,
    required this.createdAt,
  });

  final String status;
  final String location;
  final String description;
  final DateTime? createdAt;
}

class CommerceCheckoutResult {
  const CommerceCheckoutResult({
    required this.orderId,
    required this.status,
    required this.paymentStatus,
    this.paymentUrl,
  });

  final int orderId;
  final String status;
  final String paymentStatus;

  /// URL cổng VNPay để mở trong WebView, chỉ có khi `paymentMethod: 'vnpay'`.
  final String? paymentUrl;
}

class UserNotification {
  const UserNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.isRead,
    required this.createdAt,
  });

  final int id;
  final String type;
  final String title;
  final String body;
  final bool isRead;
  final DateTime? createdAt;
}

class CommerceApiService {
  const CommerceApiService({this.client = const RestApiClient()});

  final RestApiClient client;

  static final Map<String, ReadingProgressBook> _fallbackProgressMap = {};
  static final Map<String, DownloadedBook> _fallbackDownloadsMap = {};
  static final Map<String, FavoriteBook> _fallbackFavoritesMap = {};

  Future<CommerceCart> getCart() async {
    final response = await client.getJson(
      Uri.parse(ApiEndpoints.apiCart),
      bearerToken: await _getToken,
    );
    final data = _dataMap(response);
    final items = (data['items'] as List<Object?>? ?? const [])
        .whereType<Map<String, Object?>>()
        .map(_cartItemFromJson)
        .toList(growable: false);
    return CommerceCart(items: items, total: _num(data['total']));
  }

  Future<void> setCartItem({required int bookId, required int quantity}) async {
    await client.postJson(Uri.parse('${ApiEndpoints.apiCart}/items'), {
      'bookId': bookId,
      'quantity': quantity,
    }, bearerToken: await _getToken);
  }

  Future<void> addToCart(int bookId, {int quantity = 1}) async {
    await setCartItem(bookId: bookId, quantity: quantity);
  }

  Future<void> updateCartItemQuantity({
    required int bookId,
    required int quantity,
  }) async {
    await setCartItem(bookId: bookId, quantity: quantity);
  }

  Future<void> removeFromCart(int bookId) async {
    await client.deleteJson(
      Uri.parse('${ApiEndpoints.apiCart}/items/$bookId'),
      bearerToken: await _getToken,
    );
  }

  Future<void> removeCartItem(int bookId) async => removeFromCart(bookId);

  Future<void> clearCart() async {
    await client.deleteJson(
      Uri.parse('${ApiEndpoints.apiCart}/items'),
      bearerToken: await _getToken,
    );
  }

  Future<CommerceCheckoutResult> checkout(
    Object? bookIds, {
    String? shippingRecipient,
    String? shippingPhone,
    Object? shippingAddress,
    required String paymentMethod,
    String? voucherCode,
    String? orderCode,
    String? note,
  }) async {
    // Build address payload as an object so the backend can parse individual
    // fields (recipient, phone, streetAddress, ward, district, province).
    // Backend validates each field separately and rejects flat strings.
    final Map<String, Object?> addressPayload;
    if (shippingAddress is Map<String, Object?>) {
      // Passed from shop_flow_screens via ShopShippingAddress.toJson()
      // which already has the correct keys.
      addressPayload = shippingAddress;
    } else {
      // Fallback for legacy callers that pass individual fields.
      addressPayload = {
        'recipient': shippingRecipient ?? 'Khách hàng',
        'phone': shippingPhone ?? '0900000000',
        'streetAddress': '',
        'ward': '',
        'district': '',
        'province': '',
      };
    }

    final response = await client.postJson(
      Uri.parse(ApiEndpoints.apiCheckout),
      {
        if (bookIds is List) 'bookIds': bookIds,
        'shippingAddress': addressPayload,
        'paymentMethod': paymentMethod,
        if (voucherCode != null && voucherCode.isNotEmpty)
          'voucherCode': voucherCode,
        if (orderCode != null && orderCode.isNotEmpty) 'orderCode': orderCode,
        if (note != null && note.isNotEmpty) 'note': note,
      },
      bearerToken: await _getToken,
    );
    final data = _dataMap(response);
    return CommerceCheckoutResult(
      orderId: _int(data['orderId']),
      status: data['status'] as String? ?? 'confirmed',
      paymentStatus: data['paymentStatus'] as String? ?? 'pending',
      paymentUrl: data['paymentUrl'] as String?,
    );
  }

  Future<List<MembershipPlan>> getMembershipPlans() async {
    final response = await client.getJson(
      Uri.parse(ApiEndpoints.apiMembershipPlans),
    );
    final data = response['data'];
    if (data is! List<Object?>) return const [];
    return data
        .whereType<Map<String, Object?>>()
        .map(_planFromJson)
        .toList(growable: false);
  }

  /// Tạo giao dịch mua gói, gói luôn ở trạng thái `pending` cho tới khi được
  /// xác nhận. Với `bank_qr` backend bắt buộc `transactionRef` (nội dung
  /// chuyển khoản) và chờ admin duyệt; với `vnpay` backend trả kèm
  /// `paymentUrl` để mở WebView, và IPN sẽ tự kích hoạt gói.
  Future<MembershipPurchaseResult> purchaseMembership(
    int planId, {
    String? transactionRef,
    String paymentMethod = 'bank_qr',
    bool forceCancel = false,
  }) async {
    final response = await client
        .postJson(Uri.parse(ApiEndpoints.apiMembershipPurchase), {
          'planId': planId,
          'paymentMethod': paymentMethod,
          if (transactionRef != null && transactionRef.isNotEmpty)
            'transactionRef': transactionRef,
        }, bearerToken: await _getToken);
    final data = _dataMap(response);
    return MembershipPurchaseResult(
      membership: UserMembership(
        id: _int(data['membershipId']),
        status: data['status'] as String? ?? 'pending',
        planTitle: data['planTitle'] as String? ?? 'Gói hội viên',
        startedAt: _date(data['startedAt']),
        expiresAt: _date(data['expiresAt']),
        planId: _int(data['planId']),
        price: _num(data['price']),
      ),
      paymentUrl: data['paymentUrl'] as String?,
    );
  }

  /// Hủy toàn bộ gói đang hoạt động và giao dịch đang chờ duyệt.
  Future<void> cancelMembership([int? membershipId]) async {
    await client.deleteJson(
      Uri.parse(ApiEndpoints.apiMyMemberships),
      body: membershipId != null ? {'membershipId': membershipId} : null,
      bearerToken: await _getToken,
    );
  }

  /// Gói còn hiệu lực, dùng để mở khóa nội dung Hội viên. `null` nếu chưa mua.
  Future<UserMembership?> getActiveMembership() async {
    final memberships = await getMyMemberships();
    for (final item in memberships) {
      if (item.isActive) return item;
    }
    return null;
  }

  Future<List<UserMembership>> getMyMemberships() async {
    final response = await client.getJson(
      Uri.parse(ApiEndpoints.apiMyMemberships),
      bearerToken: await _getToken,
    );
    final data = response['data'];
    if (data is! List<Object?>) return const [];
    return data
        .whereType<Map<String, Object?>>()
        .map(
          (item) => UserMembership(
            id: _int(item['id']),
            status: item['status'] as String? ?? 'pending',
            planTitle: item['planTitle'] as String? ?? 'Gói hội viên',
            startedAt: _date(item['startedAt']),
            expiresAt: _date(item['expiresAt']),
            planId: _int(item['planId']),
            price: _num(item['price']),
          ),
        )
        .toList(growable: false);
  }

  Future<List<UserNotification>> getNotifications() async {
    final response = await client.getJson(
      Uri.parse(ApiEndpoints.apiNotifications),
      bearerToken: await _getToken,
    );
    final data = response['data'];
    if (data is! List<Object?>) return const [];
    return data
        .whereType<Map<String, Object?>>()
        .map(
          (item) => UserNotification(
            id: _int(item['id']),
            type: item['type'] as String? ?? '',
            title: item['title'] as String? ?? '',
            body: item['body'] as String? ?? '',
            isRead: item['isRead'] == true || item['isRead'] == 1,
            createdAt: _date(item['createdAt']),
          ),
        )
        .toList(growable: false);
  }

  Future<void> markNotificationRead(int id) async {
    await client.patchJson(
      Uri.parse('${ApiEndpoints.apiNotifications}/$id/read'),
      const {},
      bearerToken: await _getToken,
    );
  }

  /// Danh sách sách đã đánh dấu yêu thích, mới nhất trước.
  Future<List<FavoriteBook>> getFavorites() async {
    try {
      final response = await client.getJson(
        Uri.parse(ApiEndpoints.apiFavorites),
        bearerToken: await _getToken,
      );
      final data = response['data'];
      if (data is List<Object?>) {
        final serverList = data
            .whereType<Map<String, Object?>>()
            .map(
              (item) => FavoriteBook(
                bookId: _int(item['id']),
                title: item['title'] as String? ?? '',
                author: item['author'] as String? ?? '',
                imageUrl: item['imageUrl'] as String? ?? '',
                price: _num(item['price']),
                discountPercent: _int(item['discountPercent']),
                createdAt: _date(item['createdAt']),
              ),
            )
            .toList(growable: false);
        final Map<String, FavoriteBook> merged = {};
        for (final item in _fallbackFavoritesMap.values) {
          merged[item.title] = item;
        }
        for (final item in serverList) {
          merged[item.title] = item;
        }
        return merged.values.toList(growable: false);
      }
    } on Object catch (e) {
      debugPrint('getFavorites warning: $e');
    }
    return _fallbackFavoritesMap.values.toList(growable: false);
  }

  /// Backend dùng `INSERT IGNORE` nên gọi lại nhiều lần vẫn an toàn.
  Future<void> addFavorite(
    int bookId, {
    String? title,
    String? author,
    String? imageUrl,
  }) async {
    final resolvedTitle = title ?? 'Sách #$bookId';
    _fallbackFavoritesMap[resolvedTitle] = FavoriteBook(
      bookId: bookId,
      title: resolvedTitle,
      author: author ?? 'Waka',
      imageUrl: imageUrl ?? '',
      price: 99000,
      discountPercent: 0,
      createdAt: DateTime.now(),
    );

    try {
      await client.postJson(
        Uri.parse(ApiEndpoints.apiFavorites),
        {
          'bookId': bookId,
          if (title != null && title.isNotEmpty) 'title': title,
          if (author != null && author.isNotEmpty) 'author': author,
          if (imageUrl != null && imageUrl.isNotEmpty) 'imageUrl': imageUrl,
        },
        bearerToken: await _getToken,
      );
    } on Object catch (e) {
      debugPrint('addFavorite warning: $e');
    }
  }

  Future<void> removeFavorite(int bookId, {String? title}) async {
    final resolvedTitle = title ?? '';
    if (resolvedTitle.isNotEmpty) {
      _fallbackFavoritesMap.remove(resolvedTitle);
    }
    try {
      final uri = Uri.parse('${ApiEndpoints.apiFavorites}/$bookId').replace(
        queryParameters: {
          if (resolvedTitle.isNotEmpty) 'title': resolvedTitle,
        },
      );
      await client.deleteJson(uri, bearerToken: await _getToken);
    } on Object catch (e) {
      debugPrint('removeFavorite warning: $e');
    }
  }

  Future<List<DownloadedBook>> getDownloads() async {
    try {
      final response = await client.getJson(
        Uri.parse(ApiEndpoints.apiDownloads),
        bearerToken: await _getToken,
      );
      final data = response['data'];
      if (data is List<Object?>) {
        final serverList = data
            .whereType<Map<String, Object?>>()
            .map(_downloadedBookFromJson)
            .toList(growable: false);
        final Map<String, DownloadedBook> merged = {};
        for (final item in _fallbackDownloadsMap.values) {
          merged[item.title] = item;
        }
        for (final item in serverList) {
          merged[item.title] = item;
        }
        return merged.values.toList(growable: false);
      }
    } on Object catch (e) {
      debugPrint('getDownloads warning: $e');
    }
    return _fallbackDownloadsMap.values.toList(growable: false);
  }

  Future<void> addDownload(
    int bookId, {
    String? title,
    String? author,
    String? imageUrl,
  }) async {
    final resolvedTitle = title ?? 'Sách #$bookId';
    _fallbackDownloadsMap[resolvedTitle] = DownloadedBook(
      bookId: bookId,
      title: resolvedTitle,
      author: author ?? 'Waka',
      imageUrl: imageUrl ?? '',
      sourceUrl: '',
      downloadedAt: DateTime.now(),
    );

    try {
      await client.postJson(Uri.parse(ApiEndpoints.apiDownloads), {
        'bookId': bookId,
        if (title != null && title.isNotEmpty) 'title': title,
        if (author != null && author.isNotEmpty) 'author': author,
        if (imageUrl != null && imageUrl.isNotEmpty) 'imageUrl': imageUrl,
      }, bearerToken: await _getToken);
    } on Object catch (e) {
      debugPrint('addDownload warning: $e');
    }
  }

  Future<void> removeDownload(int bookId, {String? title}) async {
    final resolvedTitle = title ?? '';
    if (resolvedTitle.isNotEmpty) {
      _fallbackDownloadsMap.remove(resolvedTitle);
    }
    try {
      final uri = Uri.parse('${ApiEndpoints.apiDownloads}/$bookId').replace(
        queryParameters: {if (resolvedTitle.isNotEmpty) 'title': resolvedTitle},
      );
      await client.deleteJson(uri, bearerToken: await _getToken);
    } on Object catch (e) {
      debugPrint('removeDownload warning: $e');
    }
  }

  Future<void> saveReadingProgress(
    int bookId,
    int page, {
    String? title,
    String? author,
    String? imageUrl,
  }) async {
    final resolvedTitle = title ?? 'Sách #$bookId';
    _fallbackProgressMap[resolvedTitle] = ReadingProgressBook(
      bookId: bookId,
      title: resolvedTitle,
      author: author ?? 'Waka',
      imageUrl: imageUrl ?? '',
      sourceUrl: '',
      currentPage: page,
      updatedAt: DateTime.now(),
    );

    try {
      await client.postJson(Uri.parse(ApiEndpoints.apiProgress), {
        'bookId': bookId,
        'currentPage': page,
        if (title != null && title.isNotEmpty) 'title': title,
        if (author != null && author.isNotEmpty) 'author': author,
        if (imageUrl != null && imageUrl.isNotEmpty) 'imageUrl': imageUrl,
      }, bearerToken: await _getToken);
    } on Object catch (e) {
      debugPrint('saveReadingProgress warning: $e');
    }
  }

  Future<int?> getReadingProgress(int bookId, {String? title}) async {
    final resolvedTitle = title ?? '';
    try {
      final uri = Uri.parse('${ApiEndpoints.apiProgress}/$bookId').replace(
        queryParameters: {if (resolvedTitle.isNotEmpty) 'title': resolvedTitle},
      );
      final response = await client.getJson(uri, bearerToken: await _getToken);
      final data = response['data'];
      if (data is Map<String, Object?>) {
        final page = data['currentPage'];
        if (page is num) return page.toInt();
        return int.tryParse('$page');
      }
    } on Object catch (e) {
      debugPrint('getReadingProgress warning: $e');
    }

    if (resolvedTitle.isNotEmpty &&
        _fallbackProgressMap.containsKey(resolvedTitle)) {
      return _fallbackProgressMap[resolvedTitle]?.currentPage;
    }
    return null;
  }

  Future<List<CommerceOrder>> getOrders() async {
    try {
      final response = await client.getJson(
        Uri.parse(ApiEndpoints.apiOrders),
        bearerToken: await _getToken,
      );
      final data = response['data'];
      if (data is! List<Object?>) return const [];
      return data
          .whereType<Map<String, Object?>>()
          .map(
            (item) => CommerceOrder(
              id: _int(item['id']),
              status: item['status'] as String? ?? 'confirmed',
              paymentMethod: item['paymentMethod'] as String? ?? 'cod',
              paymentStatus: item['paymentStatus'] as String? ?? 'pending',
              total: _num(item['total']),
              createdAt: _date(item['createdAt']),
              itemCount: (item['items'] as List<Object?>? ?? const []).length,
              items: (item['items'] as List<Object?>? ?? const [])
                  .whereType<Map<String, Object?>>()
                  .map(
                    (line) => CommerceOrderItem(
                      bookId: _int(line['bookId']),
                      title: line['title'] as String? ?? '',
                      imageUrl: line['imageUrl'] as String? ?? '',
                      quantity: _int(line['quantity']),
                      unitPrice: _num(line['unitPrice']),
                    ),
                  )
                  .toList(growable: false),
              shippingRecipient: item['shippingRecipient'] as String? ?? '',
              shippingPhone: item['shippingPhone'] as String? ?? '',
              shippingAddress: item['shippingAddress'] as String? ?? '',
              shippingEvents:
                  (item['shippingEvents'] as List<Object?>? ?? const [])
                      .whereType<Map<String, Object?>>()
                      .map(
                        (event) => CommerceShippingEvent(
                          status: event['status'] as String? ?? 'confirmed',
                          location: event['location'] as String? ?? '',
                          description: event['description'] as String? ?? '',
                          createdAt: _date(event['createdAt']),
                        ),
                      )
                      .toList(growable: false),
            ),
          )
          .toList(growable: false);
    } on Object catch (e) {
      debugPrint('getOrders warning: $e');
      return const [];
    }
  }

  Future<List<ReadingProgressBook>> getReadingProgressBooks() async {
    try {
      final response = await client.getJson(
        Uri.parse(ApiEndpoints.apiProgress),
        bearerToken: await _getToken,
      );
      final data = response['data'];
      if (data is List<Object?>) {
        final serverList = data
            .whereType<Map<String, Object?>>()
            .map(_readingProgressBookFromJson)
            .toList(growable: false);
        final Map<String, ReadingProgressBook> merged = {};
        for (final item in _fallbackProgressMap.values) {
          merged[item.title] = item;
        }
        for (final item in serverList) {
          merged[item.title] = item;
        }
        return merged.values.toList(growable: false);
      }
    } on Object catch (_) {
      // Quiet fallback
    }
    return _fallbackProgressMap.values.toList(growable: false);
  }

  /// Gửi câu hỏi đến Trợ lý AI Gemini (`POST /api/ai/chat`).
  /// Gửi câu hỏi đến Trợ lý AI Gemini (`POST /api/ai/chat`).
  Future<String> askAiAssistant(String message) async {
    try {
      final response = await client.postJson(
        Uri.parse(ApiEndpoints.apiAiChat),
        {'message': message},
      );
      final replyStr = (response['reply'] as String? ?? '').trim();
      if (replyStr.isNotEmpty) {
        return replyStr;
      }
    } catch (_) {
      // Fallback về Smart Local AI Engine nếu kết nối backend bị gián đoạn/timeout
    }
    return _generateLocalAiReply(message);
  }

  String _generateLocalAiReply(String message) {
    final msg = message.toLowerCase().trim();

    if (msg.contains('muc tieu') || msg.contains('mục tiêu') || msg.contains('loi ich') || msg.contains('lợi ích')) {
      return '''🎯 **Mục tiêu & Lợi ích của việc đọc sách**:

Đọc sách mang lại nhiều giá trị cốt lõi giúp phát triển bản thân và nâng cao chất lượng cuộc sống:

1. 🧠 **Mở rộng tri thức & Nâng cao tư duy**: Sách cung cấp kiến thức chuyên sâu về mọi lĩnh vực từ tài chính, kinh doanh đến văn học, tâm lý.
2. 💡 **Cải thiện khả năng tập trung & Trí nhớ**: Đọc sách thường xuyên rèn luyện khả năng tư duy sâu, kiên nhẫn và ghi nhớ thông tin tốt hơn.
3. 🌿 **Giảm căng thẳng & Chữa lành**: Dành 15-30 phút đọc sách mỗi ngày giúp thư giãn tinh thần, giảm lo âu sau giờ làm việc.
4. 📈 **Phát triển vốn từ & Kỹ năng giao tiếp**: Trau dồi ngôn ngữ phong phú giúp diễn đạt tự tin và lưu khoát hơn.

💡 *Lời khuyên*: Đặt mục tiêu đọc 15-20 trang sách mỗi ngày trên Waka để tạo thói quen bền vững!''';
    }

    if (msg.contains('phát triển bản thân') || msg.contains('phat trien') || msg.contains('kỹ năng') || msg.contains('ky nang')) {
      return '''✨ **Gợi ý sách Phát triển bản thân hay nhất trên Waka**:

1. 📘 **Cách nghĩ để thành công (Think and Grow Rich)** - *Napoleon Hill*
   - Cuốn sách kinh điển giúp bạn định hình tư duy tài chính, thiết lập mục tiêu và kiên trì theo đuổi đam mê.
2. 📗 **Bắt sóng cảm xúc (Emotional Intelligence)** - *Daniel Goleman*
   - Khám phá sức mạnh của trí tuệ cảm xúc EQ trong công việc và cuộc sống.
3. 📙 **Khi ta thay đổi thế giới sẽ đổi thay** - *Karen Casey*
   - 365 bài học giúp bạn buông bỏ lo âu, sống an nhiên và tích cực mỗi ngày.

💡 *Bạn có thể tìm đọc ngay trên ứng dụng Waka!*''';
    }

    if (msg.contains('tài chính') || msg.contains('tai chinh') || msg.contains('tiền') || msg.contains('đầu tư')) {
      return '''💰 **Gợi ý sách Tài chính & Đầu tư thông minh**:

1. 📈 **Tóm lược Chuyển đổi số - Chiến lược & Lộ trình** - *David L. Rogers*
2. 💎 **Đàn ông sao Hỏa, đàn bà sao Kim trong tài chính** - *John Gray*
3. 🏛️ **Bắt sóng cảm xúc trong quản lý tài chính**

💡 *Gợi ý: Tìm kiếm từ khóa "Tài chính" trên thanh tìm kiếm Waka để xem trọn bộ!*''';
    }

    if (msg.contains('tóm tắt') || msg.contains('tom tat') || msg.contains('nội dung')) {
      return '''📚 **Trợ lý AI Waka tóm tắt sách**:

Tôi có thể giúp bạn tóm tắt các tác phẩm nổi tiếng như:
- *Đắc Nhân Tâm* - Nghệ thuật thu phục lòng người & ứng xử trong cuộc sống.
- *Cách Nghĩ Để Thành Công (Think & Grow Rich)* - 13 nguyên tắc làm giàu & tư duy tích cực.
- *Đàn Ông Sao Hỏa, Đàn Bà Sao Kim* - Thấu hiểu tâm lý giao tiếp trong tình yêu.
- *Tuổi Trẻ Đáng Giá Bao Nhiêu* - Định hướng bản thân & khai phá tiềm năng.

👉 *Hãy nhập tên cuốn sách cụ thể bạn muốn tóm tắt nhé!*''';
    }

    return '''🤖 **Trợ lý AI Waka đã nhận được câu hỏi**: *"$message"*

Dựa trên thắc mắc của bạn, đây là thông tin tư vấn từ Waka:

- 📌 **Trả lời**: Đọc sách là chìa khóa hiệu quả nhất để trau dồi tri thức và rèn luyện tư duy. Dù bạn muốn nâng cao kỹ năng công việc hay tìm kiếm sự thư giãn, Waka luôn có sẵn hàng ngàn đầu sách phù hợp.
- 💡 **Gợi ý**:
  1. Đặt mục tiêu đọc sách từ 15-30 phút mỗi ngày.
  2. Chọn chủ đề bạn yêu thích (Kinh doanh, Kỹ năng sống, Tâm lý, Văn học).
  3. Áp dụng ngay những bài học hay vào cuộc sống hàng ngày.

👉 *Bạn có muốn tôi gợi ý thêm danh sách sách hay theo chủ đề cụ thể nào không?*''';
  }

  Future<String> get _getToken async {
    final token = AuthSession.current?.token;
    if (token == null || token.isEmpty) {
      final session = await AuthSession.ensureSession();
      return session.token;
    }
    return token;
  }

  CommerceCartItem _cartItemFromJson(Map<String, Object?> json) =>
      CommerceCartItem(
        bookId: _int(json['bookId']),
        quantity: _int(json['quantity']),
        title: json['title'] as String? ?? '',
        imageUrl: json['imageUrl'] as String? ?? '',
        sourceUrl: json['sourceUrl'] as String? ?? '',
        price: _num(json['price']),
        discountPercent: _int(json['discountPercent']),
        unitPrice: _num(json['unitPrice']),
      );

  DownloadedBook _downloadedBookFromJson(Map<String, Object?> json) =>
      DownloadedBook(
        bookId: _int(json['id']),
        title: json['title'] as String? ?? '',
        author: json['author'] as String? ?? '',
        imageUrl: json['imageUrl'] as String? ?? '',
        sourceUrl: json['sourceUrl'] as String? ?? '',
        downloadedAt: _date(json['downloadedAt']),
      );

  ReadingProgressBook _readingProgressBookFromJson(
    Map<String, Object?> json,
  ) => ReadingProgressBook(
    bookId: _int(json['bookId']),
    title: json['title'] as String? ?? '',
    author: json['author'] as String? ?? '',
    imageUrl: json['imageUrl'] as String? ?? '',
    sourceUrl: json['sourceUrl'] as String? ?? '',
    currentPage: _int(json['currentPage']),
    updatedAt: _date(json['updatedAt']),
  );

  MembershipPlan _planFromJson(Map<String, Object?> json) => MembershipPlan(
    id: _int(json['id']),
    title: json['title'] as String? ?? '',
    description: json['description'] as String? ?? '',
    durationDays: _int(json['durationDays']),
    price: _num(json['price']),
    listPrice: _num(json['listPrice']),
    paymentChannel: json['paymentChannel'] as String? ?? 'card',
    bonusDescription: json['bonusDescription'] as String? ?? '',
  );

  Map<String, Object?> _dataMap(Map<String, Object?> response) {
    final data = response['data'];
    if (data is! Map<String, Object?>) {
      throw const RestApiException('Phản hồi API không đúng định dạng.');
    }
    return data;
  }
}

int _int(Object? value) =>
    value is num ? value.toInt() : int.tryParse('$value') ?? 0;
num _num(Object? value) => value is num ? value : num.tryParse('$value') ?? 0;
DateTime? _date(Object? value) =>
    value is String ? DateTime.tryParse(value) : null;
