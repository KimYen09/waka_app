# Waka Demo REST API

Backend Express + MySQL cho ứng dụng Flutter Waka Demo. Flutter chỉ nhận JSON
từ backend; khi backend không khả dụng, ứng dụng tự chuyển sang
`assets/data/books.json`.

## Chạy local

Yêu cầu: Node.js 20+, npm và MySQL 8+. Có thể chạy MySQL bằng Docker:

```bash
docker compose up -d
cp .env.example .env
```

Nếu dùng cấu hình Docker phía trên, đặt `DB_PASSWORD=root` trong `.env`, sau đó:

```bash
npm install
npm run db:init
npm run dev
```

Kiểm tra tại `http://localhost:3000/health`.

## Endpoint

| Method | Endpoint | Chức năng | Xác thực |
| --- | --- | --- | --- |
| POST | `/api/auth/register` | Tạo tài khoản | Không |
| POST | `/api/auth/login` | Đăng nhập, nhận JWT | Không |
| GET | `/api/auth/me` | Thông tin tài khoản | Bearer JWT |
| GET | `/api/books` | Phân trang/tìm/lọc sách | Không |
| GET | `/api/books/:id` | Chi tiết sách | Không |
| GET | `/api/categories` | Danh mục | Không |
| GET | `/api/offers` | Ưu đãi đang hiệu lực | Không |
| GET | `/api/rankings` | Bảng xếp hạng theo kỳ và loại nội dung | Không |
| GET | `/api/recommendations` | Danh sách Waka đề xuất | Không |
| GET/POST | `/api/favorites` | Danh sách/thêm yêu thích | Bearer JWT |
| DELETE | `/api/favorites/:bookId` | Xóa yêu thích | Bearer JWT |
| GET/POST | `/api/orders` | Danh sách/tạo đơn hàng | Bearer JWT |

Ví dụ lọc sách:

```text
GET /api/books?page=1&limit=20&search=đầu tư&categoryId=2
GET /api/rankings?period=week&contentType=ebook&limit=20
GET /api/recommendations?contentType=ebook&limit=20
```

## Cấu hình Flutter

Android Emulator dùng mặc định `http://10.0.2.2:3000/api`.

iOS Simulator hoặc desktop:

```bash
flutter run --dart-define=API_BASE_URL=http://127.0.0.1:3000/api
```

Thiết bị thật dùng IP LAN của máy chạy backend:

```bash
flutter run --dart-define=API_BASE_URL=http://192.168.1.10:3000/api
```

HTTP chỉ được bật cho Android debug build. Bản release cần triển khai backend qua
HTTPS và truyền URL HTTPS bằng `--dart-define`.
