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
    this.backendBookId = 0,
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
  final int backendBookId;
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
    title: 'Giữa chốn phồn hoa gặp được người - Tập 2',
    price: '89.000đ',
    oldPrice: '110.000đ',
    discount: '-19%',
    sold: 'Cửu Nguyệt Hi',
    rank: null,
    colors: [Color(0xFF2B3A4A), Color(0xFF6B8CAE)],
    imageAsset: 'https://307a0e78.vws.vegacdn.vn/view/v2/image/img.book/0/0/1/33467.jpg?v=1&w=480&h=700',
    url: 'https://waka.vn/ebook/giua-chon-phon-hoa-gap-duoc-nguoi-tap-2.html',
    type: 'Tác phẩm kinh điển',
  ),
  ShopProduct(
    title: 'Làm đĩ',
    price: '79.000đ',
    oldPrice: '99.000đ',
    discount: '-20%',
    sold: 'Vũ Trọng Phụng',
    rank: null,
    colors: [Color(0xFF4A2B18), Color(0xFFC88A4C)],
    imageAsset: 'https://down-vn.img.susercontent.com/file/c98e25971a7301c8248a2506f33d293b',
    url: 'https://waka.vn/ebook/lam-di-vu-trong-phung.html',
    type: 'Tác phẩm kinh điển',
  ),
  ShopProduct(
    title: 'Bên nhau trọn đời',
    price: '99.000đ',
    oldPrice: '120.000đ',
    discount: '-17%',
    sold: 'Cố Mạn',
    rank: null,
    colors: [Color(0xFF3B1E37), Color(0xFF9E5A93)],
    imageAsset: 'https://307a0e78.vws.vegacdn.vn/view/v2/image/img.book/0/0/0/16736.jpg?v=1&w=480&h=700',
    url: 'https://waka.vn/ebook/ben-nhau-tron-doi-co-man.html',
    type: 'Tiểu thuyết',
  ),
  ShopProduct(
    title: 'CM-12 Phía sau kế hoạch phản gián',
    price: '119.000đ',
    oldPrice: '150.000đ',
    discount: '-20%',
    sold: 'Nguyễn Khắc Đức',
    rank: null,
    colors: [Color(0xFF1B3B2B), Color(0xFF47A36F)],
    imageAsset: 'https://cdn1.fahasa.com/media/catalog/product/z/7/z7559362432815_58b7db0644c7ffc7e9378ada6274a2f4_2_1.jpg',
    url: 'https://waka.vn/ebook/cm-12-phia-sau-ke-hoach-phan-gian.html',
    type: 'Chính trị',
  ),
  ShopProduct(
    title: '[Tóm tắt sách] 1000 câu hỏi về tình dục dành cho các cặp đôi',
    price: '69.000đ',
    oldPrice: '89.000đ',
    discount: '-22%',
    sold: 'Trần Nhật Dương',
    rank: null,
    colors: [Color(0xFF6B1A1A), Color(0xFFD34747)],
    imageAsset: 'https://307a0e78.vws.vegacdn.vn/view/v2/image/img.book/0/0/1/47101.jpg?v=7&w=480&h=700',
    url: 'https://waka.vn/ebook/1000-cau-hoi-ve-tinh-duc.html',
    type: 'Y học & Đời sống',
  ),
  ShopProduct(
    title: 'Bộ Khoa học và Công nghệ kế thừa lịch sử, hướng tới tương lai',
    price: '139.000đ',
    oldPrice: '180.000đ',
    discount: '-22%',
    sold: 'Bộ Khoa học và Công nghệ',
    rank: null,
    colors: [Color(0xFF8B1515), Color(0xFFE54D4D)],
    imageAsset: 'https://vista.gov.vn/vn-uploads/science-technology/2024_08/bia-sach-trang-2023.png',
    url: 'https://waka.vn/ebook/bo-khoa-hoc-va-cong-nghe.html',
    type: 'Khoa học',
  ),
  ShopProduct(
    title: 'Di chúc của Chủ tịch Hồ Chí Minh',
    price: '59.000đ',
    oldPrice: '75.000đ',
    discount: '-21%',
    sold: 'Hồ Chí Minh',
    rank: null,
    colors: [Color(0xFF5A3E1E), Color(0xFFC49A5A)],
    imageAsset: 'https://www.nxbtre.com.vn/Images/Read/nxbtre_di-chuc-cua-chu-tich-ho-chi-minh-19-5-1890-02-9-1969.pdf_page-1.png',
    url: 'https://waka.vn/ebook/di-chuc-chu-tich-ho-chi-minh.html',
    type: 'Lịch sử & Chính trị',
  ),
  ShopProduct(
    title: 'Tôi đi học',
    price: '75.000đ',
    oldPrice: '95.000đ',
    discount: '-21%',
    sold: 'Nguyễn Ngọc Ký',
    rank: null,
    colors: [Color(0xFF1E4035), Color(0xFF4BA388)],
    imageAsset: 'https://firstnews.vn/upload/products/original/-1729482421.jpg',
    url: 'https://waka.vn/ebook/toi-di-hoc-nguyen-ngoc-ky.html',
    type: 'Hồi ký',
  ),
  ShopProduct(
    title: 'Tóm lược Chuyển đổi số - Chiến lược & Lộ trình',
    price: '109.000đ',
    oldPrice: '139.000đ',
    discount: '-21%',
    sold: 'David L. Rogers',
    rank: null,
    colors: [Color(0xFF0F3B40), Color(0xFF2CA5B0)],
    imageAsset: 'https://images.unsplash.com/photo-1518621736915-f3b1c41bfd00?w=500',
    url: 'https://waka.vn/ebook/tom-luoc-chuyen-doi-so.html',
    type: 'Kinh tế',
  ),
  ShopProduct(
    title: 'Khi ta thay đổi thế giới sẽ đổi thay',
    price: '89.000đ',
    oldPrice: '115.000đ',
    discount: '-22%',
    sold: 'Karen Casey',
    rank: null,
    colors: [Color(0xFF2C3E50), Color(0xFFE74C3C)],
    imageAsset: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=500',
    url: 'https://waka.vn/ebook/khi-ta-thay-doi-the-gioi-se-doi-thay.html',
    type: 'Tâm lý & Kỹ năng',
  ),
  ShopProduct(
    title: 'Cách nghĩ để thành công',
    price: '99.000đ',
    oldPrice: '130.000đ',
    discount: '-23%',
    sold: 'Napoleon Hill',
    rank: null,
    colors: [Color(0xFF1B2A47), Color(0xFF4A74C4)],
    imageAsset: 'https://images.unsplash.com/photo-1516589178581-6cd7833ae3b2?w=500',
    url: 'https://waka.vn/ebook/cach-nghi-de-thanh-cong.html',
    type: 'Tư duy phát triển',
  ),
  ShopProduct(
    title: 'Bắt sóng cảm xúc',
    price: '85.000đ',
    oldPrice: '105.000đ',
    discount: '-19%',
    sold: 'Bí mật lực hấp dẫn',
    rank: null,
    colors: [Color(0xFF1A3B69), Color(0xFF388AE6)],
    imageAsset: 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=500',
    url: 'https://waka.vn/ebook/bat-song-cam-xuc.html',
    type: 'Kỹ năng sống',
  ),
];
