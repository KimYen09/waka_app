# Hướng dẫn sử dụng và vận hành dự án Waka Demo

Tài liệu này dành cho cả người dùng thử ứng dụng, thành viên phát triển và
người chấm/triển khai đồ án. Nội dung mô tả trạng thái hiện tại của repository:

> Phiên bản trình bày theo mẫu báo cáo, chia từng bước và in đậm nội dung:
> [HUONG_DAN_SU_DUNG_BAO_CAO.md](HUONG_DAN_SU_DUNG_BAO_CAO.md).

- Ứng dụng Flutter chạy trên Android, iOS, macOS và web.
- REST API viết bằng Node.js + Express.
- Dữ liệu nghiệp vụ lưu trong MySQL 8.4.
- Docker Compose hiện chỉ chạy MySQL; Express chạy trực tiếp bằng Node.js.
- Thanh toán VNPay đang dùng môi trường sandbox.

> Các lệnh trong tài liệu được chạy từ thư mục gốc `waka_app`, trừ khi phần
> hướng dẫn ghi rõ cần chuyển vào `backend`.

## 1. Tổng quan kiến trúc

```text
Flutter
  │
  │ HTTP + JSON, Bearer JWT
  ▼
Node.js / Express tại cổng 3000
  │
  │ SQL qua mysql2 connection pool
  ▼
MySQL 8.4 tại cổng 3306
```

Các dịch vụ bên ngoài có thể được sử dụng:

- Google Sign-In và Facebook Login.
- Gemini API cho Trợ lý AI.
- VNPay Sandbox cho thanh toán.
- Province Open API cho tỉnh, huyện và xã.
- CDN Waka và một số nguồn ảnh HTTPS.

Khi API danh sách sách không hoạt động, ứng dụng có dữ liệu dự phòng trong
`assets/data/books.json`. Dữ liệu dự phòng chỉ giúp giao diện tiếp tục hiển
thị; các chức năng tài khoản, giỏ hàng, đơn hàng và quản trị vẫn cần backend.

## 2. Yêu cầu môi trường

| Thành phần | Yêu cầu | Lệnh kiểm tra |
| --- | --- | --- |
| Flutter | SDK tương thích Dart `^3.12.0-327.4.beta` | `flutter --version` |
| Node.js | 20 trở lên | `node --version` |
| npm | Đi kèm Node.js | `npm --version` |
| Docker Desktop | Dùng để chạy MySQL | `docker version` |
| Android Studio | Android SDK và AVD | `flutter devices` |
| Git | Quản lý mã nguồn | `git --version` |

Kiểm tra môi trường Flutter:

```bash
flutter doctor -v
```

Không nên bắt đầu sửa lỗi ứng dụng khi `flutter doctor` vẫn báo thiếu Android
SDK, license hoặc thiết bị.

## 3. Cài đặt lần đầu

### 3.1. Lấy mã nguồn và dependency Flutter

```bash
git clone <URL_REPOSITORY>
cd waka_app
flutter pub get
```

### 3.2. Tạo cấu hình backend

```bash
cd backend
cp .env.example .env
```

Cấu hình tối thiểu để chạy local:

```env
PORT=3000
DB_HOST=127.0.0.1
DB_PORT=3306
DB_USER=root
DB_PASSWORD=root
DB_NAME=waka_demo
DB_TIMEZONE=Z
JWT_SECRET=thay-bang-mot-chuoi-ngau-nhien-dai
JWT_EXPIRES_IN=7d
CORS_ORIGIN=*
```

Không commit `backend/.env`. File này có thể chứa mật khẩu database, JWT
secret, khóa Gemini và bí mật merchant VNPay.

### 3.3. Khởi động MySQL bằng Docker

```bash
cd backend
docker compose up -d
docker compose ps
```

Kết quả đúng phải có container `backend-mysql-1` ở trạng thái `healthy`.
Compose sử dụng named volume `waka_mysql_data`, vì vậy recreate container không
xóa database trừ khi chủ động xóa volume.

### 3.4. Cài dependency và khởi tạo database

```bash
cd backend
npm ci
npm run db:init
```

`npm ci` cài đúng phiên bản trong `package-lock.json`. `npm run db:init` tạo
hoặc cập nhật schema và nạp dữ liệu sách, bảng xếp hạng, gợi ý và gói hội viên.
Lệnh init được thiết kế để có thể chạy lại sau khi pull code có schema mới.

### 3.5. Chạy REST API

```bash
cd backend
npm run dev
```

Giữ terminal này mở. Dòng sau cho biết API đã sẵn sàng:

```text
Waka API listening on http://localhost:3000
```

Kiểm tra:

```bash
curl http://127.0.0.1:3000/health
curl "http://127.0.0.1:3000/api/books?page=1&limit=1"
```

### 3.6. Chạy Flutter

Mở terminal khác tại thư mục gốc:

```bash
flutter devices
flutter run -d emulator-5554
```

Nếu ID emulator khác, dùng ID do `flutter devices` trả về.

## 4. Địa chỉ API theo thiết bị

Flutter lấy base URL từ `API_BASE_URL`. Nếu không truyền biến này, ứng dụng tự
chọn địa chỉ phù hợp với Android Emulator chính thức.

### Android Emulator của Android Studio

```text
http://10.0.2.2:3000/api
```

`10.0.2.2` đại diện cho máy host từ bên trong Android Emulator.

```bash
flutter run -d emulator-5554
```

### iOS Simulator, macOS hoặc web

```bash
flutter run -d macos \
  --dart-define=API_BASE_URL=http://127.0.0.1:3000/api
```

### Điện thoại Android thật

Điện thoại và máy chạy backend phải cùng mạng. Thay IP ví dụ bằng IP LAN của
máy:

```bash
flutter run -d <DEVICE_ID> \
  --dart-define=API_BASE_URL=http://192.168.1.10:3000/api
```

Nếu backend production dùng HTTPS:

```bash
flutter run --release \
  --dart-define=API_BASE_URL=https://api.example.com/api
```

## 5. Quy trình chạy hằng ngày

Mỗi lần mở máy, thực hiện theo thứ tự:

Terminal 1:

```bash
cd backend
docker compose up -d
docker compose ps
npm run dev
```

Terminal 2:

```bash
flutter pub get
flutter run -d emulator-5554
```

Khi chỉ thay đổi Dart UI, dùng Hot Reload. Khi thay đổi khởi tạo session, plugin,
native Android, dependency hoặc cấu hình global, dùng Hot Restart hoặc chạy lại
ứng dụng.

## 6. Hướng dẫn sử dụng ứng dụng

### 6.1. Đăng ký và đăng nhập

1. Mở ứng dụng và chọn đăng nhập/đăng ký.
2. Nhập email hoặc số điện thoại và mật khẩu.
3. Backend băm mật khẩu bằng bcrypt trước khi lưu.
4. Đăng nhập thành công trả về JWT.
5. Session và token được lưu trong Secure Storage để khôi phục sau khi mở lại
   ứng dụng.

Người dùng cũng có thể đăng nhập Google/Facebook nếu môi trường đã cấu hình.
Khi chưa cấu hình OAuth, nên sử dụng tài khoản mật khẩu để kiểm thử.

### 6.2. Trang chủ

Trang chủ hiển thị các nhóm sách, sách hội viên, đề xuất và chương trình quảng
bá. Dữ liệu ưu tiên từ REST API. Nếu backend tắt, một số khu vực chuyển sang
dữ liệu local/fallback.

Chọn một sách để mở chi tiết. Ảnh bìa được tải qua HTTPS; khi CDN lỗi hoặc URL
rỗng, ứng dụng hiển thị bìa được sinh tự động.

### 6.3. Waka Shop và giỏ hàng

1. Mở tab **Waka Shop**.
2. Chọn danh mục hoặc tìm sản phẩm.
3. Mở chi tiết sách.
4. Thêm sách vào giỏ.
5. Thay đổi số lượng hoặc xóa sản phẩm trong giỏ.
6. Chọn **Mua hàng** để sang checkout.

Giỏ hàng được đồng bộ với backend theo tài khoản. Tổng tiền được backend tính
lại; không tin hoàn toàn số tiền do client gửi lên.

### 6.4. Địa chỉ nhận hàng

Ở checkout:

1. Chọn **Thêm địa chỉ** hoặc **Thay đổi**.
2. Nhập người nhận và số điện thoại.
3. Chọn tỉnh/thành, quận/huyện, phường/xã.
4. Nhập số nhà và tên đường.
5. Chọn loại địa chỉ.
6. Lưu địa chỉ.

Địa chỉ được lưu theo ID tài khoản trong Secure Storage. Mục **Cá nhân → Địa
chỉ** ưu tiên đọc địa chỉ local; nếu chưa tìm thấy, ứng dụng khôi phục địa chỉ
từ đơn hàng gần nhất của chính tài khoản.

### 6.5. Voucher

Checkout hỗ trợ các voucher demo do backend kiểm tra. Nếu mã không tồn tại hoặc
đơn chưa đạt giá trị tối thiểu, API từ chối checkout. Không sửa tổng tiền trực
tiếp ở Flutter để giả lập voucher vì backend sẽ tính lại.

### 6.6. Đặt hàng COD

1. Chọn **Thanh toán khi nhận hàng**.
2. Kiểm tra địa chỉ và sản phẩm.
3. Xác nhận đặt hàng.
4. Đơn mới thường ở trạng thái `confirmed`.
5. Trong Profile, đơn thuộc nhóm **Chờ lấy hàng**.

Mỗi lần chọn tab **Cá nhân**, ứng dụng gọi lại `/api/orders` để cập nhật badge.
Có thể kéo xuống để refresh thủ công.

### 6.7. Thanh toán VNPay Sandbox

1. Chọn VNPay tại checkout.
2. Backend tạo đơn `payment_review` và payment `pending`.
3. App mở `paymentUrl` trong WebView.
4. Người dùng thanh toán trên VNPay Sandbox.
5. VNPay chuyển WebView về endpoint return.
6. VNPay gọi IPN server-to-server.
7. Backend xác thực chữ ký IPN và chuyển payment sang `paid` hoặc `failed`.
8. App tải lại trạng thái đơn.

Return URL chỉ dùng để hiển thị kết quả. IPN mới là nguồn xác nhận chính thức.

### 6.8. Thư viện

Các tab chính:

- **Đã mua**: tổng hợp sách từ `GET /api/orders`.
- **Yêu thích**: từ `GET /api/favorites`.
- **Tải xuống**: từ `GET /api/downloads`.
- **Tiếp tục**: từ `GET /api/progress`.

Ảnh sách đã mua được trả trong `items[].imageUrl` của API orders. Nếu vừa cập
nhật code backend/model, cần Hot Restart để Flutter dùng model mới.

### 6.9. Đọc sách và tiến độ

Khi người dùng chuyển trang, app gửi tiến độ lên `/api/progress`. Một người dùng
chỉ có một dòng tiến độ cho mỗi sách; lần ghi mới cập nhật `current_page`.

### 6.10. Đánh giá sách

Người dùng đăng nhập có thể gửi rating và bình luận. Mỗi tài khoản có một đánh
giá cho mỗi sách; gửi lại sẽ cập nhật đánh giá hiện có. Admin có thể khóa đánh
giá vi phạm.

### 6.11. Gói hội viên

1. Mở **Gói cước**.
2. Chọn gói đang hoạt động.
3. Chọn phương thức thanh toán.
4. Sau khi xác nhận thành công, membership chuyển sang `active`.
5. Người dùng có thể xem lịch sử hoặc hủy gói.

### 6.12. Trợ lý AI

Nút **Trợ lý AI** gửi câu hỏi đến `POST /api/ai/chat`. Backend gọi Gemini bằng
`GEMINI_API_KEY`. Nếu khóa chưa được cấu hình, backend trả thông báo cấu hình
thay vì câu trả lời AI.

## 7. Trang quản trị

Tài khoản có `role = 'admin'` và `account_status = 'active'` được chuyển đến
Admin Dashboard sau đăng nhập.

Admin có thể:

- Xem số liệu dashboard.
- Tạo, sửa, duyệt và khóa sách.
- Duyệt đơn đăng ký tác giả.
- Quản lý tác giả và người dùng.
- Xem đơn hàng và thay đổi trạng thái vận chuyển.
- Thêm shipping event.
- Quản lý payment.
- Khóa/mở đánh giá.

Cấu hình danh sách định danh admin trong `.env`:

```env
ADMIN_IDENTIFIERS=admin@example.com,admin2@example.com
```

Chạy lại `npm run db:init` hoặc quy trình tạo tài khoản phù hợp sau khi thay đổi
cấu hình, rồi khởi động lại backend.

## 8. Vòng đời trạng thái đơn hàng

```text
payment_review
      │ thanh toán được xác nhận
      ▼
confirmed → packing → in_transit → at_hub → out_for_delivery → delivered
      └────────────────────────────────────────────────────────→ cancelled
```

Nhóm badge phía người dùng:

| Badge | Trạng thái được đếm |
| --- | --- |
| Chờ xác nhận | `payment_review` |
| Chờ lấy hàng | `confirmed`, `packing` |
| Đang giao hàng | `in_transit`, `at_hub`, `out_for_delivery` |

`delivered` và `cancelled` vẫn nằm trong lịch sử chi tiết nhưng không hiện ở ba
badge đang xử lý.

## 9. Các endpoint REST quan trọng

Base URL local: `http://127.0.0.1:3000/api`.

### Xác thực

```text
POST /auth/register
POST /auth/login
POST /auth/guest
POST /auth/social/google
POST /auth/social/facebook
GET  /auth/me
POST /auth/change-password
```

### Catalog và người dùng

```text
GET    /books
GET    /books/:id
GET    /books/:bookId/reviews
POST   /books/:bookId/reviews
GET    /categories
GET    /offers
GET    /rankings
GET    /recommendations
GET    /favorites
POST   /favorites
DELETE /favorites/:bookId
GET    /downloads
POST   /downloads
GET    /progress
POST   /progress
```

### Thương mại

```text
GET    /cart
POST   /cart/items
DELETE /cart/items/:bookId
POST   /checkout
GET    /orders
GET    /membership-plans
GET    /memberships/me
POST   /memberships/purchase
DELETE /memberships/me
GET    /payments
GET    /notifications
PATCH  /notifications/:id/read
```

Endpoint cần xác thực nhận header:

```http
Authorization: Bearer <JWT>
```

## 10. Cấu hình tính năng tùy chọn

### Gemini

```env
GEMINI_API_KEY=your-api-key
```

Khởi động lại `npm run dev` sau khi sửa `.env`.

### Google Sign-In

Backend:

```env
GOOGLE_CLIENT_ID=your-web-client-id.apps.googleusercontent.com
```

Android cần `android/app/google-services.json`, package
`com.example.waka_demo`, SHA-1 đúng và Web client ID:

```bash
flutter run \
  --dart-define=GOOGLE_SERVER_CLIENT_ID=your-web-client-id.apps.googleusercontent.com
```

### Facebook Login

Backend:

```env
FACEBOOK_APP_ID=your-app-id
FACEBOOK_APP_SECRET=your-app-secret
```

Android local `android/gradle.properties`:

```properties
FACEBOOK_APP_ID=your-app-id
FACEBOOK_CLIENT_TOKEN=your-client-token
```

Không đưa Facebook App Secret vào Flutter.

### VNPay Sandbox

```env
VNP_TMN_CODE=your-tmn-code
VNP_HASH_SECRET=your-hash-secret
VNP_URL=https://sandbox.vnpayment.vn/paymentv2/vpcpay.html
VNP_RETURN_URL=https://your-public-host/api/payments/vnpay/return
```

Backend local phải được expose bằng tunnel HTTPS. Cấu hình IPN trên merchant
portal:

```text
https://your-public-host/api/payments/vnpay/ipn
```

Khi tunnel đổi URL, cập nhật cả `VNP_RETURN_URL` và IPN URL.

## 11. Database

Schema nằm tại `backend/database/schema.sql`. Các nhóm bảng chính:

- Tài khoản: `users`, `social_accounts`.
- Catalog: `categories`, `authors`, `books`, `offers`.
- Khám phá: `rankings`, `recommendations`.
- Nội dung người dùng: `favorites`, `downloads`, `reading_progress`,
  `book_reviews`.
- Thương mại: `cart_items`, `orders`, `order_items`, `shipping_events`,
  `payments`.
- Hội viên: `membership_plans`, `user_memberships`.
- Quản trị/tương tác: `author_applications`, `notifications`.

### Backup database

```bash
docker exec backend-mysql-1 \
  mysqldump -uroot -proot waka_demo > waka_demo_backup.sql
```

File backup có thể chứa dữ liệu người dùng; không commit lên Git.

### Restore database

```bash
docker exec -i backend-mysql-1 \
  mysql -uroot -proot waka_demo < waka_demo_backup.sql
```

### Recreate container nhưng giữ dữ liệu

```bash
cd backend
docker compose down
docker compose up -d --build --force-recreate
npm run db:init
```

Không thêm `-v` vào `docker compose down` nếu muốn giữ volume.

### Xóa toàn bộ database local

Thao tác này phá hủy dữ liệu và chỉ dùng khi chắc chắn:

```bash
cd backend
docker compose down -v
docker compose up -d
npm run db:init
```

## 12. Kiểm thử và kiểm tra chất lượng

```bash
flutter analyze
flutter test
```

Chạy một nhóm test:

```bash
flutter test test/vnpay_return_url_test.dart
flutter test test/widget_test.dart --plain-name "cart sync"
```

Backend hiện dùng Node test runner:

```bash
cd backend
npm test
```

Ảnh golden nằm trong `test/goldens`. Khi golden fail, kiểm tra ảnh ở
`test/failures`; không cập nhật golden chỉ để làm test xanh nếu giao diện thực
sự đang sai.

## 13. Quy trình Git an toàn

Trước khi pull:

```bash
git status
git add <cac-file-can-luu>
git commit -m "Mo ta thay doi"
git pull --rebase origin main
```

Sau khi resolve conflict:

```bash
flutter analyze
flutter test
git push origin main
```

Không dùng `git reset --hard` khi còn thay đổi chưa commit. Có thể tạo nhánh
backup trước thao tác lớn:

```bash
git branch backup/truc-khi-dong-bo
```

## 14. Xử lý lỗi thường gặp

### Flutter báo không thể kết nối API

Kiểm tra lần lượt:

```bash
docker compose -f backend/docker-compose.yml ps
curl http://127.0.0.1:3000/health
flutter devices
```

- MySQL phải healthy.
- `npm run dev` phải đang chạy.
- Android Emulator dùng `10.0.2.2`, không dùng `127.0.0.1` để gọi host.
- Điện thoại thật dùng IP LAN.

### `Cannot find module '@google/genai'`

```bash
cd backend
npm ci
```

### `connect ECONNREFUSED 127.0.0.1:3306`

MySQL chưa chạy hoặc chưa healthy:

```bash
cd backend
docker compose up -d
docker compose ps
```

### Ảnh bìa chỉ hiện placeholder

1. Kiểm tra API có trả `imageUrl` không.
2. Kiểm tra URL trên trình duyệt.
3. Kiểm tra DNS emulator:

```bash
adb shell ping -c 1 8.8.8.8
adb shell ping -c 1 307a0e78.vws.vegacdn.vn
```

Nếu ping IP được nhưng tên miền không được, restart emulator với DNS:

```bash
emulator -avd Medium_Phone_API_35 \
  -dns-server 8.8.8.8,1.1.1.1
```

### Emulator báo `device not found`

```bash
adb kill-server
adb start-server
adb devices -l
```

Nếu emulator crash, kiểm tra dung lượng ổ đĩa. Nên còn tối thiểu 10–15 GB.

### Địa chỉ không xuất hiện trong Profile

- Hot Restart để nhận code mới.
- Đăng nhập đúng tài khoản đã đặt đơn.
- Mở **Cá nhân → Địa chỉ**.
- Profile sẽ đọc Secure Storage; nếu không có, nó lấy đơn hàng gần nhất.

### Badge đơn hàng không tăng

Chọn lại tab **Cá nhân** hoặc kéo xuống refresh. Badge chỉ đếm đơn đang xử lý,
không đếm `delivered` và `cancelled`.

### VNPay trả về nhưng đơn vẫn pending

- Kiểm tra IPN URL đã khai trên VNPay Sandbox.
- Kiểm tra tunnel còn hoạt động.
- Kiểm tra `VNP_HASH_SECRET`.
- Đảm bảo IPN trả `RspCode: "00"`.

## 15. Checklist trước khi demo

1. Docker Desktop đang chạy.
2. MySQL container healthy.
3. `npm run db:init` đã chạy sau lần pull gần nhất.
4. `npm run dev` đang lắng nghe cổng 3000.
5. `/health` trả `status: ok`.
6. Emulator có Internet và DNS hoạt động.
7. Flutter dùng đúng `API_BASE_URL`.
8. Đăng nhập đúng tài khoản cần demo.
9. VNPay/Gemini/OAuth được cấu hình nếu sẽ trình diễn.
10. `flutter analyze` không có lỗi.

## 16. Checklist trước production

Phiên bản hiện tại phù hợp demo/MVP. Trước production cần:

- Triển khai API qua HTTPS.
- Thay package ID `com.example.waka_demo` bằng ID chính thức.
- Tạo release signing key riêng; không dùng debug signing.
- Không dùng JWT secret mặc định.
- Giới hạn CORS thay vì `*`.
- Không fallback request protected sang guest khi token sai/hết hạn.
- Thêm rate limiting, validation và audit log.
- Dùng migration framework có version.
- Tăng coverage test backend và integration test.
- Dùng secret manager cho production.
- Chuyển VNPay từ sandbox sang merchant production sau khi được duyệt.
- Thiết lập backup MySQL định kỳ và giám sát uptime.

## 17. Lệnh nhanh

```bash
# Khởi động database
cd backend && docker compose up -d

# Cập nhật schema
cd backend && npm run db:init

# Chạy API
cd backend && npm run dev

# Chạy Android Emulator
flutter run -d emulator-5554

# Kiểm tra code
flutter analyze
flutter test

# Kiểm tra API
curl http://127.0.0.1:3000/health

# Xem thiết bị
flutter devices
adb devices -l
```

## 18. Tài liệu liên quan

- `README.md`: cài đặt nhanh và cấu hình tích hợp.
- `backend/README.md`: chi tiết REST API và VNPay.
- `README_AUDIO_PLAYER.md`: chức năng phát audio.
- `lib/features/library/AUDIO_FEATURE.md`: thiết kế tính năng audio trong thư
  viện.
