import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waka_demo/core/services/waka_discovery_store.dart';
import 'package:waka_demo/features/reader/book_detail_screen.dart';
import 'package:waka_demo/features/reader/reader_screen.dart';
import 'package:waka_demo/features/shop/shop_constants.dart';
import 'package:waka_demo/features/shop/shop_flow_screens.dart';
import 'package:waka_demo/features/shop/shop_screen.dart';

const _demoBook = BookDetailData(
  title: 'Điểm số quyền lực',
  author: 'Marcus Phung',
  price: '99.000đ',
  section: 'Tài chính cá nhân',
  colors: [Color(0xFFF2EEE4), Color(0xFFB60000)],
  icon: Icons.trending_up_rounded,
);

void main() {
  test('shop fallback products use distinct local cover assets', () {
    const products = [...topProducts, ...suggestedProducts];
    final assets = products.map((product) => product.imageAsset).toList();

    expect(assets.every((asset) => asset.isNotEmpty), isTrue);
    expect(assets.toSet(), hasLength(products.length));
  });

  test(
    'local discovery snapshot contains ranking and recommendation data',
    () async {
      final store = WakaDiscoveryStore(remoteEnabled: false);
      final rankings = await store.getRankings();
      final recommendations = await store.getRecommendations();

      expect(rankings, hasLength(14));
      expect(rankings.first.rank, 1);
      expect(rankings.last.rank, 14);
      expect(rankings.map((entry) => entry.book.title).toSet(), hasLength(14));
      expect(recommendations, hasLength(12));
      expect(recommendations.first.reason, isNotEmpty);
      expect(
        recommendations.every((entry) => entry.book.imageUrl.isNotEmpty),
        isTrue,
      );
    },
  );

  testWidgets('book detail opens the preview reader', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: BookDetailScreen(book: _demoBook)),
    );

    expect(find.text('Điểm số quyền lực'), findsWidgets);
    expect(find.text('ĐỌC THỬ'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ĐỌC THỬ'));
    await tester.pumpAndSettle();

    expect(find.byType(ReaderScreen), findsOneWidget);
    expect(find.text('Hiển thị').hitTestable(), findsNothing);

    await tester.tapAt(const Offset(400, 300));
    await tester.pumpAndSettle();
    expect(find.text('Mục lục').hitTestable(), findsOneWidget);
    expect(find.text('Hiển thị').hitTestable(), findsOneWidget);

    await tester.tap(find.text('Hiển thị'));
    await tester.pumpAndSettle();
    expect(find.text('Tùy chỉnh hiển thị'), findsOneWidget);
    expect(find.text('Sáng'), findsOneWidget);
    expect(find.text('Giấy'), findsOneWidget);
    expect(find.text('Tối'), findsOneWidget);
  });

  testWidgets('member offer can be dismissed', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: BookDetailScreen(book: _demoBook)),
    );

    expect(find.text('ƯU ĐÃI HỘI VIÊN'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();
    expect(find.text('ƯU ĐÃI HỘI VIÊN'), findsNothing);
  });

  testWidgets('reader opens with progress and supports horizontal paging', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: ReaderScreen(book: _demoBook)),
    );

    expect(find.text('Đang mở sách'), findsOneWidget);
    expect(find.text('ĐÓNG'), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(400, 300));
    await tester.pumpAndSettle();
    expect(find.text('1/12'), findsOneWidget);

    await tester.drag(find.byType(PageView), const Offset(-600, 0));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(400, 300));
    await tester.pumpAndSettle();
    expect(find.text('2/12'), findsOneWidget);
  });

  testWidgets('book detail phone layout', (tester) async {
    await tester.binding.setSurfaceSize(const Size(430, 932));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(useMaterial3: true),
        home: const BookDetailScreen(book: _demoBook),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(BookDetailScreen),
      matchesGoldenFile('goldens/book_detail_phone.png'),
    );
  });

  testWidgets('reader phone layout', (tester) async {
    await tester.binding.setSurfaceSize(const Size(430, 932));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(useMaterial3: true),
        home: const BookDetailScreen(book: _demoBook),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ĐỌC THỬ'));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(ReaderScreen),
      matchesGoldenFile('goldens/reader_phone.png'),
    );
  });

  testWidgets('shop category exposes search filter and product grid', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(useMaterial3: true),
        home: ShopProductCategoryScreen(
          category: shopCategories.first,
          products: const [...topProducts, ...suggestedProducts],
        ),
      ),
    );

    expect(find.text('Sách Văn học'), findsOneWidget);
    expect(find.text('Nhập tên sản phẩm'), findsOneWidget);
    expect(find.text('Lọc'), findsOneWidget);
    expect(find.byType(ShopProductTile), findsWidgets);
  });

  testWidgets('shop ranking supports product type filters', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(useMaterial3: true),
        home: const ShopRankingScreen(products: topProducts),
      ),
    );

    expect(find.text('Bảng Xếp hạng'), findsOneWidget);
    expect(find.text('Sách điện tử'), findsOneWidget);
    expect(find.text('Mua ngay'), findsNWidgets(3));

    await tester.tap(find.text('Sách giấy'));
    await tester.pumpAndSettle();
    expect(find.text('Mua ngay'), findsOneWidget);
  });

  testWidgets('shop seller and chat screens match video flows', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(useMaterial3: true),
        home: const ShopSellerScreen(sellers: shopSellers),
      ),
    );

    expect(find.text('Nhà sách Online'), findsOneWidget);
    expect(find.byType(ShopSellerLogo), findsNWidgets(shopSellers.length));

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(useMaterial3: true),
        home: const ShopChatScreen(),
      ),
    );
    await tester.pump();
    expect(find.text('Trò chuyện'), findsOneWidget);
    expect(find.text('Trợ lý Waka'), findsOneWidget);
  });

  testWidgets('shop main phone layout', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(useMaterial3: true),
        home: const Scaffold(body: ShopScreen(loadApiData: false)),
      ),
    );
    final shopContext = tester.element(find.byType(ShopScreen));
    await tester.runAsync(() async {
      await Future.wait([
        precacheImage(
          const AssetImage(ShopAssets.bookIllustration),
          shopContext,
        ),
        for (final category in shopCategories)
          precacheImage(AssetImage(category.imageAsset), shopContext),
      ]);
    });
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(ShopScreen),
      matchesGoldenFile('goldens/shop_main_phone.png'),
    );
  });

  testWidgets('shop cart stores and removes selected products', (tester) async {
    shopCartProducts.value = const [];
    addTearDown(() => shopCartProducts.value = const []);
    addShopProductToCart(topProducts.first);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(useMaterial3: true),
        home: const ShopCartScreen(),
      ),
    );

    expect(find.text(topProducts.first.title), findsOneWidget);
    expect(find.text('Tổng thanh toán'), findsOneWidget);
    await tester.tap(find.byTooltip('Xóa khỏi giỏ'));
    await tester.pump();
    expect(find.text('Giỏ hàng đang trống'), findsOneWidget);
  });
}
