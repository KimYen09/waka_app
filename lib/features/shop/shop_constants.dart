import 'package:flutter/material.dart';

abstract final class ShopLayout {
  static const double horizontalPadding = 12;
  static const double headerHeight = 64;
  static const double searchHeight = 36;
  static const double categoryAvatarSize = 64;
  static const double sellerAvatarSize = 64;
  static const double couponHeight = 104;
  static const double topProductWidth = 126;
  static const double topProductListHeight = 260;
  static const double topProductImageHeight = 132;
  static const double suggestedImageHeight = 180;
  static const double suggestedProductCardHeight = 320;
  static const double categoryScreenItemHeight = 145;
  static const double categoryScreenImageSize = 74;
}

abstract final class ShopFontSizes {
  static const double sectionTitle = 22;
  static const double categoryLabel = 14;
  static const double sellerLabel = 13;
  static const double productTitle = 15;
  static const double price = 18;
  static const double oldPrice = 13;
  static const double sold = 12;
  static const double categoryScreenLabel = 14;
}

abstract final class ShopAssets {
  static const String bookIllustration = 'assets/images/welcome_books.jpg';
}

class ShopCategory {
  const ShopCategory({
    required this.label,
    required this.colors,
    required this.bookColor,
    this.imageAsset = '',
  });

  final String label;
  final List<Color> colors;
  final Color bookColor;
  final String imageAsset;
}

class ShopSeller {
  const ShopSeller({
    required this.name,
    required this.logo,
    required this.colors,
  });

  final String name;
  final String logo;
  final List<Color> colors;
}

class ShopProduct {
  const ShopProduct({
    required this.title,
    required this.price,
    required this.oldPrice,
    required this.discount,
    required this.sold,
    required this.rank,
    required this.colors,
    this.imageUrl = '',
    this.imageAsset = '',
    this.url = '',
    this.type = 'Sách giấy',
  });

  final String title;
  final String price;
  final String oldPrice;
  final String discount;
  final String sold;
  final int? rank;
  final List<Color> colors;
  final String imageUrl;
  final String imageAsset;
  final String url;
  final String type;
}

const shopCategories = [
  ShopCategory(
    label: 'Sách Văn\nhọc',
    colors: [Color(0xFFFF7A9E), Color(0xFFFFD36B), Color(0xFF55D6F3)],
    bookColor: Color(0xFF7E4A2E),
    imageAsset: 'assets/images/shop_category_literature.jpg',
  ),
  ShopCategory(
    label: 'Sách Thiếu\nnhi',
    colors: [Color(0xFFFF8FB2), Color(0xFFFFE071), Color(0xFF6DE6F4)],
    bookColor: Color(0xFFF4E4AB),
    imageAsset: 'assets/images/shop_category_children.png',
  ),
  ShopCategory(
    label: 'Sách Kinh\ntế',
    colors: [Color(0xFFFF7BA1), Color(0xFFFFDD74), Color(0xFF5FE1E8)],
    bookColor: Color(0xFF57C9C7),
    imageAsset: 'assets/images/shop_category_economics.jpg',
  ),
  ShopCategory(
    label: 'Sách Giáo\nkhoa -\nGiáo Trình',
    colors: [Color(0xFFFF81A7), Color(0xFFFFD86A), Color(0xFF64DCEB)],
    bookColor: Color(0xFF247DB8),
    imageAsset: 'assets/images/shop_category_education.jpg',
  ),
  ShopCategory(
    label: 'Phát triển\nbản thân',
    colors: [Color(0xFFFF7BA1), Color(0xFFFFDD74), Color(0xFF5FE1E8)],
    bookColor: Color(0xFF17466F),
    imageAsset: 'assets/images/shop_category_self_development.jpg',
  ),
  ShopCategory(
    label: 'Sách Kiến\nthức tổng\nhợp',
    colors: [Color(0xFFFF7E9F), Color(0xFFFFD873), Color(0xFF64D9F0)],
    bookColor: Color(0xFF245D77),
    imageAsset: 'assets/images/shop_category_knowledge.jpg',
  ),
  ShopCategory(
    label: 'Sách kỹ\nnăng',
    colors: [Color(0xFFFF7E9F), Color(0xFFFFD873), Color(0xFF64D9F0)],
    bookColor: Color(0xFFB88C65),
    imageAsset: 'assets/images/shop_category_skills.jpg',
  ),
  ShopCategory(
    label: 'Sách ngoại\nvăn',
    colors: [Color(0xFFFF7E9F), Color(0xFFFFD873), Color(0xFF64D9F0)],
    bookColor: Color(0xFFF5F0EA),
    imageAsset: 'assets/images/shop_category_foreign.jpg',
  ),
  ShopCategory(
    label: 'Sách tham\nkhảo',
    colors: [Color(0xFFFF7E9F), Color(0xFFFFD873), Color(0xFF64D9F0)],
    bookColor: Color(0xFFF5F4EE),
    imageAsset: 'assets/images/shop_category_reference.jpg',
  ),
];

const shopStationeryCategories = [
  ShopCategory(
    label: 'Sổ tay các\nloại',
    colors: [Color(0xFF55E0D5), Color(0xFFF7F7F7), Color(0xFF1D2735)],
    bookColor: Color(0xFFF3E8D9),
  ),
  ShopCategory(
    label: 'Quà lưu\nniệm',
    colors: [Color(0xFF1E3726), Color(0xFF5C815A), Color(0xFFC3D5A9)],
    bookColor: Color(0xFF365C3D),
  ),
  ShopCategory(
    label: 'Thiết bị\ngiáo dục',
    colors: [Color(0xFFFFFFFF), Color(0xFFF6F6F6)],
    bookColor: Color(0xFFDDDDDD),
  ),
];

const shopSellers = [
  ShopSeller(
    name: 'San Hô\nBooks',
    logo: 'SAN HÔ\nBOOKS',
    colors: [Color(0xFFFFFFFF), Color(0xFFE8F3F6)],
  ),
  ShopSeller(
    name: 'Waka.vn',
    logo: 'WAKA',
    colors: [Color(0xFFFFFFFF), Color(0xFFFFFFFF)],
  ),
  ShopSeller(
    name: 'Tiệm sách\nSói',
    logo: 'SÓI',
    colors: [Color(0xFF101010), Color(0xFF353535)],
  ),
  ShopSeller(
    name: 'Ổ Nhỏ Của\nRita',
    logo: 'RITA',
    colors: [Color(0xFFFFE0E6), Color(0xFFFF8DA8)],
  ),
  ShopSeller(
    name: 'DinoBook',
    logo: 'DINO\nBOOK',
    colors: [Color(0xFFFFF3B0), Color(0xFF60C7A5)],
  ),
  ShopSeller(
    name: 'Alpha\nBooks',
    logo: 'ALPHA',
    colors: [Color(0xFFFFFFFF), Color(0xFFD9EBF7)],
  ),
  ShopSeller(
    name: 'Nhà sách\nBách Việt',
    logo: 'BÁCH\nVIỆT',
    colors: [Color(0xFFFFF5CF), Color(0xFFFFD67B)],
  ),
];

const topProducts = [
  ShopProduct(
    title: 'Sách - Lâu đài Xanh',
    price: '89.000đ',
    oldPrice: '120.000đ',
    discount: '-26%',
    sold: 'Đã bán 1424',
    rank: 1,
    colors: [Color(0xFF1C5581), Color(0xFF97C7DF)],
    imageAsset: 'assets/images/shop_category_literature.jpg',
    url: 'https://waka.vn/ebook/lau-dai-xanh-lucy-maud-montgomery-bZqKaW.html',
    type: 'Sách giấy',
  ),
  ShopProduct(
    title: 'Sách - Ba anh em nhà Rover và bí mật ở nông trại',
    price: '109.000đ',
    oldPrice: '128.000đ',
    discount: '-15%',
    sold: 'Đã bán 1276',
    rank: 2,
    colors: [Color(0xFF604520), Color(0xFFE9B65B)],
    imageAsset: 'assets/images/shop_category_children.png',
    url:
        'https://waka.vn/ebook/ba-anh-em-nha-rover-va-bi-mat-o-nong-trai-edward-stratemeyer-boMl6W.html',
    type: 'Sách điện tử',
  ),
  ShopProduct(
    title: 'Sách - Dám kiếm tiền, dám đầu tư',
    price: '99.000đ',
    oldPrice: '125.000đ',
    discount: '-21%',
    sold: 'Đã bán 1273',
    rank: 3,
    colors: [Color(0xFF081E37), Color(0xFFD5A530)],
    imageAsset: 'assets/images/shop_category_economics.jpg',
    url:
        'https://waka.vn/ebook/dam-kiem-tien-dam-dau-tu-marcus-phung-bnM2mW.html',
    type: 'Sách nói',
  ),
];

const suggestedProducts = [
  ShopProduct(
    title: 'Sách - Thành tích cao, thu nhập thấp',
    price: '79.000đ',
    oldPrice: '99.000đ',
    discount: '-20%',
    sold: 'Đã bán 986',
    rank: null,
    colors: [Color(0xFFF1A409), Color(0xFFFFC32A)],
    imageAsset: 'assets/images/shop_category_education.jpg',
    url:
        'https://waka.vn/ebook/thanh-tich-cao-thu-nhap-thap-hoang-nguyen-bA8W4W.html',
  ),
  ShopProduct(
    title: 'Sách - Nghệ thuật đàm phán với bất kỳ ai',
    price: '89.000đ',
    oldPrice: '119.000đ',
    discount: '-25%',
    sold: 'Đã bán 843',
    rank: null,
    colors: [Color(0xFF102B42), Color(0xFFFFBD42)],
    imageAsset: 'assets/images/shop_category_self_development.jpg',
    url:
        'https://waka.vn/ebook/nghe-thuat-dam-phan-voi-bat-ky-ai-sarah-an-b4314W.html',
  ),
  ShopProduct(
    title: 'Sách - Thần số học - Con số đọc vị con người',
    price: '109.000đ',
    oldPrice: '135.000đ',
    discount: '-19%',
    sold: 'Đã bán 715',
    rank: null,
    colors: [Color(0xFF17100A), Color(0xFFB98236)],
    imageAsset: 'assets/images/shop_category_knowledge.jpg',
    url:
        'https://waka.vn/ebook/than-so-hoc-con-so-doc-vi-con-nguoi-tri-nguyen-minh-bqM4mW.html',
  ),
  ShopProduct(
    title: 'Sách - Quy tắc giao tiếp quyền lực',
    price: '95.000đ',
    oldPrice: '119.000đ',
    discount: '-20%',
    sold: 'Đã bán 624',
    rank: null,
    colors: [Color(0xFF23354C), Color(0xFF84A4CD)],
    imageAsset: 'assets/images/shop_category_skills.jpg',
    url:
        'https://waka.vn/ebook/quy-tac-giao-tiep-quyen-luc-hoang-nguyen-bLZgvW.html',
  ),
  ShopProduct(
    title: 'Sách - Giấy dán tường vàng',
    price: '69.000đ',
    oldPrice: '89.000đ',
    discount: '-22%',
    sold: 'Đã bán 519',
    rank: null,
    colors: [Color(0xFF302A13), Color(0xFF9A7C24)],
    imageAsset: 'assets/images/shop_category_foreign.jpg',
    url:
        'https://waka.vn/ebook/giay-dan-tuong-vang-charlotte-perkins-gilman-bbMjpW.html',
  ),
  ShopProduct(
    title: 'Sách - Sáu cú sốc thay đổi lịch sử World Cup',
    price: '99.000đ',
    oldPrice: '129.000đ',
    discount: '-23%',
    sold: 'Đã bán 487',
    rank: null,
    colors: [Color(0xFF12263D), Color(0xFFC69222)],
    imageAsset: 'assets/images/shop_category_reference.jpg',
    url:
        'https://waka.vn/ebook/sau-cu-soc-thay-doi-lich-su-world-cup-aron-kim-bNnZ7W.html',
  ),
];
