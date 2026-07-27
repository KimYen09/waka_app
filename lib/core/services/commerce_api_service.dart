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
  });

  final int id;
  final String status;
  final String planTitle;
  final DateTime? startedAt;
  final DateTime? expiresAt;
}

class CommerceOrder {
  const CommerceOrder({
    required this.id,
    required this.status,
    required this.total,
    required this.createdAt,
    required this.itemCount,
  });

  final int id;
  final String status;
  final num total;
  final DateTime? createdAt;
  final int itemCount;
}

class CommerceApiService {
  const CommerceApiService({this.client = const RestApiClient()});

  final RestApiClient client;

  Future<CommerceCart> getCart() async {
    final response = await client.getJson(
      Uri.parse(ApiEndpoints.apiCart),
      bearerToken: _token,
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
    }, bearerToken: _token);
  }

  Future<void> removeCartItem(int bookId) async {
    await client.deleteJson(
      Uri.parse('${ApiEndpoints.apiCart}/items/$bookId'),
      bearerToken: _token,
    );
  }

  Future<void> checkout(List<int> bookIds) async {
    await client.postJson(Uri.parse(ApiEndpoints.apiCheckout), {
      'bookIds': bookIds,
    }, bearerToken: _token);
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
    }, bearerToken: _token);
  }

  Future<List<UserMembership>> getMyMemberships() async {
    final response = await client.getJson(
      Uri.parse(ApiEndpoints.apiMyMemberships),
      bearerToken: _token,
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
          ),
        )
        .toList(growable: false);
  }

  Future<List<CommerceOrder>> getOrders() async {
    final response = await client.getJson(
      Uri.parse(ApiEndpoints.apiOrders),
      bearerToken: _token,
    );
    final data = response['data'];
    if (data is! List<Object?>) return const [];
    return data
        .whereType<Map<String, Object?>>()
        .map(
          (item) => CommerceOrder(
            id: _int(item['id']),
            status: item['status'] as String? ?? 'pending',
            total: _num(item['total']),
            createdAt: _date(item['createdAt']),
            itemCount: (item['items'] as List<Object?>? ?? const []).length,
          ),
        )
        .toList(growable: false);
  }

  String get _token {
    final token = AuthSession.current?.token;
    if (token == null || token.isEmpty) {
      throw const RestApiException('Bạn cần đăng nhập để đồng bộ dữ liệu.');
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
