import 'package:flutter/foundation.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/services/auth_api_service.dart';
import '../../core/services/rest_api_client.dart';

class AdminMetrics {
  const AdminMetrics({
    required this.totalBooks,
    required this.pendingBooks,
    required this.approvedBooks,
    required this.lockedBooks,
    required this.totalAuthors,
    required this.activeAuthors,
    required this.lockedAuthors,
    required this.pendingAuthorApplications,
    this.totalOrders = 0,
    this.pendingOrders = 0,
    this.paidOrders = 0,
    this.cancelledOrders = 0,
    this.orderRevenue = 0,
    this.totalPayments = 0,
    this.paidPayments = 0,
    this.refundedPayments = 0,
    this.receivedAmount = 0,
    this.totalUsers = 0,
    this.lockedUsers = 0,
  });

  final int totalBooks;
  final int pendingBooks;
  final int approvedBooks;
  final int lockedBooks;
  final int totalAuthors;
  final int activeAuthors;
  final int lockedAuthors;
  final int pendingAuthorApplications;
  final int totalOrders;
  final int pendingOrders;
  final int paidOrders;
  final int cancelledOrders;
  final int orderRevenue;
  final int totalPayments;
  final int paidPayments;
  final int refundedPayments;
  final int receivedAmount;
  final int totalUsers;
  final int lockedUsers;

  factory AdminMetrics.fromJson(Map<String, Object?> json) {
    final books = _map(json['books']);
    final authors = _map(json['authors']);
    final applications = _map(json['authorApplications']);
    final orders = _map(json['orders']);
    final payments = _map(json['payments']);
    final users = _map(json['users']);
    return AdminMetrics(
      totalBooks: _integer(books['total']),
      pendingBooks: _integer(books['pending']),
      approvedBooks: _integer(books['approved']),
      lockedBooks: _integer(books['locked']),
      totalAuthors: _integer(authors['total']),
      activeAuthors: _integer(authors['active']),
      lockedAuthors: _integer(authors['locked']),
      pendingAuthorApplications: _integer(applications['pending']),
      totalOrders: _integer(orders['total']),
      pendingOrders: _integer(orders['pending']),
      paidOrders: _integer(orders['paid']),
      cancelledOrders: _integer(orders['cancelled']),
      orderRevenue: _integer(orders['revenue']),
      totalPayments: _integer(payments['total']),
      paidPayments: _integer(payments['paid']),
      refundedPayments: _integer(payments['refunded']),
      receivedAmount: _integer(payments['received']),
      totalUsers: _integer(users['total']),
      lockedUsers: _integer(users['locked']),
    );
  }
}

class AdminBook {
  const AdminBook({
    required this.id,
    required this.title,
    required this.author,
    required this.description,
    required this.imageUrl,
    required this.sourceUrl,
    required this.price,
    required this.discountPercent,
    required this.isFeatured,
    required this.moderationStatus,
    required this.moderationNote,
    required this.isLocked,
    required this.lockReason,
    required this.categoryId,
    required this.categoryName,
    required this.authorId,
    required this.updatedAt,
  });

  final int id;
  final String title;
  final String author;
  final String description;
  final String imageUrl;
  final String sourceUrl;
  final int price;
  final int discountPercent;
  final bool isFeatured;
  final String moderationStatus;
  final String moderationNote;
  final bool isLocked;
  final String lockReason;
  final int? categoryId;
  final String categoryName;
  final int? authorId;
  final DateTime? updatedAt;

  factory AdminBook.fromJson(Map<String, Object?> json) => AdminBook(
    id: _integer(json['id']),
    title: _string(json['title']),
    author: _string(json['author']),
    description: _string(json['description']),
    imageUrl: _string(json['imageUrl']),
    sourceUrl: _string(json['sourceUrl']),
    price: _integer(json['price']),
    discountPercent: _integer(json['discountPercent']),
    isFeatured: json['isFeatured'] == true,
    moderationStatus: _string(json['moderationStatus'], fallback: 'pending'),
    moderationNote: _string(json['moderationNote']),
    isLocked: json['isLocked'] == true,
    lockReason: _string(json['lockReason']),
    categoryId: _nullableInteger(json['categoryId']),
    categoryName: _string(json['categoryName']),
    authorId: _nullableInteger(json['authorId']),
    updatedAt: DateTime.tryParse(_string(json['updatedAt'])),
  );
}

class AdminAuthorApplication {
  const AdminAuthorApplication({
    required this.id,
    required this.account,
    required this.realName,
    required this.penName,
    required this.email,
    required this.phone,
    required this.bio,
    required this.portfolioUrl,
    required this.status,
    required this.reviewNote,
    required this.createdAt,
  });

  final int id;
  final String account;
  final String realName;
  final String penName;
  final String email;
  final String phone;
  final String bio;
  final String portfolioUrl;
  final String status;
  final String reviewNote;
  final DateTime? createdAt;

  factory AdminAuthorApplication.fromJson(Map<String, Object?> json) =>
      AdminAuthorApplication(
        id: _integer(json['id']),
        account: _string(json['account']),
        realName: _string(json['realName']),
        penName: _string(json['penName']),
        email: _string(json['email']),
        phone: _string(json['phone']),
        bio: _string(json['bio']),
        portfolioUrl: _string(json['portfolioUrl']),
        status: _string(json['status'], fallback: 'pending'),
        reviewNote: _string(json['reviewNote']),
        createdAt: DateTime.tryParse(_string(json['createdAt'])),
      );
}

class AdminAuthor {
  const AdminAuthor({
    required this.id,
    required this.account,
    required this.displayName,
    required this.penName,
    required this.email,
    required this.phone,
    required this.bio,
    required this.avatarUrl,
    required this.status,
    required this.lockReason,
    required this.bookCount,
  });

  final int id;
  final String account;
  final String displayName;
  final String penName;
  final String email;
  final String phone;
  final String bio;
  final String avatarUrl;
  final String status;
  final String lockReason;
  final int bookCount;

  factory AdminAuthor.fromJson(Map<String, Object?> json) => AdminAuthor(
    id: _integer(json['id']),
    account: _string(json['account']),
    displayName: _string(json['displayName']),
    penName: _string(json['penName']),
    email: _string(json['email']),
    phone: _string(json['phone']),
    bio: _string(json['bio']),
    avatarUrl: _string(json['avatarUrl']),
    status: _string(json['status'], fallback: 'active'),
    lockReason: _string(json['lockReason']),
    bookCount: _integer(json['bookCount']),
  );
}

class AdminOrder {
  const AdminOrder({
    required this.id,
    required this.orderCode,
    required this.account,
    required this.customerName,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.paymentId,
    required this.status,
    required this.total,
    required this.itemCount,
    required this.items,
    required this.shippingRecipient,
    required this.shippingPhone,
    required this.shippingAddress,
    required this.shippingEvents,
    required this.createdAt,
  });

  final int id;
  final String orderCode;
  final String account;
  final String customerName;
  final String paymentMethod;
  final String paymentStatus;
  final int? paymentId;
  final String status;
  final int total;
  final int itemCount;
  final List<String> items;
  final String shippingRecipient;
  final String shippingPhone;
  final String shippingAddress;
  final List<AdminShippingEvent> shippingEvents;
  final DateTime? createdAt;

  factory AdminOrder.fromJson(Map<String, Object?> json) => AdminOrder(
    id: _integer(json['id']),
    orderCode: _string(json['orderCode']),
    account: _string(json['account']),
    customerName: _string(json['customerName']),
    paymentMethod: _string(json['paymentMethod'], fallback: 'cod'),
    paymentStatus: _string(json['paymentStatus'], fallback: 'pending'),
    paymentId: _nullableInteger(json['paymentId']),
    status: _string(json['status'], fallback: 'confirmed'),
    total: _integer(json['total']),
    itemCount: _integer(json['itemCount']),
    items: _list(json['items']).map(_string).toList(),
    shippingRecipient: _string(json['shippingRecipient']),
    shippingPhone: _string(json['shippingPhone']),
    shippingAddress: _string(json['shippingAddress']),
    shippingEvents: _list(
      json['shippingEvents'],
    ).map((event) => AdminShippingEvent.fromJson(_map(event))).toList(),
    createdAt: DateTime.tryParse(_string(json['createdAt'])),
  );
}

class AdminShippingEvent {
  const AdminShippingEvent({
    required this.status,
    required this.location,
    required this.description,
    required this.createdAt,
  });

  final String status;
  final String location;
  final String description;
  final DateTime? createdAt;

  factory AdminShippingEvent.fromJson(Map<String, Object?> json) =>
      AdminShippingEvent(
        status: _string(json['status'], fallback: 'confirmed'),
        location: _string(json['location']),
        description: _string(json['description']),
        createdAt: DateTime.tryParse(_string(json['createdAt'])),
      );
}

class AdminPayment {
  const AdminPayment({
    required this.id,
    required this.account,
    required this.customerName,
    required this.orderId,
    required this.membershipTitle,
    required this.provider,
    required this.transactionRef,
    required this.amount,
    required this.status,
    required this.paidAt,
    required this.createdAt,
  });

  final int id;
  final String account;
  final String customerName;
  final int? orderId;
  final String membershipTitle;
  final String provider;
  final String transactionRef;
  final int amount;
  final String status;
  final DateTime? paidAt;
  final DateTime? createdAt;

  factory AdminPayment.fromJson(Map<String, Object?> json) => AdminPayment(
    id: _integer(json['id']),
    account: _string(json['account']),
    customerName: _string(json['customerName']),
    orderId: _nullableInteger(json['orderId']),
    membershipTitle: _string(json['membershipTitle']),
    provider: _string(json['provider'], fallback: 'demo'),
    transactionRef: _string(json['transactionRef']),
    amount: _integer(json['amount']),
    status: _string(json['status'], fallback: 'pending'),
    paidAt: DateTime.tryParse(_string(json['paidAt'])),
    createdAt: DateTime.tryParse(_string(json['createdAt'])),
  );
}

class AdminUserAccount {
  const AdminUserAccount({
    required this.id,
    required this.identifier,
    required this.displayName,
    required this.role,
    required this.accountStatus,
    required this.orderCount,
    required this.paymentCount,
    required this.totalSpent,
    required this.createdAt,
  });

  final int id;
  final String identifier;
  final String displayName;
  final String role;
  final String accountStatus;
  final int orderCount;
  final int paymentCount;
  final int totalSpent;
  final DateTime? createdAt;

  factory AdminUserAccount.fromJson(Map<String, Object?> json) =>
      AdminUserAccount(
        id: _integer(json['id']),
        identifier: _string(json['identifier']),
        displayName: _string(json['displayName']),
        role: _string(json['role'], fallback: 'reader'),
        accountStatus: _string(json['accountStatus'], fallback: 'active'),
        orderCount: _integer(json['orderCount']),
        paymentCount: _integer(json['paymentCount']),
        totalSpent: _integer(json['totalSpent']),
        createdAt: DateTime.tryParse(_string(json['createdAt'])),
      );
}

class AdminSnapshot {
  const AdminSnapshot({
    required this.metrics,
    required this.books,
    required this.authorApplications,
    required this.authors,
    this.orders = const [],
    this.payments = const [],
    this.users = const [],
    this.reviews = const [],
  });

  final AdminMetrics metrics;
  final List<AdminBook> books;
  final List<AdminAuthorApplication> authorApplications;
  final List<AdminAuthor> authors;
  final List<AdminOrder> orders;
  final List<AdminPayment> payments;
  final List<AdminUserAccount> users;
  final List<AdminReview> reviews;
}

class AdminReview {
  const AdminReview({
    required this.id,
    required this.bookTitle,
    required this.identifier,
    required this.displayName,
    required this.rating,
    required this.comment,
    required this.isAnonymous,
    required this.status,
    required this.lockReason,
    required this.createdAt,
  });
  final int id;
  final String bookTitle;
  final String identifier;
  final String displayName;
  final int rating;
  final String comment;
  final bool isAnonymous;
  final String status;
  final String lockReason;
  final DateTime? createdAt;
  factory AdminReview.fromJson(Map<String, Object?> json) => AdminReview(
    id: _integer(json['id']),
    bookTitle: _string(json['bookTitle']),
    identifier: _string(json['identifier']),
    displayName: _string(json['displayName']),
    rating: _integer(json['rating']),
    comment: _string(json['comment']),
    isAnonymous: json['isAnonymous'] == true,
    status: _string(json['status'], fallback: 'visible'),
    lockReason: _string(json['lockReason']),
    createdAt: DateTime.tryParse(_string(json['createdAt'])),
  );
}

class AdminBookInput {
  const AdminBookInput({
    required this.title,
    required this.author,
    required this.description,
    required this.imageUrl,
    required this.sourceUrl,
    required this.price,
    required this.discountPercent,
    required this.isFeatured,
    required this.moderationStatus,
    this.categoryId,
    this.authorId,
  });

  final String title;
  final String author;
  final String description;
  final String imageUrl;
  final String sourceUrl;
  final int price;
  final int discountPercent;
  final bool isFeatured;
  final String moderationStatus;
  final int? categoryId;
  final int? authorId;

  Map<String, Object?> toJson() => {
    'title': title,
    'author': author,
    'description': description,
    'imageUrl': imageUrl,
    'sourceUrl': sourceUrl,
    'price': price,
    'discountPercent': discountPercent,
    'isFeatured': isFeatured,
    'moderationStatus': moderationStatus,
    'categoryId': categoryId,
    'authorId': authorId,
  };
}

abstract interface class AdminRepository {
  Future<AdminSnapshot> load();
  Future<void> createBook(AdminBookInput input);
  Future<void> updateBook(int id, AdminBookInput input);
  Future<void> moderateBook(int id, String status, {String note = ''});
  Future<void> lockBook(int id, bool locked, {String reason = ''});
  Future<void> reviewAuthorApplication(
    int id,
    String status, {
    String note = '',
  });
  Future<void> updateAuthor(AdminAuthor author);
  Future<void> lockAuthor(int id, bool locked, {String reason = ''});
  Future<void> updateOrderStatus(int id, String status);
  Future<void> addShippingEvent(
    int id, {
    required String status,
    required String location,
    required String description,
  });
  Future<void> updatePaymentStatus(int id, String status);
  Future<void> updateUser(
    int id, {
    required String role,
    required String status,
  });
  Future<void> lockReview(int id, bool locked, {String reason = ''});
}

class AdminApiService implements AdminRepository {
  const AdminApiService({this.client = const RestApiClient()});

  final RestApiClient client;

  String get _token {
    final token = AuthSession.current?.token;
    if (token == null || token.isEmpty) {
      throw const RestApiException('Bạn cần đăng nhập bằng tài khoản admin.');
    }
    return token;
  }

  @override
  Future<AdminSnapshot> load() async {
    Future<Map<String, Object?>> safeGet(String url) async {
      try {
        final token = AuthSession.current?.token ?? '';
        if (token.isEmpty) return const {'data': null};
        return await client.getJson(Uri.parse(url), bearerToken: token);
      } on Object catch (e) {
        debugPrint('AdminApiService safeGet warning ($url): $e');
        return const {'data': null};
      }
    }

    final responses = await Future.wait([
      safeGet(ApiEndpoints.apiAdminDashboard),
      safeGet('${ApiEndpoints.apiAdminBooks}?limit=100'),
      safeGet(ApiEndpoints.apiAdminAuthorApplications),
      safeGet(ApiEndpoints.apiAdminAuthors),
      safeGet(ApiEndpoints.apiAdminOrders),
      safeGet(ApiEndpoints.apiAdminPayments),
      safeGet(ApiEndpoints.apiAdminUsers),
      safeGet(ApiEndpoints.apiAdminReviews),
    ]);
    return AdminSnapshot(
      metrics: AdminMetrics.fromJson(_map(responses[0]['data'])),
      books: _list(
        responses[1]['data'],
      ).map((item) => AdminBook.fromJson(_map(item))).toList(),
      authorApplications: _list(
        responses[2]['data'],
      ).map((item) => AdminAuthorApplication.fromJson(_map(item))).toList(),
      authors: _list(
        responses[3]['data'],
      ).map((item) => AdminAuthor.fromJson(_map(item))).toList(),
      orders: _list(
        responses[4]['data'],
      ).map((item) => AdminOrder.fromJson(_map(item))).toList(),
      payments: _list(
        responses[5]['data'],
      ).map((item) => AdminPayment.fromJson(_map(item))).toList(),
      users: _list(
        responses[6]['data'],
      ).map((item) => AdminUserAccount.fromJson(_map(item))).toList(),
      reviews: _list(
        responses[7]['data'],
      ).map((item) => AdminReview.fromJson(_map(item))).toList(),
    );
  }

  @override
  Future<void> createBook(AdminBookInput input) async {
    await client.postJson(
      Uri.parse(ApiEndpoints.apiAdminBooks),
      input.toJson(),
      bearerToken: _token,
    );
  }

  @override
  Future<void> updateBook(int id, AdminBookInput input) async {
    await client.patchJson(
      Uri.parse('${ApiEndpoints.apiAdminBooks}/$id'),
      input.toJson(),
      bearerToken: _token,
    );
  }

  @override
  Future<void> moderateBook(int id, String status, {String note = ''}) async {
    await client.patchJson(
      Uri.parse('${ApiEndpoints.apiAdminBooks}/$id/moderation'),
      {'status': status, 'note': note},
      bearerToken: _token,
    );
  }

  @override
  Future<void> lockBook(int id, bool locked, {String reason = ''}) async {
    await client.patchJson(
      Uri.parse('${ApiEndpoints.apiAdminBooks}/$id/lock'),
      {'locked': locked, 'reason': reason},
      bearerToken: _token,
    );
  }

  @override
  Future<void> reviewAuthorApplication(
    int id,
    String status, {
    String note = '',
  }) async {
    await client.patchJson(
      Uri.parse('${ApiEndpoints.apiAdminAuthorApplications}/$id'),
      {'status': status, 'note': note},
      bearerToken: _token,
    );
  }

  @override
  Future<void> updateAuthor(AdminAuthor author) async {
    await client.patchJson(
      Uri.parse('${ApiEndpoints.apiAdminAuthors}/${author.id}'),
      {
        'displayName': author.displayName,
        'penName': author.penName,
        'email': author.email,
        'phone': author.phone,
        'bio': author.bio,
        'avatarUrl': author.avatarUrl,
      },
      bearerToken: _token,
    );
  }

  @override
  Future<void> lockAuthor(int id, bool locked, {String reason = ''}) async {
    await client.patchJson(
      Uri.parse('${ApiEndpoints.apiAdminAuthors}/$id/lock'),
      {'locked': locked, 'reason': reason},
      bearerToken: _token,
    );
  }

  @override
  Future<void> updateOrderStatus(int id, String status) async {
    await client.patchJson(
      Uri.parse('${ApiEndpoints.apiAdminOrders}/$id/status'),
      {'status': status},
      bearerToken: _token,
    );
  }

  @override
  Future<void> addShippingEvent(
    int id, {
    required String status,
    required String location,
    required String description,
  }) async {
    await client.postJson(
      Uri.parse('${ApiEndpoints.apiAdminOrders}/$id/shipping-events'),
      {'status': status, 'location': location, 'description': description},
      bearerToken: _token,
    );
  }

  @override
  Future<void> updatePaymentStatus(int id, String status) async {
    await client.patchJson(
      Uri.parse('${ApiEndpoints.apiAdminPayments}/$id/status'),
      {'status': status},
      bearerToken: _token,
    );
  }

  @override
  Future<void> updateUser(
    int id, {
    required String role,
    required String status,
  }) async {
    await client.patchJson(Uri.parse('${ApiEndpoints.apiAdminUsers}/$id'), {
      'role': role,
      'accountStatus': status,
    }, bearerToken: _token);
  }

  @override
  Future<void> lockReview(int id, bool locked, {String reason = ''}) async {
    await client.patchJson(
      Uri.parse('${ApiEndpoints.apiAdminReviews}/$id/lock'),
      {'locked': locked, 'reason': reason},
      bearerToken: _token,
    );
  }
}

Map<String, Object?> _map(Object? value) {
  if (value is Map<String, Object?>) return value;
  if (value is Map) {
    return value.map((key, item) => MapEntry(key.toString(), item));
  }
  return <String, Object?>{};
}

List<Object?> _list(Object? value) => value is List ? value : const [];

String _string(Object? value, {String fallback = ''}) {
  if (value == null) return fallback;
  return value.toString();
}

int _integer(Object? value) {
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

int? _nullableInteger(Object? value) {
  if (value == null) return null;
  final parsed = _integer(value);
  return parsed > 0 ? parsed : null;
}
