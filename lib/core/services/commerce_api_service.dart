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
  });

  final int bookId;
  final String title;
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

  Future<void> purchaseMembership(int planId) async {
    await client.postJson(Uri.parse(ApiEndpoints.apiMembershipPurchase), {
      'planId': planId,
    }, bearerToken: await _getToken);
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
  Future<String> askAiAssistant(String message) async {
    try {
      final response = await client.postJson(
        Uri.parse(ApiEndpoints.apiAiChat),
        {'message': message},
      );
      if (response['success'] == true && response['reply'] is String) {
        return response['reply'] as String;
      }
      if (response['reply'] is String) {
        return response['reply'] as String;
      }
      return response['message'] as String? ??
          'Không nhận được phản hồi từ AI.';
    } catch (e) {
      return 'Không thể kết nối tới Trợ lý AI ($e). Vui lòng thử lại sau.';
    }
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
