# waka_demo

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

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
