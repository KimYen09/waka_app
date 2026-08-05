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
| GET | `/api/cart` | Giỏ hàng đã lưu của tài khoản | Bearer JWT |
| POST/DELETE | `/api/cart/items` | Cập nhật/xóa sản phẩm giỏ hàng | Bearer JWT |
| POST | `/api/checkout` | Tạo đơn và giao dịch demo từ giỏ hàng | Bearer JWT |
| GET | `/api/membership-plans` | Danh sách gói hội viên | Không |
| GET/POST | `/api/memberships/me`, `/api/memberships/purchase` | Lịch sử/mua gói hội viên demo | Bearer JWT |
| GET | `/api/payments` | Lịch sử giao dịch demo | Bearer JWT |
| GET | `/api/payments/vnpay/return` | Trang kết quả sau khi khách thanh toán trên VNPay (WebView mở URL này) | Không |
| GET | `/api/payments/vnpay/ipn` | VNPay gọi server-to-server để xác nhận giao dịch (không dùng trực tiếp từ app) | Không |

## Thanh toán qua VNPay (sandbox)

Đặt `paymentMethod: "vnpay"` khi gọi `POST /api/checkout` hoặc
`POST /api/memberships/purchase` (gói hội viên không cần gửi `transactionRef`
trong trường hợp này). Response trả thêm trường `data.paymentUrl` — mở URL đó
trong WebView để khách thanh toán trên VNPay.

Sau khi thanh toán, VNPay chuyển hướng WebView về
`GET /api/payments/vnpay/return` (chỉ để hiển thị trang kết quả cho khách).
Nguồn xác nhận chính thức là `GET /api/payments/vnpay/ipn`, được VNPay gọi
thẳng từ server của họ — app chỉ cần theo dõi URL của WebView, khi thấy nó
chứa `/api/payments/vnpay/return` thì đóng WebView và gọi lại
`GET /api/orders` hoặc `GET /api/memberships/me` để lấy trạng thái mới nhất.

App nhận diện trang kết quả bằng **path** (`ApiEndpoints.vnpayReturnPath`),
không so khớp URL đầy đủ. Nhờ vậy `VNP_RETURN_URL` được phép trỏ tới host
tunnel công khai khác hẳn `API_BASE_URL` mà app dùng để gọi API, và đổi
tunnel thì không phải build lại app.

`vnp_ResponseCode` trên URL trả về chỉ là tín hiệu hiển thị tạm. Sau khi đóng
WebView, app hỏi lại backend vài nhịp (`GET /api/orders`,
`GET /api/memberships/me`) rồi mới kết luận, vì IPN có thể về sau vài giây.

Cấu hình cần thiết trong `.env` (đăng ký tài khoản merchant sandbox tại
https://sandbox.vnpayment.vn/devreg/, xem TMN Code/Hash Secret tại
https://sandbox.vnpayment.vn/merchantv2/):

```text
VNP_TMN_CODE=...
VNP_HASH_SECRET=...
VNP_URL=https://sandbox.vnpayment.vn/paymentv2/vpcpay.html
VNP_RETURN_URL=http://<host-backend-cong-khai>:3000/api/payments/vnpay/return
```

`VNP_RETURN_URL` và endpoint IPN phải là URL VNPay truy cập được từ Internet —
khi chạy local, dùng ngrok/localtunnel để expose backend rồi khai báo URL
public đó trên cổng quản trị VNPay sandbox lẫn trong `.env`.

Ba điểm hay làm hỏng luồng sandbox:

1. **IPN URL phải được khai trên cổng quản trị VNPay sandbox**
   (`https://<host-cong-khai>/api/payments/vnpay/ipn`). Nếu bỏ qua, khách trả
   tiền thành công nhưng đơn kẹt vĩnh viễn ở `payment_review` và gói hội viên
   kẹt ở `pending`, vì không có gì gọi `applyPaymentStatus`.
2. **Đổi tunnel là phải sửa cả hai chỗ** — `VNP_RETURN_URL` trong `.env` *và*
   IPN URL trên cổng quản trị. URL ngrok/cloudflared đổi mỗi lần khởi động lại.
3. **`PORT` trong `.env` phải khớp với cổng mà tunnel và `API_BASE_URL` trỏ
   tới.** Mặc định của app là `:3000`; nếu chạy backend ở cổng khác thì phải
   truyền `--dart-define=API_BASE_URL=http://<host>:<port>/api`.

Kiểm tra nhanh IPN mà không cần thanh toán thật: lấy `transactionRef` của một
giao dịch đang `pending` trong bảng `payments`, ký query bằng `VNP_HASH_SECRET`
rồi gọi `GET /api/payments/vnpay/ipn`. Trả về `{"RspCode":"00"}` nghĩa là
đường dây xác nhận đã thông.

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

## Dữ liệu thương mại

Schema tạo các bảng `cart_items`, `membership_plans`, `user_memberships` và
`payments`. Thanh toán hiện là mô phỏng: backend chỉ tạo mã giao dịch `DEMO-*`
và trạng thái `paid`; tuyệt đối không gửi hoặc lưu số thẻ, CVV hay OTP. Khi tích
hợp cổng thanh toán thật, chỉ lưu mã giao dịch và trạng thái phản hồi của cổng.
