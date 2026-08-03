# 📚 Library Audio Feature

## Tổng quan

Thư viện đã được nâng cấp với chức năng nghe sách nói tương tự ứng dụng nghe nhạc. Mỗi cuốn sách nói có thể được bấm để mở giao diện phát nhạc với đầy đủ tính năng điều khiển.

## 🎵 Cách sử dụng

### Phát nhạc sách nói
1. Tại thư viện, bấm vào bất kỳ cuốn sách nói nào (có biểu tượng play xanh)
2. Giao diện phát nhạc sẽ mở với:
   - Hình ảnh sách dạng album art
   - Thanh tiến độ với thời gian hiện tại/tổng cộng
   - Các nút điều khiển: back 10s, forward 30s, play/pause, skip
   - Tốc độ phát (0.75x - 2.0x)

### Quản lý âm thanh
Phần "Quản lý âm thanh" cho phép:
- **Tải lên**: Thêm file âm thanh mới cho cuốn sách
- **Chỉnh sửa**: Cập nhật thông tin hoặc cat file âm thanh
- **Xóa**: Xóa file âm thanh hiện tại

## 📁 Cấu trúc thư mục

```
lib/features/library/
├── library_screen.dart           # Màn hình chính thư viện
├── models/
│   └── book_audio_model.dart    # Model dữ liệu âm thanh sách
└── widgets/
    └── audio_player_bottom_sheet.dart  # Giao diện phát nhạc
```

## 🎨 Thiết kế

### Màu sắc (theo theme Waka)
- **Accent**: `#20D5A2` - Màu xanh lá cho nút play chính
- **Surface**: `#1B1B1D` - Nền cho các nút điều khiển
- **Background**: `#0E0F0F` - Nền chính
- **Text**: `#F8F8F8` - Chữ sáng

### Thành phần UI
- **Album Art**: Hình tròn 280x280 với shadow xanh
- **Play Button**: Nút tròn 70x70 ở giữa, màu accent
- **Control Buttons**: Nút tròn 52x52 với icon xanh
- **Progress Bar**: Thanh slider tùy chỉnh màu accent

## 📊 Dữ liệu sách

Mỗi cuốn sách bây giờ chứa:

```dart
_LibraryBook(
  title: 'Tên sách',
  color: Color(0xFF...),        // Màu fallback nếu không có hình
  mediaType: _MediaType.audio,  // Hoặc .ebook
  imageUrl: 'https://...',      // Hình sách
  narrator: 'Tên diễn viên',     // Mới
  duration: Duration(...),       // Độ dài sách nói
)
```

## 🔧 Mở rộng

### Thêm tính năng mới
1. **Lưu vị trí phát**: Thêm `currentPosition` vào database
2. **Playlist**: Thêm queue cho nhiều sách
3. **Tải xuống offline**: Tích hợp `just_audio` package
4. **Bookmark**: Đánh dấu các đoạn yêu thích

### Cấu hình backend
Cần API endpoint để:
- Upload/delete audio files
- Lưu metadata sách nói
- Sync vị trí phát giữa các thiết bị

```javascript
// Ví dụ backend route
POST /api/books/:bookId/audio
GET /api/books/:bookId/audio
DELETE /api/books/:bookId/audio
```

## 🐛 Debugging

### Nếu play button không hoạt động:
1. Kiểm tra `mediaType == _MediaType.audio`
2. Đảm bảo `BookAudio` được convert đúng
3. Check console log ở `_AudioPlayerBottomSheetState`

### Nếu duration hiển thị sai:
- Đảm bảo `Duration` được khởi tạo với đơn vị đúng
- Ví dụ: `Duration(hours: 2, minutes: 30)` = 2h30m
