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
