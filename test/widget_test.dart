import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waka_demo/core/services/auth_api_service.dart';
import 'package:waka_demo/core/services/commerce_api_service.dart';
import 'package:waka_demo/core/services/waka_discovery_store.dart';
import 'package:waka_demo/features/admin/admin_api_service.dart';
import 'package:waka_demo/features/admin/admin_dashboard_screen.dart';
import 'package:waka_demo/features/home/home_screen.dart';
import 'package:waka_demo/features/offer/offer_screen.dart';
import 'package:waka_demo/features/purchase/digital_purchase_sheet.dart';
import 'package:waka_demo/features/reader/book_detail_screen.dart';
import 'package:waka_demo/features/reader/reader_screen.dart';
import 'package:waka_demo/features/shop/shop_address_store.dart';
import 'package:waka_demo/features/shop/shop_checkout_screen.dart';
import 'package:waka_demo/features/shop/shop_constants.dart';
import 'package:waka_demo/features/shop/shop_flow_screens.dart';
import 'package:waka_demo/features/shop/shop_location_service.dart';
import 'package:waka_demo/features/shop/shop_screen.dart';

const _demoBook = BookDetailData(
  title: 'Điểm số quyền lực',
  author: 'Marcus Phung',
  price: '99.000đ',
  section: 'Tài chính cá nhân',
  colors: [Color(0xFFF2EEE4), Color(0xFFB60000)],
  icon: Icons.trending_up_rounded,
);

class _MemoryAddressStore implements ShopAddressStore {
  ShopShippingAddress? value;

  @override
  Future<ShopShippingAddress?> read(String ownerKey) async => value;

  @override
  Future<void> write(String ownerKey, ShopShippingAddress address) async {
    value = address;
  }
}

class _FakeLocationRepository implements ShopLocationRepository {
  static const province = ShopAdministrativeUnit(
    code: 79,
    name: 'Thành phố Hồ Chí Minh',
  );
  static const district = ShopAdministrativeUnit(code: 760, name: 'Quận 1');
  static const ward = ShopAdministrativeUnit(
    code: 26734,
    name: 'Phường Bến Nghé',
  );

  @override
  Future<List<ShopAdministrativeUnit>> getProvinces() async => const [province];

  @override
  Future<List<ShopAdministrativeUnit>> getDistricts(int provinceCode) async =>
      const [district];

  @override
  Future<List<ShopAdministrativeUnit>> getWards(int districtCode) async =>
      const [ward];
}

class _FakeAdminRepository implements AdminRepository {
  int createBookCalls = 0;

  final snapshot = const AdminSnapshot(
    metrics: AdminMetrics(
      totalBooks: 8,
      pendingBooks: 1,
      approvedBooks: 6,
      lockedBooks: 1,
      totalAuthors: 2,
      activeAuthors: 1,
      lockedAuthors: 1,
      pendingAuthorApplications: 1,
    ),
    books: [
      AdminBook(
        id: 1,
        title: 'Truyện đang chờ duyệt',
        author: 'Tác giả Demo',
        description: 'Nội dung giới thiệu',
        imageUrl: '',
        sourceUrl: '',
        price: 49000,
        discountPercent: 0,
        isFeatured: false,
        moderationStatus: 'pending',
        moderationNote: '',
        isLocked: false,
        lockReason: '',
        categoryId: null,
        categoryName: 'Tiểu thuyết',
        authorId: null,
        updatedAt: null,
      ),
    ],
    authorApplications: [
      AdminAuthorApplication(
        id: 2,
        account: 'author@example.com',
        realName: 'Nguyễn Tác Giả',
        penName: 'Mây',
        email: 'author@example.com',
        phone: '0900000000',
        bio: 'Tác giả truyện dài.',
        portfolioUrl: '',
        status: 'pending',
        reviewNote: '',
        createdAt: null,
      ),
    ],
    authors: [
      AdminAuthor(
        id: 3,
        account: 'approved@example.com',
        displayName: 'Tác giả đã duyệt',
        penName: 'Nắng',
        email: 'approved@example.com',
        phone: '',
        bio: '',
        avatarUrl: '',
        status: 'active',
        lockReason: '',
        bookCount: 2,
      ),
    ],
    orders: [
      AdminOrder(
        id: 4,
        orderCode: 'WAKA-QR-4',
        account: 'buyer@example.com',
        customerName: 'Khách QR',
        paymentMethod: 'bank_qr',
        paymentStatus: 'proof_submitted',
        paymentId: 40,
        status: 'payment_review',
        total: 139000,
        itemCount: 1,
        items: ['Sách QR ×1'],
        shippingRecipient: 'Khách QR',
        shippingPhone: '0900000000',
        shippingAddress: 'Quận 1, TP Hồ Chí Minh',
        shippingEvents: [],
        createdAt: null,
      ),
      AdminOrder(
        id: 5,
        orderCode: 'WAKA-COD-5',
        account: 'cod@example.com',
        customerName: 'Khách COD',
        paymentMethod: 'cod',
        paymentStatus: 'pending',
        paymentId: 50,
        status: 'confirmed',
        total: 99000,
        itemCount: 1,
        items: ['Sách COD ×1'],
        shippingRecipient: 'Khách COD',
        shippingPhone: '0911111111',
        shippingAddress: 'Cầu Giấy, Hà Nội',
        shippingEvents: [
          AdminShippingEvent(
            status: 'confirmed',
            location: 'Nhà sách Waka',
            description: 'Đơn COD đã được tiếp nhận.',
            createdAt: null,
          ),
        ],
        createdAt: null,
      ),
    ],
  );

  @override
  Future<void> createBook(AdminBookInput input) async {
    createBookCalls += 1;
  }

  @override
  Future<AdminSnapshot> load() async => snapshot;

  @override
  Future<void> lockAuthor(int id, bool locked, {String reason = ''}) async {}

  @override
  Future<void> lockBook(int id, bool locked, {String reason = ''}) async {}

  @override
  Future<void> moderateBook(int id, String status, {String note = ''}) async {}

  @override
  Future<void> reviewAuthorApplication(
    int id,
    String status, {
    String note = '',
  }) async {}

  @override
  Future<void> updateAuthor(AdminAuthor author) async {}

  @override
  Future<void> updateBook(int id, AdminBookInput input) async {}

  @override
  Future<void> updateOrderStatus(int id, String status) async {}

  @override
  Future<void> addShippingEvent(
    int id, {
    required String status,
    required String location,
    required String description,
  }) async {}

  @override
  Future<void> updatePaymentStatus(int id, String status) async {}

  @override
  Future<void> updateUser(
    int id, {
    required String role,
    required String status,
  }) async {}
}

void main() {
  testWidgets('admin dashboard opens book management and adds a story', (
    tester,
  ) async {
    final repository = _FakeAdminRepository();
    await tester.binding.setSurfaceSize(const Size(430, 932));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(useMaterial3: true),
        home: AdminDashboardScreen(repository: repository),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Trung tâm quản trị'), findsOneWidget);
    expect(find.text('Truyện chờ duyệt'), findsOneWidget);
    expect(find.text('Hồ sơ tác giả'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('admin-section-1')));
    await tester.pumpAndSettle();
    expect(find.text('Truyện đang chờ duyệt'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('admin-add-book')));
    await tester.pumpAndSettle();
    expect(find.text('Thêm truyện mới'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(0), 'Truyện mới');
    await tester.enterText(find.byType(TextFormField).at(1), 'Tác giả mới');
    await tester.tap(find.byKey(const ValueKey('admin-save-book')));
    await tester.pumpAndSettle();

    expect(repository.createBookCalls, 1);
    expect(find.text('Đã thêm truyện mới.'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('admin-section-3')));
    await tester.pumpAndSettle();
    expect(find.text('Đơn hàng (2)'), findsOneWidget);
    expect(find.text('Giao dịch (0)'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('admin-confirm-payment-4')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('admin-shipping-event-5')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('admin-section-4')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('admin-user-search')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('admin-logout')));
    await tester.pumpAndSettle();
    expect(find.text('Đăng xuất?'), findsOneWidget);
    expect(find.text('ĐĂNG XUẤT'), findsOneWidget);
    await tester.tap(find.text('HỦY'));
    await tester.pumpAndSettle();
  });

  test('cart sync restores products and total quantity from API', () async {
    AuthSession.current = const AuthResult(
      user: AuthUser(id: 7, identifier: 'tester@example.com'),
      token: 'test-token',
    );
    shopCartProducts.value = const [];
    shopCartItemCount.value = 0;
    addTearDown(() {
      AuthSession.clear();
      shopCartProducts.value = const [];
      shopCartItemCount.value = 0;
    });

    await syncShopCartFromServer(
      loadCart: () async => const CommerceCart(
        total: 267000,
        items: [
          CommerceCartItem(
            bookId: 1,
            quantity: 3,
            title: 'Sách đã lưu',
            imageUrl: '',
            sourceUrl: 'book-1',
            price: 89000,
            discountPercent: 0,
            unitPrice: 89000,
          ),
        ],
      ),
    );

    expect(shopCartProducts.value, hasLength(1));
    expect(shopCartProducts.value.single.title, 'Sách đã lưu');
    expect(shopCartItemCount.value, 3);
  });

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

  testWidgets('offer book card opens the shared book detail screen', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 932));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(useMaterial3: true),
        home: const Scaffold(body: OffersScreen()),
      ),
    );

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -1600));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(HomeBookCard).first);
    await tester.pumpAndSettle();

    expect(find.byType(BookDetailScreen), findsOneWidget);
    expect(find.text('99.000đ'), findsWidgets);
  });

  testWidgets('offer buy button opens the digital purchase sheet', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 932));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(useMaterial3: true),
        home: const Scaffold(body: OffersScreen()),
      ),
    );

    await tester.tap(find.text('MUA NGAY').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(DigitalPurchaseSheet), findsOneWidget);
    expect(find.text('Mua sách điện tử'), findsOneWidget);
    expect(find.text('Thanh toán qua Google Play'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('digital-purchase-continue')),
      findsOneWidget,
    );
  });

  testWidgets('book detail buy button opens the digital purchase sheet', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 932));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      const MaterialApp(home: BookDetailScreen(book: _demoBook)),
    );

    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('book-detail-buy-button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(DigitalPurchaseSheet), findsOneWidget);
    expect(find.text('Điểm số quyền lực'), findsWidgets);
    expect(find.text('99.000đ'), findsWidgets);
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
    expect(find.text('Trang 1 / 12'), findsOneWidget);
    await tester.tapAt(const Offset(400, 300));
    await tester.pumpAndSettle();
    expect(find.text('1/12'), findsOneWidget);

    await tester.drag(find.byType(PageView), const Offset(-600, 0));
    await tester.pumpAndSettle();
    expect(find.text('Trang 2 / 12'), findsOneWidget);
  });

  testWidgets('reader contents opens the selected chapter', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: ReaderScreen(book: _demoBook)),
    );

    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(PageView), const Offset(-600, 0));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('reader-contents-chapter-1')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('reader-contents-chapter-1')));
    await tester.pumpAndSettle();

    expect(find.text('Trang 6 / 12'), findsOneWidget);
    expect(find.text('Dữ liệu kể câu chuyện gì?'), findsOneWidget);
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

  testWidgets('shop top header stays visible while scrolling', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(useMaterial3: true),
        home: const Scaffold(body: ShopScreen(loadApiData: false)),
      ),
    );

    final header = find.byKey(const ValueKey('shop-sticky-header'));
    expect(header.hitTestable(), findsOneWidget);
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -1200));
    await tester.pumpAndSettle();

    expect(header.hitTestable(), findsOneWidget);
    expect(find.byType(TextField).hitTestable(), findsOneWidget);
  });

  testWidgets('home top header stays visible while scrolling', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(useMaterial3: true),
        home: const Scaffold(body: HomeScreen(loadApiData: false)),
      ),
    );

    final header = find.byKey(const ValueKey('home-sticky-header'));
    expect(header.hitTestable(), findsOneWidget);
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -1200));
    await tester.pumpAndSettle();

    expect(header.hitTestable(), findsOneWidget);
    expect(find.byTooltip('Giỏ hàng').hitTestable(), findsOneWidget);
  });

  testWidgets('shop cart stores and removes selected products', (tester) async {
    shopCartProducts.value = const [];
    shopCartItemCount.value = 0;
    addTearDown(() {
      shopCartProducts.value = const [];
      shopCartItemCount.value = 0;
    });
    addShopProductToCart(topProducts.first);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(useMaterial3: true),
        home: const ShopCartScreen(),
      ),
    );

    expect(find.text(topProducts.first.title), findsOneWidget);
    expect(shopCartItemCount.value, 1);
    expect(find.text('Tổng thanh toán'), findsOneWidget);
    await tester.tap(find.byTooltip('Xóa khỏi giỏ'));
    await tester.pump();
    expect(find.text('Giỏ hàng đang trống'), findsOneWidget);
    expect(shopCartItemCount.value, 0);
  });

  testWidgets('shop checkout renders product, total and payment details', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(useMaterial3: true),
        home: ShopCheckoutScreen(
          lines: [ShopCheckoutLine(product: topProducts.first, quantity: 2)],
          voucherName: 'Giảm 10%',
          voucherDiscount: 10000,
          addressStore: _MemoryAddressStore(),
          onSubmitOrder: (_, _, _, _) async => 1,
        ),
      ),
    );

    expect(find.text('Thanh toán'), findsOneWidget);
    expect(find.text(topProducts.first.title), findsOneWidget);
    expect(find.text('x2'), findsOneWidget);
    expect(find.text('Địa chỉ nhận hàng'), findsOneWidget);
    expect(find.byKey(const ValueKey('checkout-submit')), findsOneWidget);
  });

  testWidgets('shop checkout lets customer select QR payment', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(useMaterial3: true),
        home: const ShopPaymentMethodScreen(
          initialPaymentMethod: ShopPaymentMethod.cashOnDelivery,
        ),
      ),
    );

    expect(find.text('Lựa chọn thanh toán'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('payment-method-bankQr')));
    await tester.pump();

    expect(
      find.descendant(
        of: find.byKey(const ValueKey('payment-method-bankQr')),
        matching: find.byIcon(Icons.check_rounded),
      ),
      findsOneWidget,
    );
  });

  testWidgets('shop checkout loads the saved shipping address', (tester) async {
    final store = _MemoryAddressStore()
      ..value = const ShopShippingAddress(
        recipient: 'Nguyễn Văn A',
        phone: '0901234567',
        provinceCode: 79,
        province: 'Thành phố Hồ Chí Minh',
        districtCode: 760,
        district: 'Quận 1',
        wardCode: 26734,
        ward: 'Phường Bến Nghé',
        streetAddress: '12 Nguyễn Huệ',
      );
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(useMaterial3: true),
        home: ShopCheckoutScreen(
          lines: [ShopCheckoutLine(product: topProducts.first, quantity: 1)],
          addressStore: store,
          locationRepository: _FakeLocationRepository(),
          onSubmitOrder: (_, _, _, _) async => 1,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Nguyễn Văn A'), findsOneWidget);
    expect(
      find.textContaining(
        '12 Nguyễn Huệ, Phường Bến Nghé, Quận 1, Thành phố Hồ Chí Minh',
      ),
      findsWidgets,
    );
  });

  testWidgets('shipping address form selects regions and persists address', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 932));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final store = _MemoryAddressStore();
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(useMaterial3: true),
        home: ShopCheckoutScreen(
          lines: [ShopCheckoutLine(product: topProducts.first, quantity: 1)],
          addressStore: store,
          locationRepository: _FakeLocationRepository(),
          onSubmitOrder: (_, _, _, _) async => 1,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Thêm địa chỉ'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Tên người nhận'),
      'Nguyễn Văn A',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Số điện thoại'),
      '0901234567',
    );
    await tester.tap(find.byKey(const ValueKey('address-province')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Thành phố Hồ Chí Minh').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('address-district')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Quận 1').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('address-ward')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Phường Bến Nghé').last);
    await tester.pumpAndSettle();

    final streetField = find.widgetWithText(TextFormField, 'Số nhà, tên đường');
    await tester.scrollUntilVisible(
      streetField,
      260,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.enterText(streetField, '12 Nguyễn Huệ');
    final saveButton = find.text('LƯU ĐỊA CHỈ');
    await tester.scrollUntilVisible(
      saveButton,
      260,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    expect(store.value?.recipient, 'Nguyễn Văn A');
    expect(
      store.value?.fullAddress,
      '12 Nguyễn Huệ, Phường Bến Nghé, Quận 1, Thành phố Hồ Chí Minh',
    );
  });

  testWidgets('checkout voucher row opens picker and applies voucher', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(useMaterial3: true),
        home: ShopCheckoutScreen(
          lines: [ShopCheckoutLine(product: topProducts.first, quantity: 2)],
          addressStore: _MemoryAddressStore(),
          onSubmitOrder: (_, _, _, _) async => 1,
        ),
      ),
    );
    await tester.pump();

    final voucherRow = find.byKey(const ValueKey('checkout-voucher-row'));
    await tester.scrollUntilVisible(
      voucherRow,
      350,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(voucherRow);
    await tester.pumpAndSettle();
    expect(find.text('Chọn Waka Voucher'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('checkout-voucher-WAKA10')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Đã giảm 17.800đ'), findsOneWidget);
  });

  testWidgets('QR screen handles receiving-account configuration', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(useMaterial3: true),
        home: const ShopQrPaymentScreen(amount: 139000, orderCode: 'WAKA1'),
      ),
    );

    expect(find.text('Thanh toán bằng QR'), findsOneWidget);
    expect(find.text('139.000đ'), findsOneWidget);
    if (ShopBankTransferConfig.isConfigured) {
      expect(find.byKey(const ValueKey('bank-transfer-qr')), findsOneWidget);
      expect(
        ShopBankTransferConfig.qrImageUri(
          amount: 139000,
          orderCode: 'WAKA1',
        ).queryParameters,
        containsPair('amount', '139000'),
      );
    } else {
      expect(
        find.textContaining('Chưa cấu hình tài khoản nhận tiền'),
        findsOneWidget,
      );
      expect(find.textContaining('PAYMENT_BANK_ID'), findsOneWidget);
    }
  });
}
