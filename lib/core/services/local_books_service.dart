import 'dart:convert';

import 'package:flutter/services.dart';

import 'waka_scraper_service.dart';

class LocalBooksService {
  const LocalBooksService({this.assetPath = 'assets/data/books.json'});

  final String assetPath;

  Future<WakaScrapeResult> loadBooks() async {
    final rawJson = await rootBundle.loadString(assetPath);
    final data = jsonDecode(rawJson) as Map<String, Object?>;
    final categoriesData = data['categories'] as List<Object?>? ?? const [];
    final booksData = data['books'] as List<Object?>? ?? const [];

    final books = booksData
        .whereType<Map<String, Object?>>()
        .map((book) {
          final imageUrl = book['imageUrl'] as String? ?? '';
          final shouldUseRemoteImage =
              imageUrl.isNotEmpty && book['useRemoteImage'] == true;

          return WakaScrapedBook(
            title: book['title'] as String? ?? '',
            url: book['url'] as String? ?? '',
            imageUrl: shouldUseRemoteImage ? imageUrl : '',
            section: book['section'] as String? ?? '',
          );
        })
        .where((book) => book.title.isNotEmpty)
        .toList(growable: false);

    return WakaScrapeResult(
      pageTitle: data['pageTitle'] as String? ?? 'Waka Demo Books API',
      description: data['description'] as String? ?? '',
      categories: categoriesData
          .whereType<Map<String, Object?>>()
          .map(
            (category) => WakaScrapedCategory(
              title: category['title'] as String? ?? '',
              url: category['url'] as String? ?? '',
            ),
          )
          .where((category) => category.title.isNotEmpty)
          .toList(growable: false),
      books: _withExpandedSections(books),
      scrapedAt: DateTime.now(),
    );
  }

  List<WakaScrapedBook> _withExpandedSections(List<WakaScrapedBook> books) {
    final expandedBooks = [...books];
    final sectionTitles = {
      'Sách Hội viên': [
        'Bản hợp đồng hôn nhân',
        'Sau ly hôn tôi thành minh tinh',
        'Người thừa kế bí mật',
        'Chạm vào ánh sao',
        'Cô gái đến từ hôm qua',
        'Tháng năm rực rỡ',
        'Đợi em nơi cuối mùa',
        'Mùa hè không tên',
      ],
      'Sách mới mỗi ngày - Dành cho Hội viên!': [
        'Tĩnh lặng giữa đời vội vã',
        'Đi qua mùa giông',
        'Những ngày không quên',
        'Cánh cửa mở ra bình minh',
        'Năm tháng dịu dàng',
        'Một cuốn sách về hy vọng',
        'Đi tìm phiên bản tốt hơn',
        'Hẹn gặp lại thanh xuân',
      ],
      'Bảng Xếp Hạng': [
        'Sức mạnh của thói quen',
        'Đừng lựa chọn an nhàn khi còn trẻ',
        'Càng kỷ luật càng tự do',
        'Làm chủ tư duy',
        'Bí mật của người thành công',
        'Tối giản để hạnh phúc',
        'Dám nghĩ lớn',
        'Nghĩ giàu làm giàu',
      ],
      'Sồi động mùa World Cup 2026': [
        'Ronaldo - Khát vọng đỉnh cao',
        'Mbappe - Tốc độ của giấc mơ',
        'Hành trình sân cỏ',
        'Những trận cầu kinh điển',
        'World Cup và những huyền thoại',
        'Bóng đá thay đổi thế giới',
        'Từ đường biên đến vinh quang',
        'Câu chuyện sau chiếc cúp vàng',
      ],
      'Sách Hiệu Sồi': [
        'Marketing tinh gọn',
        'Quản trị bản thân',
        'Tài chính cá nhân thông minh',
        'Kỹ năng giao tiếp hiện đại',
        'Lãnh đạo bằng sự tử tế',
        'Tư duy phản biện mỗi ngày',
        'Kỷ luật tạo tự do',
        'Đầu tư cho tương lai',
      ],
      'Truyện tranh': [
        'Cún nhỏ nói dối sẽ bị ăn thịt',
        'Đêm trăng bên bờ biển',
        'Quán trà của mèo đen',
        'Mùa hoa trong thành phố',
        'Bức thư gửi ngày mai',
        'Tình yêu dưới mái hiên',
        'Người bạn cạnh cửa sổ',
        'Giấc mơ màu xanh',
      ],
    };

    for (final entry in sectionTitles.entries) {
      final count = expandedBooks
          .where((book) => book.section == entry.key)
          .length;
      var nextIndex = count + 1;
      for (final title in entry.value) {
        if (expandedBooks.any((book) => book.title == title)) continue;
        if (expandedBooks.where((book) => book.section == entry.key).length >=
            14) {
          break;
        }

        expandedBooks.add(
          WakaScrapedBook(
            title: title,
            url:
                'https://waka.vn/local/${entry.key.hashCode.abs()}-$nextIndex.html',
            imageUrl: '',
            section: entry.key,
          ),
        );
        nextIndex++;
      }
    }

    return expandedBooks;
  }
}
