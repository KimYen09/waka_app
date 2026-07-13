import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../constants/api_endpoints.dart';

class WakaScrapedCategory {
  const WakaScrapedCategory({required this.title, required this.url});

  final String title;
  final String url;

  Map<String, String> toJson() {
    return {'title': title, 'url': url};
  }
}

class WakaScrapedBook {
  const WakaScrapedBook({
    required this.title,
    required this.url,
    required this.imageUrl,
    required this.section,
  });

  final String title;
  final String url;
  final String imageUrl;
  final String section;

  Map<String, String> toJson() {
    return {
      'title': title,
      'url': url,
      'imageUrl': imageUrl,
      'section': section,
    };
  }
}

class WakaScrapeResult {
  const WakaScrapeResult({
    required this.pageTitle,
    required this.description,
    required this.categories,
    required this.books,
    required this.scrapedAt,
  });

  final String pageTitle;
  final String description;
  final List<WakaScrapedCategory> categories;
  final List<WakaScrapedBook> books;
  final DateTime scrapedAt;

  Map<String, Object> toJson() {
    return {
      'pageTitle': pageTitle,
      'description': description,
      'categories': categories.map((category) => category.toJson()).toList(),
      'books': books.map((book) => book.toJson()).toList(),
      'scrapedAt': scrapedAt.toIso8601String(),
    };
  }
}

class WakaScraperException implements Exception {
  const WakaScraperException(this.message);

  final String message;

  @override
  String toString() => 'WakaScraperException: $message';
}

class WakaScraperService {
  const WakaScraperService({this.client});

  static final Uri wakaHomeUri = Uri.parse(ApiEndpoints.wakaHome);

  final HttpClient? client;

  Future<WakaScrapeResult> scrapeHome({Uri? uri}) async {
    final targetUri = uri ?? wakaHomeUri;
    final html = await _downloadHtml(targetUri);
    return parseHomeHtml(html, baseUri: targetUri);
  }

  Future<WakaScrapeResult> scrapeAllBooks({int maxPagesPerCategory = 6}) async {
    final safePageLimit = maxPagesPerCategory.clamp(1, 30).toInt();
    final home = await scrapeHome();
    final booksByUrl = <String, WakaScrapedBook>{};
    final categoriesByUrl = <String, WakaScrapedCategory>{};

    void collect(WakaScrapeResult result, {String sectionFallback = ''}) {
      for (final category in result.categories) {
        categoriesByUrl[category.url] = category;
      }

      for (final book in result.books) {
        final existingBook = booksByUrl[book.url];
        final nextBook = _bookWithSection(book, sectionFallback);
        if (existingBook == null ||
            (existingBook.section.isEmpty && nextBook.section.isNotEmpty)) {
          booksByUrl[book.url] = nextBook;
        }
      }
    }

    collect(home);

    final seedCategories = <WakaScrapedCategory>[
      ..._defaultSeedCategories(),
      ...home.categories,
    ];
    final seenCategoryUrls = <String>{};

    for (final category in seedCategories) {
      final categoryUri = Uri.tryParse(category.url);
      if (categoryUri == null || !_isWakaUrl(categoryUri)) continue;
      if (!seenCategoryUrls.add(categoryUri.toString())) continue;

      for (var page = 1; page <= safePageLimit; page++) {
        final pageUris = _pageCandidates(categoryUri, page);
        var foundBooksInPage = false;

        for (final pageUri in pageUris) {
          try {
            final html = await _downloadHtml(pageUri);
            final result = parseHomeHtml(html, baseUri: pageUri);
            if (result.books.isEmpty) continue;

            collect(result, sectionFallback: category.title);
            foundBooksInPage = true;
            await Future<void>.delayed(const Duration(milliseconds: 180));
            break;
          } on Object {
            continue;
          }
        }

        if (!foundBooksInPage) break;
      }
    }

    return WakaScrapeResult(
      pageTitle: home.pageTitle,
      description: home.description,
      categories: categoriesByUrl.values.toList(growable: false),
      books: booksByUrl.values.toList(growable: false),
      scrapedAt: DateTime.now(),
    );
  }

  WakaScrapeResult parseHomeHtml(String html, {Uri? baseUri}) {
    final base = baseUri ?? wakaHomeUri;
    return WakaScrapeResult(
      pageTitle: _firstMatch(
        html,
        RegExp('<title>(.*?)</title>', caseSensitive: false, dotAll: true),
      ),
      description: _firstMatch(
        html,
        RegExp(
          '<meta[^>]+name=["\']description["\'][^>]+content=["\']([^"\']*)',
          caseSensitive: false,
          dotAll: true,
        ),
      ),
      categories: _parseCategories(html, base),
      books: _parseBooks(html, base),
      scrapedAt: DateTime.now(),
    );
  }

  WakaScrapedBook _bookWithSection(
    WakaScrapedBook book,
    String sectionFallback,
  ) {
    final section = sectionFallback.trim().isEmpty
        ? book.section
        : sectionFallback.trim();

    return WakaScrapedBook(
      title: book.title,
      url: book.url,
      imageUrl: book.imageUrl,
      section: section,
    );
  }

  List<WakaScrapedCategory> _defaultSeedCategories() {
    return [
      WakaScrapedCategory(
        title: 'Sách Hội viên',
        url: ApiEndpoints.wakaCategories['memberBooks']!,
      ),
      WakaScrapedCategory(
        title: 'Sách miễn phí',
        url: ApiEndpoints.wakaCategories['memberBooks']!,
      ),
      WakaScrapedCategory(
        title: 'Sách điện tử',
        url: ApiEndpoints.wakaCategories['ebook']!,
      ),
      WakaScrapedCategory(
        title: 'Sách Hiệu Sồi',
        url: ApiEndpoints.wakaCategories['hieuSoi']!,
      ),
      WakaScrapedCategory(
        title: 'Sách nói',
        url: ApiEndpoints.wakaCategories['audiobook']!,
      ),
      WakaScrapedCategory(
        title: 'Truyện tranh',
        url: ApiEndpoints.wakaCategories['comic']!,
      ),
      WakaScrapedCategory(
        title: 'Sách miễn phí',
        url: ApiEndpoints.wakaCategories['freeBooks']!,
      ),
      WakaScrapedCategory(
        title: 'Sách tóm tắt',
        url: ApiEndpoints.wakaCategories['summaryBooks']!,
      ),
    ];
  }

  Future<String> _downloadHtml(Uri uri) async {
    final httpClient = client ?? HttpClient();
    try {
      final request = await httpClient
          .getUrl(uri)
          .timeout(ApiConfig.requestTimeout);
      request.headers.set(HttpHeaders.userAgentHeader, ApiConfig.userAgent);
      request.headers.set(HttpHeaders.acceptHeader, 'text/html,*/*');

      final response = await request.close().timeout(ApiConfig.requestTimeout);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw WakaScraperException(
          'Không tải được ${uri.toString()} '
          '(HTTP ${response.statusCode}).',
        );
      }

      return response.transform(utf8.decoder).join();
    } on TimeoutException {
      throw const WakaScraperException('Kết nối tới Waka bị quá thời gian.');
    } on SocketException catch (error) {
      throw WakaScraperException('Không có kết nối mạng: ${error.message}');
    } finally {
      if (client == null) {
        httpClient.close(force: true);
      }
    }
  }

  List<WakaScrapedCategory> _parseCategories(String html, Uri baseUri) {
    const allowedTitles = {
      'Sách điện tử',
      'Sách hội viên',
      'Sách Hội viên',
      'Sách hiệu sồi',
      'Sách Hiệu Sồi',
      'Sách nói',
      'Sách mua lẻ',
      'Sách ngoại văn',
      'Truyện tranh',
      'Sách miễn phí',
      'Sách tương tác',
      'Sách tóm tắt',
      'Dịch vụ Xuất bản',
      'Waka Shop',
      'Combo',
      'Tuyển tập',
      'Podcast',
    };

    final categories = <WakaScrapedCategory>[];
    final seenUrls = <String>{};
    for (final match in _anchorPattern.allMatches(html)) {
      final href = match.group(1);
      final label = _cleanText(match.group(2) ?? '');
      if (href == null || label.isEmpty || !allowedTitles.contains(label)) {
        continue;
      }

      final url = _resolveUrl(baseUri, href);
      if (seenUrls.add(url)) {
        categories.add(WakaScrapedCategory(title: label, url: url));
      }
    }

    return categories;
  }

  List<WakaScrapedBook> _parseBooks(String html, Uri baseUri) {
    final books = <WakaScrapedBook>[];
    final seenUrls = <String>{};

    void addBook({
      required String title,
      required String href,
      required String imageSrc,
      required String section,
    }) {
      final cleanTitle = _cleanText(title);
      if (cleanTitle.length < 2 || !_looksLikeBookUrl(href)) return;

      final bookUrl = _resolveUrl(baseUri, href);
      if (!seenUrls.add(bookUrl)) return;

      books.add(
        WakaScrapedBook(
          title: cleanTitle,
          url: bookUrl,
          imageUrl: _resolveUrl(baseUri, imageSrc),
          section: section,
        ),
      );
    }

    for (final match in _anchorPattern.allMatches(html)) {
      final href = match.group(1);
      final anchorHtml = match.group(2) ?? '';
      if (href == null || !_looksLikeBookUrl(href)) continue;

      final imageTag = _imageTagPattern.firstMatch(anchorHtml)?.group(0) ?? '';
      final imageSrc = _readImageSource(imageTag);
      final imageAlt =
          _readAttribute(imageTag, 'alt') ?? _readAttribute(imageTag, 'title');
      final textTitle = _cleanText(anchorHtml);
      final title = _cleanText(imageAlt ?? textTitle);
      if (title.length < 2 || imageSrc == null) continue;

      addBook(
        title: title,
        href: href,
        imageSrc: imageSrc,
        section: _findNearestSection(html, match.start),
      );
    }

    for (final match in _jsonBookPattern.allMatches(html)) {
      final rawBlock = match.group(0) ?? '';
      final href = _decodeJsonString(match.group(1) ?? '');
      final title = _readJsonField(rawBlock, const [
        'title',
        'name',
        'bookName',
        'displayName',
      ]);
      final imageSrc = _readJsonField(rawBlock, const [
        'image',
        'imageUrl',
        'cover',
        'coverUrl',
        'avatar',
        'thumbnail',
        'thumb',
      ]);
      if (title == null || imageSrc == null) continue;

      addBook(
        title: _decodeJsonString(title),
        href: href,
        imageSrc: _decodeJsonString(imageSrc),
        section: _sectionFromUrl(href),
      );
    }

    return books;
  }

  bool _looksLikeBookUrl(String href) {
    return href.contains('/ebook/') ||
        href.contains('/sach-noi/') ||
        href.contains('/truyen-tranh/') ||
        href.contains('/sach-tuong-tac/') ||
        href.contains('/combo/');
  }

  String _findNearestSection(String html, int beforeIndex) {
    final head = html.substring(0, beforeIndex);
    final sectionMatches = RegExp(
      '<h[12][^>]*>(.*?)</h[12]>',
      caseSensitive: false,
      dotAll: true,
    ).allMatches(head);

    if (sectionMatches.isEmpty) return '';
    return _cleanText(sectionMatches.last.group(1) ?? '');
  }

  String _resolveUrl(Uri baseUri, String value) {
    return baseUri.resolve(_decodeHtml(value.trim())).toString();
  }

  String _sectionFromUrl(String href) {
    if (href.contains('/sach-noi/')) return 'Sách nói';
    if (href.contains('/truyen-tranh/')) return 'Truyện tranh';
    if (href.contains('/sach-tuong-tac/')) return 'Sách tương tác';
    if (href.contains('/combo/')) return 'Combo';
    return 'Sách điện tử';
  }

  bool _isWakaUrl(Uri uri) {
    return uri.host == wakaHomeUri.host;
  }

  Uri _withPage(Uri uri, int page) {
    return uri.replace(
      queryParameters: {...uri.queryParameters, 'page': page.toString()},
    );
  }

  List<Uri> _pageCandidates(Uri uri, int page) {
    if (page == 1) return [uri];

    return [
      _withPage(uri, page),
      uri.replace(
        queryParameters: {...uri.queryParameters, 'p': page.toString()},
      ),
      uri.resolve(
        '${uri.path.endsWith('/') ? uri.path : '${uri.path}/'}page/$page',
      ),
    ];
  }

  String _firstMatch(String html, RegExp pattern) {
    return _cleanText(pattern.firstMatch(html)?.group(1) ?? '');
  }

  String? _readAttribute(String tag, String attribute) {
    final pattern = RegExp(
      '$attribute=["\']([^"\']*)["\']',
      caseSensitive: false,
    );
    return pattern.firstMatch(tag)?.group(1);
  }

  String? _readJsonField(String block, List<String> fields) {
    for (final field in fields) {
      final pattern = RegExp(
        '"$field"\\s*:\\s*"([^"]+)"',
        caseSensitive: false,
      );
      final value = pattern.firstMatch(block)?.group(1);
      if (value != null && value.trim().isNotEmpty) return value;
    }

    return null;
  }

  String? _readImageSource(String imageTag) {
    final candidates = [
      _readAttribute(imageTag, 'data-src'),
      _readAttribute(imageTag, 'data-original'),
      _readAttribute(imageTag, 'src'),
    ].whereType<String>().where((value) => value.trim().isNotEmpty).toList();

    if (candidates.isEmpty) return null;
    return candidates.firstWhere(
      (value) => !value.contains('thumb-loading'),
      orElse: () => candidates.first,
    );
  }

  String _cleanText(String value) {
    return _decodeHtml(
      value
          .replaceAll(RegExp('<script.*?</script>', dotAll: true), ' ')
          .replaceAll(RegExp('<style.*?</style>', dotAll: true), ' ')
          .replaceAll(RegExp('<[^>]+>'), ' ')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim(),
    );
  }

  String _decodeHtml(String value) {
    return value
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&apos;', "'")
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&nbsp;', ' ');
  }

  String _decodeJsonString(String value) {
    return _decodeHtml(
      value
          .replaceAll(r'\/', '/')
          .replaceAll(r'\"', '"')
          .replaceAll(r'\u002F', '/')
          .replaceAll(r'\u0026', '&'),
    );
  }
}

final _anchorPattern = RegExp(
  '<a\\b[^>]*href=["\']([^"\']+)["\'][^>]*>(.*?)</a>',
  caseSensitive: false,
  dotAll: true,
);

final _imageTagPattern = RegExp(
  '<img\\b[^>]*>',
  caseSensitive: false,
  dotAll: true,
);

final _jsonBookPattern = RegExp(
  r'\{[^{}]*"(?:url|href|link|slug)"\s*:\s*"([^"]*(?:/ebook/|/sach-noi/|/truyen-tranh/|/sach-tuong-tac/|/combo/)[^"]*)"[^{}]*\}',
  caseSensitive: false,
  dotAll: true,
);
