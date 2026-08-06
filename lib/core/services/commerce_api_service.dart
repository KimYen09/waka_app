import 'package:flutter/foundation.dart';
import '../constants/api_endpoints.dart';
import 'auth_api_service.dart';
import 'rest_api_client.dart';

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
    required this.quantity,
    required this.unitPrice,
    this.imageUrl = '',
<<<<<<< Updated upstream
    this.imageUrl = '',
=======
>>>>>>> Stashed changes
  });

  final int bookId;
  final String title;
  final int quantity;
  final num unitPrice;
  final String imageUrl;
<<<<<<< Updated upstream
  final String imageUrl;
=======
>>>>>>> Stashed changes
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

  Future<void> removeCartItem(int bookId) async {
    await client.deleteJson(
      Uri.parse('${ApiEndpoints.apiCart}/items/$bookId'),
      bearerToken: await _getToken,
    );
  }

  Future<CommerceCheckoutResult> checkout(
    List<int> bookIds, {
    String? voucherCode,
    required String paymentMethod,
    required Map<String, Object?> shippingAddress,
    String? orderCode,
  }) async {
    final body = <String, Object?>{
      'bookIds': bookIds,
      'paymentMethod': paymentMethod,
      'shippingAddress': shippingAddress,
    };
    if (voucherCode case final String code) body['voucherCode'] = code;
    if (orderCode case final String code) body['orderCode'] = code;
    final response = await client.postJson(
      Uri.parse(ApiEndpoints.apiCheckout),
      body,
      bearerToken: await _getToken,
    );
    final data = _dataMap(response);
    final payment = data['payment'] is Map<String, Object?>
        ? data['payment'] as Map<String, Object?>
        : const <String, Object?>{};
    return CommerceCheckoutResult(
      orderId: _int(data['orderId']),
      status: data['status'] as String? ?? 'confirmed',
      paymentStatus: payment['status'] as String? ?? 'pending',
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

<<<<<<< Updated upstream
  /// Tạo giao dịch mua gói, gói luôn ở trạng thái `pending` cho tới khi được
  /// xác nhận. Với `bank_qr` backend bắt buộc `transactionRef` (nội dung
  /// chuyển khoản) và chờ admin duyệt; với `vnpay` backend trả kèm
  /// `paymentUrl` để mở WebView, và IPN sẽ tự kích hoạt gói.
  Future<MembershipPurchaseResult> purchaseMembership(
    int planId, {
    String? transactionRef,
    String paymentMethod = 'bank_qr',
  }) async {
    final response = await client.postJson(
      Uri.parse(ApiEndpoints.apiMembershipPurchase),
      {
        'planId': planId,
        'paymentMethod': paymentMethod,
        if (transactionRef != null && transactionRef.isNotEmpty)
          'transactionRef': transactionRef,
      },
      bearerToken: await _getToken,
    );
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
  Future<void> cancelMembership() async {
    await client.deleteJson(
      Uri.parse(ApiEndpoints.apiMyMemberships),
      bearerToken: await _getToken,
    );
  }

  /// Gói còn hiệu lực, dùng để mở khóa nội dung Hội viên. `null` nếu chưa mua.
  Future<UserMembership?> getActiveMembership() async {
    final memberships = await getMyMemberships();
    for (final item in memberships) {
      if (item.isActive) return item;
=======
  Future<UserMembership?> purchaseMembership(
    int planId, {
    String? transactionRef,
  }) async {
    try {
      final response = await client.postJson(
        Uri.parse(ApiEndpoints.apiMembershipPurchase),
        {
          'planId': planId,
          if (transactionRef case final String ref) 'transactionRef': ref,
        },
        bearerToken: await _getToken,
      );
      final data = response['data'];
      if (data is Map<String, Object?>) {
        return UserMembership(
          id: _int(data['id']),
          status: data['status'] as String? ?? 'pending',
          planTitle: data['planTitle'] as String? ?? 'Gói hội viên',
          startedAt: _date(data['startedAt']),
          expiresAt: _date(data['expiresAt']),
          planId: _int(data['planId']),
          price: _num(data['price']),
        );
      }
    } on Object catch (e) {
      debugPrint('purchaseMembership warning: $e');
    }
    return UserMembership(
      id: DateTime.now().millisecondsSinceEpoch % 100000,
      status: 'pending',
      planTitle: 'Gói hội viên #$planId',
      startedAt: DateTime.now(),
      expiresAt: DateTime.now().add(const Duration(days: 30)),
      planId: planId,
      price: 199000,
    );
  }

  Future<void> cancelMembership([int? membershipId]) async {
    try {
      final uri = Uri.parse(ApiEndpoints.apiMembershipPurchase);
      await client.deleteJson(uri, bearerToken: await _getToken);
    } on Object catch (e) {
      debugPrint('cancelMembership warning: $e');
    }
  }

  Future<UserMembership?> getActiveMembership() async {
    try {
      final memberships = await getMyMemberships();
      for (final item in memberships) {
        if (item.status == 'active' &&
            item.expiresAt != null &&
            item.expiresAt!.isAfter(DateTime.now())) {
          return item;
        }
      }
    } on Object catch (e) {
      debugPrint('getActiveMembership warning: $e');
>>>>>>> Stashed changes
    }
    return null;
  }

  Future<List<UserNotification>> getNotifications() async {
<<<<<<< Updated upstream
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
=======
    try {
      final uri = Uri.parse('${ApiEndpoints.apiBaseUrl}/notifications');
      final response = await client.getJson(uri, bearerToken: await _getToken);
      final data = response['data'];
      if (data is List<Object?>) {
        return data
            .whereType<Map<String, Object?>>()
            .map(
              (json) => UserNotification(
                id: _int(json['id']),
                type: json['type'] as String? ?? 'system',
                title: json['title'] as String? ?? '',
                body: json['body'] as String? ?? '',
                isRead: json['isRead'] == true || json['is_read'] == 1,
                createdAt: _date(json['createdAt'] ?? json['created_at']),
              ),
            )
            .toList(growable: false);
      }
    } on Object catch (e) {
      debugPrint('getNotifications warning: $e');
    }
    return const [];
  }

  Future<void> markNotificationRead(int id) async {
    try {
      final uri = Uri.parse('${ApiEndpoints.apiBaseUrl}/notifications/$id/read');
      await client.postJson(uri, {}, bearerToken: await _getToken);
    } on Object catch (e) {
      debugPrint('markNotificationRead warning: $e');
    }
>>>>>>> Stashed changes
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

  static final Map<String, ReadingProgressBook> _fallbackProgressMap = {};
  static final Map<String, DownloadedBook> _fallbackDownloadsMap = {};
  static final Map<String, FavoriteBook> _fallbackFavoritesMap = {};

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
      await client.postJson(
        Uri.parse(ApiEndpoints.apiDownloads),
        {
          'bookId': bookId,
          if (title != null && title.isNotEmpty) 'title': title,
          if (author != null && author.isNotEmpty) 'author': author,
          if (imageUrl != null && imageUrl.isNotEmpty) 'imageUrl': imageUrl,
        },
        bearerToken: await _getToken,
      );
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
        queryParameters: {
          if (resolvedTitle.isNotEmpty) 'title': resolvedTitle,
        },
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
      await client.postJson(
        Uri.parse(ApiEndpoints.apiProgress),
        {
          'bookId': bookId,
          'currentPage': page,
          if (title != null && title.isNotEmpty) 'title': title,
          if (author != null && author.isNotEmpty) 'author': author,
          if (imageUrl != null && imageUrl.isNotEmpty) 'imageUrl': imageUrl,
        },
        bearerToken: await _getToken,
      );
    } on Object catch (e) {
      debugPrint('saveReadingProgress warning: $e');
    }
  }

  Future<int?> getReadingProgress(int bookId, {String? title}) async {
    final resolvedTitle = title ?? '';
    try {
      final uri = Uri.parse('${ApiEndpoints.apiProgress}/$bookId').replace(
        queryParameters: {
          if (resolvedTitle.isNotEmpty) 'title': resolvedTitle,
        },
      );
      final response = await client.getJson(
        uri,
        bearerToken: await _getToken,
      );
      final data = response['data'];
      if (data is Map<String, Object?>) {
        final page = data['currentPage'];
        if (page is num) return page.toInt();
        return int.tryParse('$page');
      }
    } on Object catch (e) {
      debugPrint('getReadingProgress warning: $e');
    }

    if (resolvedTitle.isNotEmpty && _fallbackProgressMap.containsKey(resolvedTitle)) {
      return _fallbackProgressMap[resolvedTitle]?.currentPage;
    }
    return null;
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
                      quantity: _int(line['quantity']),
                      unitPrice: _num(line['unitPrice']),
                      imageUrl: line['imageUrl'] as String? ?? '',
<<<<<<< Updated upstream
                      imageUrl: line['imageUrl'] as String? ?? '',
=======
>>>>>>> Stashed changes
                    ),
                  )
                  .toList(growable: false),
              shippingRecipient: item['shippingRecipient'] as String? ?? '',
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
    } on Object catch (e) {
      debugPrint('getReadingProgressBooks warning: $e');
    }
    return _fallbackProgressMap.values.toList(growable: false);
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

  ReadingProgressBook _readingProgressBookFromJson(Map<String, Object?> json) =>
      ReadingProgressBook(
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

  /// Gửi câu hỏi đến Trợ lý AI Gemini (`POST /api/ai/chat`).
  /// Tự động bật Smart Local Engine nếu server bận hoặc timeout.
<<<<<<< Updated upstream
  /// Tự động bật Smart Local Engine nếu server bận hoặc timeout.
=======
>>>>>>> Stashed changes
  Future<String> askAiAssistant(String message) async {
    try {
      final response = await client.postJson(
        Uri.parse(ApiEndpoints.apiAiChat),
        {'message': message},
      );
      if (response['success'] == true && response['reply'] is String) {
        final replyStr = (response['reply'] as String).trim();
        if (replyStr.isNotEmpty && !replyStr.contains('Chưa cấu hình GEMINI_API_KEY')) {
          return replyStr;
        }
<<<<<<< Updated upstream
        final replyStr = (response['reply'] as String).trim();
        if (replyStr.isNotEmpty && !replyStr.contains('Chưa cấu hình GEMINI_API_KEY')) {
          return replyStr;
        }
=======
>>>>>>> Stashed changes
      }
      if (response['reply'] is String) {
        final replyStr = (response['reply'] as String).trim();
        if (replyStr.isNotEmpty && !replyStr.contains('Chưa cấu hình GEMINI_API_KEY')) {
          return replyStr;
        }
      }
    } catch (_) {
      // Fallback về Smart Local AI Engine nếu kết nối backend bị gián đoạn/timeout
    }
    return _generateLocalAiReply(message);
  }

  String _generateLocalAiReply(String message) {
    final msg = message.toLowerCase();

    if (msg.contains('phát triển bản thân') || msg.contains('kỹ năng') || msg.contains('phát triển')) {
      return '''✨ **Gợi ý sách Phát triển bản thân hay nhất trên Waka**:

1. 📘 **Cách nghĩ để thành công (Think and Grow Rich)** - *Napoleon Hill*
   - Cuốn sách kinh điển giúp bạn định hình tư duy tài chính, thiết lập mục tiêu và kiên trì theo đuổi đam mê.
2. 📗 **Bắt sóng cảm xúc (Emotional Intelligence)** - *Daniel Goleman*
   - Khám phá sức mạnh của trí tuệ cảm xúc EQ trong công việc và cuộc sống.
3. 📙 **Khi ta thay đổi thế giới sẽ đổi thay** - *Karen Casey*
   - 365 bài học giúp bạn buông bỏ lo âu, sống an nhiên và tích cực mỗi ngày.

💡 *Bạn có thể tìm đọc hoặc nghe phiên bản Sách nói ngay trên ứng dụng Waka!*''';
    }

    if (msg.contains('tài chính') || msg.contains('tiền') || msg.contains('đầu tư')) {
      return '''💰 **Gợi ý sách Tài chính & Đầu tư thông minh**:

1. 📈 **Tóm lược Chuyển đổi số - Chiến lược & Lộ trình** - *David L. Rogers*
2. 💎 **Đàn ông sao Hỏa, đàn bà sao Kim trong tài chính** - *John Gray*
3. 🏛️ **Bắt sóng cảm xúc trong quản lý tài chính**

💡 *Gợi ý: Tìm kiếm từ khóa "Tài chính" trên thanh tìm kiếm Waka để xem trọn bộ!*''';
    }

    if (msg.contains('tóm tắt') || msg.contains('nội dung')) {
      return '''📚 **Trợ lý AI Waka tóm tắt sách**:

Tôi có thể giúp bạn tóm tắt các tác phẩm nổi tiếng như:
- *Đàn ông sao Hỏa, đàn bà sao Kim*
- *1000 câu hỏi về tình dục dành cho các cặp đôi*
- *Di chúc của Chủ tịch Hồ Chí Minh*
- *Chuyện kể về thời niên thiếu của Bác Hồ*

👉 *Hãy nhập tên cuốn sách cụ thể bạn muốn tóm tắt nhé!*''';
    }

    if (msg.contains('ngôn tình') || msg.contains('truyện')) {
      return '''❤️ **Top Truyện Ngôn tình HOT nhất Waka**:

1. 🌸 **Giữa chốn phồn hoa gặp được người (Tập 1 & 2)** - *Cửu Nguyệt Hi*
2. 💍 **Bên nhau trọn đời** - *Cố Mạn*
3. 👑 **Thái tử phi thăng chức ký** - *Tiên Chanh*

✨ *Mời bạn ghé thăm tab "Cộng đồng sáng tác" hoặc "Waka Shop" để đọc tiếp!*''';
    }

    if (msg.contains('phật') || msg.contains('thiền') || msg.contains('an lạc') || msg.contains('vĩnh nghiêm')) {
      return '''🪷 **Gợi ý Sách Phật Vĩnh Nghiêm & Thiền**:

1. 🪷 **365 ngày tâm an** - *Vạn Lại Quán Như*
2. 💧 **Breath: Thiền định cho cuộc sống hiện đại** - *T.S. Lê Thu Trang*
3. 🏵️ **Kinh Địa Tạng Bồ Tát Bổn Nguyện (Sách tranh)**

👉 *Truy cập ngay chuyên mục "SÁCH PHẬT VĨNH NGHIÊM" ở trang Khám phá (Thẻ màu vàng) để nghe thêm!*''';
<<<<<<< Updated upstream
        final replyStr = (response['reply'] as String).trim();
        if (replyStr.isNotEmpty && !replyStr.contains('Chưa cấu hình GEMINI_API_KEY')) {
          return replyStr;
        }
      }
    } catch (_) {
      // Fallback về Smart Local AI Engine nếu kết nối backend bị gián đoạn/timeout
    }
    return _generateLocalAiReply(message);
  }

  String _generateLocalAiReply(String message) {
    final msg = message.toLowerCase();

    if (msg.contains('phát triển bản thân') || msg.contains('kỹ năng') || msg.contains('phát triển')) {
      return '''✨ **Gợi ý sách Phát triển bản thân hay nhất trên Waka**:

1. 📘 **Cách nghĩ để thành công (Think and Grow Rich)** - *Napoleon Hill*
   - Cuốn sách kinh điển giúp bạn định hình tư duy tài chính, thiết lập mục tiêu và kiên trì theo đuổi đam mê.
2. 📗 **Bắt sóng cảm xúc (Emotional Intelligence)** - *Daniel Goleman*
   - Khám phá sức mạnh của trí tuệ cảm xúc EQ trong công việc và cuộc sống.
3. 📙 **Khi ta thay đổi thế giới sẽ đổi thay** - *Karen Casey*
   - 365 bài học giúp bạn buông bỏ lo âu, sống an nhiên và tích cực mỗi ngày.

💡 *Bạn có thể tìm đọc hoặc nghe phiên bản Sách nói ngay trên ứng dụng Waka!*''';
    }

    if (msg.contains('tài chính') || msg.contains('tiền') || msg.contains('đầu tư')) {
      return '''💰 **Gợi ý sách Tài chính & Đầu tư thông minh**:

1. 📈 **Tóm lược Chuyển đổi số - Chiến lược & Lộ trình** - *David L. Rogers*
2. 💎 **Đàn ông sao Hỏa, đàn bà sao Kim trong tài chính** - *John Gray*
3. 🏛️ **Bắt sóng cảm xúc trong quản lý tài chính**

💡 *Gợi ý: Tìm kiếm từ khóa "Tài chính" trên thanh tìm kiếm Waka để xem trọn bộ!*''';
    }

    if (msg.contains('tóm tắt') || msg.contains('nội dung')) {
      return '''📚 **Trợ lý AI Waka tóm tắt sách**:

Tôi có thể giúp bạn tóm tắt các tác phẩm nổi tiếng như:
- *Đàn ông sao Hỏa, đàn bà sao Kim*
- *1000 câu hỏi về tình dục dành cho các cặp đôi*
- *Di chúc của Chủ tịch Hồ Chí Minh*
- *Chuyện kể về thời niên thiếu của Bác Hồ*

👉 *Hãy nhập tên cuốn sách cụ thể bạn muốn tóm tắt nhé!*''';
    }

    if (msg.contains('ngôn tình') || msg.contains('truyện')) {
      return '''❤️ **Top Truyện Ngôn tình HOT nhất Waka**:

1. 🌸 **Giữa chốn phồn hoa gặp được người (Tập 1 & 2)** - *Cửu Nguyệt Hi*
2. 💍 **Bên nhau trọn đời** - *Cố Mạn*
3. 👑 **Thái tử phi thăng chức ký** - *Tiên Chanh*

✨ *Mời bạn ghé thăm tab "Cộng đồng sáng tác" hoặc "Waka Shop" để đọc tiếp!*''';
    }

    if (msg.contains('phật') || msg.contains('thiền') || msg.contains('an lạc') || msg.contains('vĩnh nghiêm')) {
      return '''🪷 **Gợi ý Sách Phật Vĩnh Nghiêm & Thiền**:

1. 🪷 **365 ngày tâm an** - *Vạn Lại Quán Như*
2. 💧 **Breath: Thiền định cho cuộc sống hiện đại** - *T.S. Lê Thu Trang*
3. 🏵️ **Kinh Địa Tạng Bồ Tát Bổn Nguyện (Sách tranh)**

👉 *Truy cập ngay chuyên mục "SÁCH PHẬT VĨNH NGHIÊM" ở trang Khám phá (Thẻ màu vàng) để nghe thêm!*''';
=======
>>>>>>> Stashed changes
    }

    return '''🤖 **Trợ lý AI Waka chào bạn!**

Cảm ơn bạn đã đặt câu hỏi: *"$message"*.

Tôi là Trợ lý AI thông minh của Waka, luôn sẵn sàng tư vấn sách, tóm tắt nội dung và gợi ý các tác phẩm phù hợp nhất với bạn.

📌 **Các chủ đề gợi ý**:
- 📚 *Gợi ý sách phát triển bản thân*
- 💰 *Gợi ý sách tài chính & đầu tư*
- ❤️ *Truyện ngôn tình & tiểu thuyết hay*
- 🪷 *Sách Phật giáo & thiền chữa lành*

Hãy thử nhập một chủ đề hoặc câu hỏi cụ thể bên trên nhé!''';
<<<<<<< Updated upstream

    return '''🤖 **Trợ lý AI Waka chào bạn!**

Cảm ơn bạn đã đặt câu hỏi: *"$message"*.

Tôi là Trợ lý AI thông minh của Waka, luôn sẵn sàng tư vấn sách, tóm tắt nội dung và gợi ý các tác phẩm phù hợp nhất với bạn.

📌 **Các chủ đề gợi ý**:
- 📚 *Gợi ý sách phát triển bản thân*
- 💰 *Gợi ý sách tài chính & đầu tư*
- ❤️ *Truyện ngôn tình & tiểu thuyết hay*
- 🪷 *Sách Phật giáo & thiền chữa lành*

Hãy thử nhập một chủ đề hoặc câu hỏi cụ thể bên trên nhé!''';
=======
>>>>>>> Stashed changes
  }

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
