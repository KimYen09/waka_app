import '../constants/api_endpoints.dart';
import 'auth_api_service.dart';
import 'rest_api_client.dart';

class BookReview {
  const BookReview({
    required this.id,
    required this.rating,
    required this.comment,
    required this.displayName,
    required this.isAnonymous,
    required this.createdAt,
  });
  final int id;
  final int rating;
  final String comment;
  final String displayName;
  final bool isAnonymous;
  final DateTime? createdAt;

  factory BookReview.fromJson(Map<String, Object?> json) => BookReview(
    id: (json['id'] as num?)?.toInt() ?? 0,
    rating: (json['rating'] as num?)?.toInt() ?? 0,
    comment: json['comment']?.toString() ?? '',
    displayName: json['displayName']?.toString() ?? 'Độc giả',
    isAnonymous: json['isAnonymous'] == true,
    createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
  );
}

class BookReviewSummary {
  const BookReviewSummary({
    required this.averageRating,
    required this.reviewCount,
    required this.reviews,
  });
  final double averageRating;
  final int reviewCount;
  final List<BookReview> reviews;
}

class BookReviewsService {
  const BookReviewsService({this.client = const RestApiClient()});
  final RestApiClient client;

  Future<BookReviewSummary> getReviews(int bookId) async {
    final response = await client.getJson(
      Uri.parse('${ApiEndpoints.apiBooks}/$bookId/reviews'),
    );
    final data = _map(response['data']);
    return BookReviewSummary(
      averageRating: (data['averageRating'] as num?)?.toDouble() ?? 0,
      reviewCount: (data['reviewCount'] as num?)?.toInt() ?? 0,
      reviews: (data['reviews'] as List? ?? const [])
          .map((item) => BookReview.fromJson(_map(item)))
          .toList(),
    );
  }

  Future<void> saveReview(
    int bookId, {
    required int rating,
    required String comment,
    required bool isAnonymous,
  }) async {
    final token = AuthSession.current?.token;
    if (token == null) {
      throw const RestApiException('Bạn cần đăng nhập để đánh giá.');
    }
    await client.postJson(
      Uri.parse('${ApiEndpoints.apiBooks}/$bookId/reviews'),
      {'rating': rating, 'comment': comment, 'isAnonymous': isAnonymous},
      bearerToken: token,
    );
  }
}

Map<String, Object?> _map(Object? value) => value is Map
    ? value.map((key, item) => MapEntry(key.toString(), item))
    : <String, Object?>{};
