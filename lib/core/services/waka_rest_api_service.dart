import '../constants/api_endpoints.dart';
import 'rest_api_client.dart';
import 'waka_scraper_service.dart';

class WakaRestApiService {
  const WakaRestApiService({this.client = const RestApiClient()});

  final RestApiClient client;

  Future<WakaScrapeResult> getBooks({int maxPages = 6}) async {
    final books = <WakaScrapedBook>[];
    var page = 1;
    var totalPages = 1;

    do {
      final uri = Uri.parse(
        ApiEndpoints.apiBooks,
      ).replace(queryParameters: {'page': '$page', 'limit': '100'});
      final response = await client.getJson(uri);
      final data = response['data'];
      if (data is! List<Object?>) {
        throw const RestApiException('Danh sách sách không đúng định dạng.');
      }

      books.addAll(data.whereType<Map<String, Object?>>().map(_mapBook));
      final meta = response['meta'];
      if (meta is Map<String, Object?>) {
        totalPages = (meta['totalPages'] as num?)?.toInt() ?? 1;
      }
      page++;
    } while (page <= totalPages && page <= maxPages);

    return WakaScrapeResult(
      pageTitle: 'Waka Demo REST API',
      description: 'Dữ liệu được cung cấp bởi backend của ứng dụng.',
      categories: _categoriesFromBooks(books),
      books: books,
      scrapedAt: DateTime.now(),
    );
  }

  WakaScrapedBook _mapBook(Map<String, Object?> json) {
    final category = json['category'];
    final categoryName = category is Map<String, Object?>
        ? category['name'] as String? ?? ''
        : '';
    return WakaScrapedBook(
      title: json['title'] as String? ?? '',
      url: json['sourceUrl'] as String? ?? '',
      imageUrl: json['imageUrl'] as String? ?? '',
      section: categoryName,
      id: _asInt(json['id']),
      price: _asInt(json['price']),
      discountPercent: _asInt(json['discountPercent']),
      isFeatured: json['isFeatured'] == true,
    );
  }

  int _asInt(Object? value) {
    if (value is num) return value.round();
    return double.tryParse('$value')?.round() ?? 0;
  }

  List<WakaScrapedCategory> _categoriesFromBooks(List<WakaScrapedBook> books) {
    final names = <String>{};
    return books
        .where((book) => book.section.isNotEmpty && names.add(book.section))
        .map(
          (book) => WakaScrapedCategory(
            title: book.section,
            url:
                '${ApiEndpoints.apiBooks}?category=${Uri.encodeQueryComponent(book.section)}',
          ),
        )
        .toList(growable: false);
  }
}
