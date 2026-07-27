class CategoryItem {
  final String name;
  final bool isNew;

  const CategoryItem({
    required this.name,
    this.isNew = false,
  });
}

class CategoryBook {
  final String title;
  final String author;
  final String imageUrl;
  final int price;
  final int originalPrice;
  final bool isVip;

  const CategoryBook({
    required this.title,
    required this.author,
    required this.imageUrl,
    required this.price,
    required this.originalPrice,
    this.isVip = false,
  });
}

class SuggestedCollection {
  final String title;
  final String imageUrl;

  const SuggestedCollection({
    required this.title,
    required this.imageUrl,
  });
}

// Danh sách tabs chính
const List<String> parentCategories = ['Sách điện tử', 'Sách nói', 'Sách Hiệu sồi'];

// Danh sách thể loại con theo tab
const Map<String, List<CategoryItem>> subCategoriesData = {
  'Sách điện tử': [
    CategoryItem(name: 'Thơ - Tản văn'),
    CategoryItem(name: 'Trinh thám - Kinh dị', isNew: true),
    CategoryItem(name: 'Marketing - Bán hàng'),
    CategoryItem(name: 'Quản trị - Lãnh đạo'),
    CategoryItem(name: 'Tài chính cá nhân', isNew: true),
    CategoryItem(name: 'Phát triển cá nhân', isNew: true),
    CategoryItem(name: 'Doanh nhân - Bài học kinh doanh'),
    CategoryItem(name: 'Chữa lành'),
    CategoryItem(name: 'Học tập - Hướng nghiệp'),
    CategoryItem(name: 'Sức khỏe - Làm đẹp'),
    CategoryItem(name: 'Khoa học - Công nghệ'),
  ],
  'Sách nói': [
    CategoryItem(name: 'Kỹ năng làm việc'),
    CategoryItem(name: 'Phát triển bản thân'),
    CategoryItem(name: 'Kinh doanh - Đầu tư'),
    CategoryItem(name: 'Truyện audio', isNew: true),
    CategoryItem(name: 'Tâm lý - Giáo dục'),
    CategoryItem(name: 'Sức khỏe - Gia đình'),
    CategoryItem(name: 'Văn học - Nghệ thuật'),
    CategoryItem(name: 'Lịch sử - Văn hóa'),
  ],
  'Sách Hiệu sồi': [
    CategoryItem(name: 'Hiệu sồi độc quyền'),
    CategoryItem(name: 'Best-sellers Hiệu sồi', isNew: true),
    CategoryItem(name: 'Tinh hoa quản trị'),
    CategoryItem(name: 'Văn học Hiệu sồi'),
    CategoryItem(name: 'Đọc nhiều nhất'),
  ],
};

// Sách Flash Sale theo thể loại
const Map<String, List<CategoryBook>> flashSaleBooksData = {
  'Thơ - Tản văn': [
    CategoryBook(
      title: 'Việt Nam - Hồ Chí Minh',
      author: 'Roger Pic',
      price: 49000,
      originalPrice: 249000,
      imageUrl: 'https://307a0e78.vws.vegacdn.vn/view/v2/image/img.book/0/0/1/55930.jpg?v=1&w=350&h=510',
    ),
    CategoryBook(
      title: 'Bão ngầm',
      author: 'Đào Trung Hiếu',
      price: 79000,
      originalPrice: 149000,
      imageUrl: 'https://307a0e78.vws.vegacdn.vn/view/v2/image/img.book/0/0/1/55909.jpg?v=1&w=350&h=510',
    ),
    CategoryBook(
      title: 'Thoát nợ sống nhẹ',
      author: 'Marcus Phùng',
      price: 39000,
      originalPrice: 119000,
      imageUrl: 'https://307a0e78.vws.vegacdn.vn/view/v2/image/img.book/0/0/1/55930.jpg?v=1&w=350&h=510',
    ),
  ],
  'Trinh thám - Kinh dị': [
    CategoryBook(
      title: 'Mắt xích tử thần',
      author: 'Noah Phạm',
      price: 59000,
      originalPrice: 199000,
      imageUrl: 'https://307a0e78.vws.vegacdn.vn/view/v2/image/img.book/0/0/1/55882.jpg?v=1&w=350&h=510',
    ),
    CategoryBook(
      title: 'Bẫy lừa đảo',
      author: 'Noah Phạm',
      price: 49000,
      originalPrice: 159000,
      imageUrl: 'https://307a0e78.vws.vegacdn.vn/view/v2/image/img.book/0/0/1/55852.jpg?v=1&w=350&h=510',
    ),
  ],
};

// Tuyển tập gợi ý theo thể loại
const Map<String, List<SuggestedCollection>> suggestedCollectionsData = {
  'Thơ - Tản văn': [
    SuggestedCollection(
      title: 'Hà Nội - Một thời để nhớ',
      imageUrl: 'https://images.unsplash.com/photo-1509023464722-18d996393ca8?w=600',
    ),
  ],
  'Trinh thám - Kinh dị': [
    SuggestedCollection(
      title: 'Tuyển tập Truyện trinh thám - linh dị',
      imageUrl: 'https://images.unsplash.com/photo-1509248961158-e54f6934749c?w=600',
    ),
    SuggestedCollection(
      title: 'Top những vụ án phá án mới',
      imageUrl: 'https://images.unsplash.com/photo-1518020382113-a7e8fc38eac9?w=600',
    ),
  ],
};

// Tất cả sách theo thể loại
const Map<String, List<CategoryBook>> allBooksData = {
  'Thơ - Tản văn': [
    CategoryBook(
      title: 'Thấy nắng vàng trước gió',
      author: 'Minh Duy',
      price: 79000,
      originalPrice: 120000,
      imageUrl: 'https://307a0e78.vws.vegacdn.vn/view/v2/image/img.book/0/0/1/55909.jpg?v=1&w=350&h=510',
    ),
    CategoryBook(
      title: 'Qua xứ sở sương mù',
      author: 'Bình Gia Huy',
      price: 149000,
      originalPrice: 199000,
      imageUrl: 'https://307a0e78.vws.vegacdn.vn/view/v2/image/img.book/0/0/1/55897.jpg?v=1&w=350&h=510',
    ),
    CategoryBook(
      title: 'Tháng năm rực rỡ',
      author: 'Waka Studio',
      price: 0,
      originalPrice: 0,
      isVip: true,
      imageUrl: 'https://307a0e78.vws.vegacdn.vn/view/v2/image/img.book/0/0/1/55930.jpg?v=1&w=350&h=510',
    ),
    CategoryBook(
      title: 'Đi tìm phiên bản tốt hơn',
      author: 'Dương Cầm',
      price: 0,
      originalPrice: 0,
      isVip: true,
      imageUrl: 'https://307a0e78.vws.vegacdn.vn/view/v2/image/img.book/0/0/1/55855.jpg?v=1&w=350&h=510',
    ),
  ],
  'Trinh thám - Kinh dị': [
    CategoryBook(
      title: 'Tuyển tập tác phẩm của Edgar Allan Poe',
      author: 'Edgar Allan Poe',
      price: 0,
      originalPrice: 0,
      isVip: true,
      imageUrl: 'https://307a0e78.vws.vegacdn.vn/view/v2/image/img.book/0/0/1/55909.jpg?v=1&w=350&h=510',
    ),
    CategoryBook(
      title: 'Mười ngày phán xét',
      author: 'Hà Kiệt',
      price: 89000,
      originalPrice: 150000,
      imageUrl: 'https://307a0e78.vws.vegacdn.vn/view/v2/image/img.book/0/0/1/55882.jpg?v=1&w=350&h=510',
    ),
    CategoryBook(
      title: 'Trò chơi tử thần',
      author: 'Waka Studio',
      price: 0,
      originalPrice: 0,
      isVip: true,
      imageUrl: 'https://307a0e78.vws.vegacdn.vn/view/v2/image/img.book/0/0/1/55930.jpg?v=1&w=350&h=510',
    ),
  ],
};

// Hàm tiện ích để lấy sách Flash Sale dự phòng nếu không có sẵn thể loại
List<CategoryBook> getFlashSaleBooks(String categoryName) {
  if (flashSaleBooksData.containsKey(categoryName)) {
    return flashSaleBooksData[categoryName]!;
  }
  return flashSaleBooksData['Thơ - Tản văn']!;
}

// Hàm tiện ích để lấy Tuyển tập gợi ý dự phòng
List<SuggestedCollection> getSuggestedCollections(String categoryName) {
  if (suggestedCollectionsData.containsKey(categoryName)) {
    return suggestedCollectionsData[categoryName]!;
  }
  return suggestedCollectionsData['Thơ - Tản văn']!;
}

// Hàm tiện ích để lấy tất cả sách dự phòng
List<CategoryBook> getAllBooks(String categoryName) {
  if (allBooksData.containsKey(categoryName)) {
    return allBooksData[categoryName]!;
  }
  return allBooksData['Thơ - Tản văn']!;
}
