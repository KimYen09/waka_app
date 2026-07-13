import 'package:flutter/material.dart';

abstract final class ShopLayout {
  static const double horizontalPadding = 12;
  static const double headerHeight = 96;
  static const double searchHeight = 44;
  static const double categoryAvatarSize = 88;
  static const double sellerAvatarSize = 86;
  static const double couponHeight = 130;
  static const double topProductWidth = 158;
  static const double topProductListHeight = 318;
  static const double topProductImageHeight = 165;
  static const double suggestedImageHeight = 210;
  static const double suggestedProductCardHeight = 370;
  static const double categoryScreenItemHeight = 178;
  static const double categoryScreenImageSize = 90;
}

abstract final class ShopFontSizes {
  static const double sectionTitle = 26;
  static const double categoryLabel = 18;
  static const double sellerLabel = 18;
  static const double productTitle = 21;
  static const double price = 22;
  static const double oldPrice = 16;
  static const double sold = 16;
  static const double categoryScreenLabel = 17.5;
}

abstract final class ShopAssets {
  static const String bookIllustration = 'assets/images/welcome_books.jpg';
}

class ShopCategory {
  const ShopCategory({
    required this.label,
    required this.colors,
    required this.bookColor,
  });

  final String label;
  final List<Color> colors;
  final Color bookColor;
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
    this.url = '',
  });

  final String title;
  final String price;
  final String oldPrice;
  final String discount;
  final String sold;
  final int? rank;
  final List<Color> colors;
  final String imageUrl;
  final String url;
}

const shopCategories = [
  ShopCategory(
    label: 'Sách Văn\nhọc',
    colors: [Color(0xFFFF7A9E), Color(0xFFFFD36B), Color(0xFF55D6F3)],
    bookColor: Color(0xFF7E4A2E),
  ),
  ShopCategory(
    label: 'Sách Giáo\nkhoa -\nGiáo Trình',
    colors: [Color(0xFFFF81A7), Color(0xFFFFD86A), Color(0xFF64DCEB)],
    bookColor: Color(0xFF247DB8),
  ),
  ShopCategory(
    label: 'Phát triển\nbản thân',
    colors: [Color(0xFFFF7BA1), Color(0xFFFFDD74), Color(0xFF5FE1E8)],
    bookColor: Color(0xFF17466F),
  ),
  ShopCategory(
    label: 'Sách Kinh\ntế',
    colors: [Color(0xFFFF7BA1), Color(0xFFFFDD74), Color(0xFF5FE1E8)],
    bookColor: Color(0xFF57C9C7),
  ),
  ShopCategory(
    label: 'Sách Thiếu\nnhi',
    colors: [Color(0xFFFF8FB2), Color(0xFFFFE071), Color(0xFF6DE6F4)],
    bookColor: Color(0xFFF4E4AB),
  ),
  ShopCategory(
    label: 'Sách Kiến\nthức tổng\nhợp',
    colors: [Color(0xFFFF7E9F), Color(0xFFFFD873), Color(0xFF64D9F0)],
    bookColor: Color(0xFF245D77),
  ),
  ShopCategory(
    label: 'Sách kỹ\nnăng',
    colors: [Color(0xFFFF7E9F), Color(0xFFFFD873), Color(0xFF64D9F0)],
    bookColor: Color(0xFFB88C65),
  ),
  ShopCategory(
    label: 'Sách ngoại\nvăn',
    colors: [Color(0xFFFF7E9F), Color(0xFFFFD873), Color(0xFF64D9F0)],
    bookColor: Color(0xFFF5F0EA),
  ),
  ShopCategory(
    label: 'Sách tham\nkhảo',
    colors: [Color(0xFFFF7E9F), Color(0xFFFFD873), Color(0xFF64D9F0)],
    bookColor: Color(0xFFF5F4EE),
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
    name: 'Nhà sách\nWaka',
    logo: 'WAKASHOP',
    colors: [Color(0xFFFFFFFF), Color(0xFFFFFFFF)],
  ),
  ShopSeller(
    name: 'Evebook\ns',
    logo: 'eve\nBOOKS',
    colors: [Color(0xFFFFFFFF), Color(0xFFFFFFFF)],
  ),
  ShopSeller(
    name: 'Etabooks',
    logo: 'ETA\nBOOKS',
    colors: [Color(0xFFD6CEC2), Color(0xFF6C6459)],
  ),
  ShopSeller(
    name: 'Akibooks\n_Official',
    logo: '',
    colors: [Color(0xFF41533E), Color(0xFFE6A7A6)],
  ),
  ShopSeller(
    name: 'Carobooks',
    logo: 'CARO\nBOOKS',
    colors: [Color(0xFFFFF5CF), Color(0xFFFFF5CF)],
  ),
];

const topProducts = [
  ShopProduct(
    title: 'Sách - Siêu cấm cùng chi',
    price: '139.000đ',
    oldPrice: '',
    discount: '-26%',
    sold: 'Đã bán 1424',
    rank: 1,
    colors: [Color(0xFF4B170E), Color(0xFFE8445B)],
  ),
  ShopProduct(
    title: 'Sách - Siêu cấm cùng chi',
    price: '424.000đ',
    oldPrice: '',
    discount: '-15%',
    sold: 'Đã bán 1276',
    rank: 2,
    colors: [Color(0xFF46180F), Color(0xFF3E7E3B)],
  ),
  ShopProduct(
    title: 'Sách - Cún nhỏ nói dối sẽ bị ăn thịt',
    price: '139.000đ',
    oldPrice: '',
    discount: '',
    sold: 'Đã bán 1273',
    rank: 3,
    colors: [Color(0xFFEAF7D1), Color(0xFFFAD845)],
  ),
];

const suggestedProducts = [
  ShopProduct(
    title: 'Sách - Combo Chuyện ma bên bà...',
    price: '228.000đ',
    oldPrice: '288.000đ',
    discount: '-21%',
    sold: '',
    rank: null,
    colors: [Color(0xFF0E2631), Color(0xFF244C5C)],
  ),
  ShopProduct(
    title: 'Sách - Chuyện ma bên bàn trà',
    price: '119.000đ',
    oldPrice: '149.000đ',
    discount: '-20%',
    sold: '',
    rank: null,
    colors: [Color(0xFFF9FAF5), Color(0xFF97B9C6)],
  ),
  ShopProduct(
    title: 'Sách - ÔNG XÃ, KẾT HÔN NÀO - ...',
    price: '165.000đ',
    oldPrice: '209.000đ',
    discount: '-21%',
    sold: 'Đã bán 2',
    rank: null,
    colors: [Color(0xFFFFF2D8), Color(0xFFFFD7B7)],
  ),
  ShopProduct(
    title: 'Sách - Điềm Dược • Viên Thuốc Ngọt...',
    price: '179.000đ',
    oldPrice: '196.000đ',
    discount: '-9%',
    sold: '',
    rank: null,
    colors: [Color(0xFFFFF5F7), Color(0xFFF3C8D8)],
  ),
];
