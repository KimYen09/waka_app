# waka_demo

Ứng dụng đọc/nghe sách (Flutter) kèm REST API (Node.js + MySQL): danh mục sách,
giỏ hàng, đơn hàng, gói hội viên, thanh toán VNPay, và trang quản trị.

- Flutter app: `lib/`
- Backend API: `backend/`

---

# Chạy lần đầu

Làm đúng theo thứ tự này. Toàn bộ mất khoảng 10 phút.

## 1. Cài sẵn

| Thứ | Yêu cầu | Kiểm tra |
|---|---|---|
| Flutter SDK | Dart >= 3.12 (bản **stable** là đủ) | `flutter --version` |
| Node.js | >= 20 | `node --version` |
| MySQL | 8.x, hoặc dùng Docker ở bước 2 | |
| Android Studio | kèm ít nhất một emulator (AVD) | `flutter devices` |

Chạy `flutter doctor` và sửa hết các mục báo lỗi trước khi đi tiếp.

## 2. Dựng database

Cách nhanh nhất là Docker:

```bash
cd backend
docker compose up -d
```

Lệnh này dựng MySQL 8.4 ở cổng 3306, user `root`, mật khẩu `root`, database
`waka_demo`. Nếu bạn đã có MySQL riêng thì bỏ qua bước này và tự tạo database
(schema sẽ tự `CREATE DATABASE IF NOT EXISTS waka_demo`).

## 3. Tạo file `backend/.env`

**Bước bắt buộc.** File `.env` chứa bí mật nên không nằm trong Git — máy nào
cũng phải tự tạo:

```bash
cd backend
cp .env.example .env
```

Rồi mở `.env` sửa 3 dòng:

```env
PORT=3000                 # giữ 3000 cho khớp mặc định của app
DB_PASSWORD=root          # khớp MySQL của bạn (docker compose dùng "root")
JWT_SECRET=<chuỗi ngẫu nhiên bất kỳ, càng dài càng tốt>
```

Các biến còn lại **để trống vẫn chạy được**, chỉ tắt tính năng tương ứng:

| Biến | Bỏ trống thì sao |
|---|---|
| `GOOGLE_CLIENT_ID` | Nút đăng nhập Google báo "chưa được cấu hình". Đăng nhập email/mật khẩu vẫn bình thường |
| `FACEBOOK_APP_ID`, `FACEBOOK_APP_SECRET` | Nút Facebook không dùng được |
| `VNP_TMN_CODE`, `VNP_HASH_SECRET` | Chọn VNPay sẽ báo lỗi. COD và chuyển khoản QR vẫn chạy |
| `GEMINI_API_KEY` | Trợ lý AI không trả lời |

> Đừng bao giờ dán giá trị thật vào `.env.example` — file đó **có** trong Git.

## 4. Chạy backend

```bash
cd backend
npm install        # BẮT BUỘC, kể cả khi đã có thư mục node_modules
npm run db:init    # tạo 21 bảng + dữ liệu mẫu
npm run dev
```

Thấy `Waka API listening on http://localhost:3000` là được. Kiểm tra nhanh:

```bash
curl http://127.0.0.1:3000/api/membership-plans
```

## 5. Chạy app

Mở terminal khác, ở thư mục gốc dự án:

```bash
flutter pub get
flutter run
```

Nếu chạy trên **Android Emulator của Android Studio** thì không cần thêm tham số
nào — app mặc định gọi `http://10.0.2.2:3000/api`, đúng địa chỉ máy host.

---

## Chạy trên thiết bị khác

`10.0.2.2` là quy ước riêng của Android Emulator. Các trường hợp khác phải chỉ
định địa chỉ backend qua `--dart-define`:

```bash
# Desktop / iOS Simulator / web
flutter run -d windows --dart-define=API_BASE_URL=http://127.0.0.1:3000/api

# Điện thoại thật hoặc giả lập bên thứ ba (LDPlayer, NoxPlayer...)
flutter run --dart-define=API_BASE_URL=http://192.168.1.10:3000/api
```

Thay `192.168.1.10` bằng IP LAN của máy chạy backend (`ipconfig` trên Windows).
Máy và điện thoại phải cùng mạng Wi-Fi.

Nếu bạn đổi `PORT` trong `.env`, phải đổi cả trong `--dart-define` cho khớp.

---

## Lỗi thường gặp

**`Cannot find module '@google/genai'` khi chạy backend**
Chưa chạy `npm install`, hoặc `node_modules` cũ hơn `package.json`. Chạy lại
`npm install` trong thư mục `backend`.

**App báo lỗi kết nối, backend vẫn chạy bình thường**
Sai địa chỉ backend. Kiểm tra `PORT` trong `.env` có khớp với cổng trong
`--dart-define=API_BASE_URL` không. Trên emulator không phải của Google (như
LDPlayer) thì `10.0.2.2` không hoạt động — phải dùng IP LAN.

**Emulator Android Studio không khởi động được, lỗi OpenGL/Vulkan**
Đang bật một máy ảo Android khác (LDPlayer, NoxPlayer, BlueStacks). Chúng tranh
nhau phần cứng ảo hóa. Tắt hẳn máy ảo kia (kể cả tiến trình nền) rồi thử lại.

**`ER_ACCESS_DENIED_ERROR` khi `npm run db:init`**
`DB_USER` / `DB_PASSWORD` trong `.env` không khớp MySQL. Với `docker compose` thì
là `root` / `root`.

**Đăng nhập Google báo `DEVELOPER_ERROR`**
Thiếu SHA-1 của debug keystore trong Firebase Console. Mỗi máy có keystore riêng
nên không chia sẻ qua Git được — xem mục [Google và Facebook Sign-In](#google-và-facebook-sign-in).

**Thanh toán VNPay không tự xác nhận**
Cần tunnel công khai và khai IPN URL trên cổng merchant. Xem
[backend/README.md](backend/README.md#thanh-toán-qua-vnpay-sandbox).

---

## Tài liệu khác

- [backend/README.md](backend/README.md) — danh sách API, cấu hình VNPay sandbox
- Các mục bên dưới — đăng nhập mạng xã hội, thanh toán, trang quản trị

## Google và Facebook Sign-In

Ứng dụng gửi token lấy từ Google hoặc Facebook tới backend. Backend xác minh
token với nhà cung cấp, tạo (hoặc tìm lại) tài khoản Waka trong bảng `users` và
liên kết tài khoản mạng xã hội ở bảng `social_accounts`, rồi trả JWT của Waka.

### Cấu hình backend

Sao chép `backend/.env.example` thành `backend/.env` (nếu chưa có) rồi đặt:

```env
GOOGLE_CLIENT_ID=your-web-oauth-client-id.apps.googleusercontent.com
FACEBOOK_APP_ID=your-facebook-app-id
FACEBOOK_APP_SECRET=your-facebook-app-secret
```

`FACEBOOK_APP_SECRET` chỉ được đặt ở backend, tuyệt đối không đặt trong Flutter
hoặc Android. Sau đó chạy lại schema để có bảng liên kết mạng xã hội:

```bash
cd backend
npm run db:init
```

### Google (Android)

Trong Firebase/Google Cloud, tạo OAuth client Android cho package
`com.example.waka_demo`, thêm SHA-1 của keystore debug/release và tải lại
`android/app/google-services.json`. Đồng thời truyền Web client ID khi chạy:

```bash
flutter run --dart-define=GOOGLE_SERVER_CLIENT_ID=your-web-oauth-client-id.apps.googleusercontent.com
```

Web client ID trong lệnh trên phải trùng `GOOGLE_CLIENT_ID` của backend.

### Google (Web)

Tạo OAuth 2.0 Client ID loại **Web application** trong Google Cloud. Thêm các
Authorized JavaScript origins dùng cho môi trường local:

```text
http://localhost
http://localhost:7357
```

Đặt cùng một Web client ID trong `backend/.env`:

```env
GOOGLE_CLIENT_ID=your-web-oauth-client-id.apps.googleusercontent.com
```

Khởi động lại backend sau khi đổi `.env`, rồi chạy Flutter Web trên cổng cố định
và truyền Client ID vào ứng dụng:

```bash
flutter run -d chrome \
  --web-hostname localhost \
  --web-port 7357 \
  --dart-define=GOOGLE_WEB_CLIENT_ID=your-web-oauth-client-id.apps.googleusercontent.com
```

`GOOGLE_WEB_CLIENT_ID` của Flutter Web và `GOOGLE_CLIENT_ID` của backend phải là
cùng một OAuth Web client ID. Không truyền `GOOGLE_SERVER_CLIENT_ID` khi chạy
Web vì `google_sign_in_web` không hỗ trợ tham số đó.

### Facebook (Android)

Tạo Facebook App, thêm Android package `com.example.waka_demo` và key hash của
keystore. Sau đó điền App ID và Client Token (đều không phải App Secret) vào
`android/gradle.properties`:

```properties
FACEBOOK_APP_ID=your-facebook-app-id
FACEBOOK_CLIENT_TOKEN=your-facebook-client-token
```

Khi hai nút ở màn đăng nhập được bấm, app sẽ hiển thị lỗi cấu hình cụ thể nếu
các giá trị OAuth ở trên chưa được thiết lập.

## Thanh toán mua sách

Nút **MUA HÀNG** trong giỏ mở màn checkout gồm địa chỉ nhận hàng, bìa sách,
số lượng, voucher, chi tiết tiền và lựa chọn phương thức. Hiện có hai lựa chọn:

- **Thanh toán khi nhận hàng**: gọi endpoint checkout demo hiện có.
- **Quét QR CODE**: tạo VietQR chuyển khoản với đúng số tiền và mã đơn, nhưng
  chưa tự xác nhận đã nhận tiền.

Địa chỉ nhận hàng được lưu theo tài khoản đăng nhập trên thiết bị, gồm tên người
nhận, điện thoại, tỉnh/thành, quận/huyện, phường/xã, số nhà–tên đường và loại
địa chỉ. Danh mục ba cấp dùng Province Open API v1; nếu dịch vụ không khả dụng,
form tự chuyển sang nhập thủ công. Voucher tại checkout cho phép chọn, đổi hoặc
bỏ và backend kiểm tra lại điều kiện trước khi lưu tổng tiền đơn hàng.

### Cấu hình QR chuyển khoản

Dự án đang có tài khoản nhận mặc định của cửa hàng là MB Bank, BIN `970422`.
Ba biến dưới đây chỉ cần dùng khi muốn ghi đè tài khoản nhận lúc chạy:

```bash
flutter run -d chrome \
  --dart-define=PAYMENT_BANK_ID=YOUR_BANK_CODE_OR_BIN \
  --dart-define=PAYMENT_ACCOUNT_NUMBER=YOUR_ACCOUNT_NUMBER \
  --dart-define=PAYMENT_ACCOUNT_NAME=YOUR_ACCOUNT_NAME
```

`PAYMENT_BANK_ID` là mã ngân hàng hoặc BIN VietQR. Tên chủ tài khoản nên viết
không dấu, đúng như ngân hàng hiển thị. Thông tin tài khoản nhận được mã hóa
trong QR nên không phải khóa bí mật; API key và checksum key vẫn tuyệt đối không
được đặt trong Flutter.

QR QuickLink chỉ giúp khách chuyển đúng tài khoản, số tiền và nội dung. Nút
“TÔI ĐÃ CHUYỂN KHOẢN” không đánh dấu đơn đã thanh toán vì lời xác nhận từ phía
khách không chứng minh ngân hàng đã ghi có.

### Tự động xác nhận thanh toán thật

Để đơn tự chuyển từ `pending` sang `paid`, cần tích hợp cổng thanh toán ở
backend, ví dụ payOS:

1. Tạo và xác minh tài khoản merchant/cá nhân kinh doanh, rồi liên kết tài
   khoản ngân hàng nhận tiền.
2. Lấy `Client ID`, `API Key` và `Checksum Key`; chỉ lưu trong
   `backend/.env`, tuyệt đối không đặt trong Flutter.
3. Backend tạo payment link/QR theo một `orderCode` duy nhất và lưu payment ở
   trạng thái `pending`.
4. Cấu hình webhook HTTPS công khai. Backend kiểm tra chữ ký webhook, đối chiếu
   `orderCode`, số tiền và mã giao dịch rồi mới cập nhật `paid`.
5. Cấu hình `returnUrl` và `cancelUrl` để đưa khách về đúng trạng thái đơn.

Không gửi API key, checksum key, mật khẩu ngân hàng, OTP, số thẻ hoặc CVV qua
chat hay commit lên Git. Các phương thức ATM, Visa/Master/JBC và ví điện tử hiện
được khóa trên giao diện cho đến khi backend có cổng thanh toán tương ứng.

## Trung tâm quản trị nội dung

Trang **Trung tâm quản trị** xuất hiện trong Hồ sơ khi tài khoản đăng nhập có
quyền `admin`. Trang hỗ trợ duyệt/từ chối truyện, duyệt đăng ký tác giả, thêm và
sửa truyện, đồng thời khóa/mở khóa truyện hoặc tác giả kèm lý do.

Khai báo email hoặc số điện thoại của tài khoản quản trị trong `backend/.env`:

```env
ADMIN_IDENTIFIERS=admin@example.com
```

Có thể khai báo nhiều tài khoản, phân tách bằng dấu phẩy. Sau khi tài khoản đã
được đăng ký, chạy lại schema để thêm các bảng kiểm duyệt và cấp quyền admin:

```bash
cd backend
npm run db:init
```

Sau đó đăng xuất và đăng nhập lại để Flutter nhận trường `role = admin`. Backend
luôn kiểm tra lại quyền ở mọi API `/api/admin`; việc ẩn hoặc hiện menu trên
Flutter không được dùng làm cơ chế bảo mật.
