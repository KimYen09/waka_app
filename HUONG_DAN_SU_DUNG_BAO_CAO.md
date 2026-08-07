# **4.2. Hướng dẫn sử dụng:**

## **Step 1: Khởi Động Hệ Thống Trước Khi Sử Dụng**

**Khởi động cơ sở dữ liệu MySQL:**

**Mở Docker Desktop ➔ Mở Terminal tại thư mục `backend` ➔ Chạy lệnh `docker compose up -d`.**

**Kiểm tra trạng thái database bằng lệnh `docker compose ps`. Khi container `backend-mysql-1` hiển thị trạng thái `healthy`, cơ sở dữ liệu đã sẵn sàng.**

**Khởi động REST API:**

**Tại thư mục `backend`, chạy `npm run dev`. Khi Terminal hiển thị `Waka API listening on http://localhost:3000`, backend đã hoạt động.**

**Khởi động ứng dụng Flutter:**

**Mở Terminal khác tại thư mục gốc dự án ➔ Chạy `flutter devices` để kiểm tra thiết bị ➔ Chạy `flutter run -d emulator-5554` để mở ứng dụng trên Android Emulator.**

**Android Emulator sử dụng địa chỉ `http://10.0.2.2:3000/api` để kết nối với backend đang chạy trên máy tính.**

## **Step 2: Đăng Nhập / Đăng Ký Tài Khoản & Phân Quyền**

**Đăng nhập/Đăng ký thông thường:**

**Mở ứng dụng ➔ Chọn Đăng nhập hoặc chuyển sang Tab Cá nhân/Thư viện để truy cập màn hình xác thực.**

**Nhập Email hoặc Số điện thoại và Mật khẩu ➔ Nhấn Đăng nhập. Nếu chưa có tài khoản, chọn Đăng ký ngay ➔ Nhập thông tin ➔ Xác nhận tạo tài khoản.**

**Sau khi đăng nhập thành công, backend trả về JWT. Ứng dụng lưu phiên đăng nhập trong Secure Storage để khôi phục đúng tài khoản sau khi đóng hoặc mở lại ứng dụng.**

**Đăng nhập nhanh qua Google:**

**Nhấn nút Đăng nhập bằng Google trên màn hình xác thực ➔ Chọn tài khoản Google ➔ Đồng ý cấp quyền ➔ Hệ thống liên kết tài khoản Google với tài khoản Waka.**

**Tính năng này yêu cầu cấu hình Google OAuth, Web Client ID, SHA-1 và file `google-services.json`. Nếu môi trường chưa cấu hình, người dùng vẫn có thể đăng nhập bằng Email/Số điện thoại và Mật khẩu.**

**Cơ chế phân quyền tự động:**

**Hệ thống đọc trường `role` của tài khoản sau khi đăng nhập để điều hướng đến giao diện phù hợp.**

**Nếu là User thường (`reader`), ứng dụng hiển thị giao diện đọc sách, quản lý thư viện, mua sắm, theo dõi đơn hàng và sử dụng Trợ lý AI.**

**Nếu là Tác giả (`author`), tài khoản được ghi nhận vai trò tác giả sau khi đơn đăng ký tác giả được quản trị viên phê duyệt.**

**Nếu là Tài khoản Admin (`admin`), hệ thống điều hướng trực tiếp vào** ***Trung tâm quản trị*** **để quản lý người dùng, tác giả, sách, đánh giá, đơn hàng và thanh toán.**

## **Step 3: Tìm Kiếm, Xem Chi Tiết & Đọc Sách**

**Tìm kiếm sách:**

**Mở Trang chủ, Waka Shop hoặc Trang Khám phá ➔ Nhấn vào Thanh tìm kiếm ➔ Nhập tên cuốn sách cần tìm ➔ Chọn kết quả phù hợp.**

**Người dùng có thể duyệt sách theo danh mục, bảng xếp hạng, sách đề xuất, sách hội viên hoặc các chương trình ưu đãi.**

**Xem chi tiết sách:**

**Nhấn vào ảnh bìa hoặc tên sách ➔ Ứng dụng mở màn hình chi tiết với tên sách, tác giả, mô tả, giá bán, ưu đãi và đánh giá của độc giả.**

**Đọc sách:**

**Tại màn hình chi tiết ➔ Nhấn Đọc sách hoặc Đọc thử ➔ Ứng dụng mở `ReaderScreen` ➔ Vuốt ngang để chuyển trang.**

***Tính năng đồng bộ tiến độ:*** **Mỗi khi người dùng chuyển trang, ứng dụng gửi vị trí hiện tại đến `POST /api/progress`. Backend lưu trang đang đọc trong bảng `reading_progress`, giúp tài khoản tiếp tục đọc từ dữ liệu đã lưu khi mở lại sách.**

**Mở Tab Thư viện ➔ Chọn mục Tiếp tục để xem các sách đang đọc dở và trang đọc gần nhất.**

## **Step 4: Quản Lý Sách Yêu Thích, Tải Xuống & Đánh Giá**

**Thêm sách yêu thích:**

**Mở chi tiết sách ➔ Nhấn biểu tượng Yêu thích ➔ Sách được lưu vào bảng `favorites` theo tài khoản đang đăng nhập.**

**Mở Tab Thư viện ➔ Chọn mục Yêu thích để xem lại danh sách. Nhấn bỏ yêu thích nếu muốn xóa sách khỏi danh sách cá nhân.**

**Lưu sách vào mục tải xuống:**

**Tại màn hình hỗ trợ tải xuống ➔ Chọn Tải sách ➔ Backend ghi nhận sách trong bảng `downloads` ➔ Mở Tab Thư viện ➔ Chọn mục Tải xuống để kiểm tra.**

**Đánh giá sách:**

**Mở chi tiết sách ➔ Chuyển đến khu vực Đánh giá ➔ Chọn số sao ➔ Nhập bình luận ➔ Nhấn Gửi đánh giá.**

**Mỗi tài khoản có một đánh giá cho mỗi cuốn sách. Nếu người dùng gửi lại, hệ thống cập nhật nội dung đánh giá hiện có thay vì tạo nhiều bản ghi trùng lặp.**

## **Step 5: Hỏi Trợ Lý AI Waka (Tích Hợp Gemini)**

**Nhấn vào nút Trợ lý AI có biểu tượng AI màu ngọc lục bảo ở góc dưới màn hình.**

**Chọn một câu hỏi gợi ý có sẵn hoặc tự nhập câu hỏi về sách, nội dung tác phẩm, thói quen đọc và nhu cầu phát triển bản thân.**

**Nhấn Gửi ➔ Flutter gọi `POST /api/ai/chat` ➔ Backend gửi câu hỏi đến Gemini ➔ Kết quả được trả về và hiển thị trong giao diện hội thoại.**

**Ví dụ câu hỏi: “Gợi ý sách phát triển bản thân”, “Tôi nên đọc sách nào để học quản lý tài chính?” hoặc “Phân tích bài học chính của một cuốn sách”.**

**Tính năng yêu cầu `GEMINI_API_KEY` trong file `backend/.env`. Nếu chưa cấu hình, hệ thống hiển thị thông báo thay vì kết quả AI.**

## **Step 6: Mua Sách Giấy Trên Waka Shop**

**Chuyển sang Tab Waka Shop ➔ Chọn danh mục hoặc tìm kiếm sản phẩm ➔ Chọn cuốn sách muốn mua.**

**Nhấn Thêm vào giỏ để tiếp tục mua sắm hoặc nhấn Mua ngay để chuyển nhanh đến quy trình thanh toán.**

**Mở Giỏ hàng ➔ Kiểm tra danh sách sản phẩm ➔ Điều chỉnh số lượng hoặc xóa sản phẩm không cần thiết ➔ Nhấn Mua hàng.**

**Thêm địa chỉ nhận hàng:**

**Nhấn Thêm địa chỉ ➔ Nhập Tên người nhận, Số điện thoại, Tỉnh/Thành phố, Quận/Huyện, Phường/Xã, Số nhà và Tên đường ➔ Chọn loại địa chỉ ➔ Nhấn Lưu.**

**Địa chỉ được lưu theo tài khoản trong Secure Storage. Nếu dữ liệu local không còn, mục Profile có thể khôi phục địa chỉ từ đơn hàng gần nhất của tài khoản.**

**Áp dụng voucher:**

**Nhấn vào mục Voucher ➔ Chọn mã ưu đãi phù hợp ➔ Hệ thống tính lại số tiền giảm. Backend sẽ kiểm tra lại mã và điều kiện tối thiểu khi checkout.**

**Xác nhận đơn hàng:**

**Chọn Phương thức thanh toán ➔ Kiểm tra sản phẩm, số lượng, địa chỉ và tổng tiền ➔ Nhấn Xác nhận đặt hàng ➔ Đơn hàng được lưu vào các bảng `orders`, `order_items` và `payments` của MySQL.**

## **Step 7: Thanh Toán COD / VNPay & Theo Dõi Đơn Hàng**

**Thanh toán khi nhận hàng (COD):**

**Chọn Thanh toán khi nhận hàng ➔ Nhấn Xác nhận đặt hàng ➔ Đơn được tạo ở trạng thái `confirmed` và xuất hiện trong nhóm Chờ lấy hàng.**

**Thanh toán VNPay Sandbox:**

**Chọn VNPay ➔ Backend tạo giao dịch `pending` ➔ Ứng dụng mở trang VNPay trong WebView ➔ Thực hiện thanh toán bằng tài khoản sandbox.**

**Sau khi thanh toán, VNPay chuyển người dùng về trang kết quả và gửi IPN đến backend. Backend kiểm tra chữ ký trước khi cập nhật giao dịch sang `paid` hoặc `failed`.**

**Theo dõi đơn hàng:**

**Mở Tab Cá nhân ➔ Xem khu vực Đơn hàng. Mỗi lần chọn Tab Cá nhân, ứng dụng gọi lại API để cập nhật số lượng đơn theo trạng thái.**

**Chờ xác nhận:** **Đếm đơn có trạng thái `payment_review`.**

**Chờ lấy hàng:** **Đếm đơn có trạng thái `confirmed` hoặc `packing`.**

**Đang giao hàng:** **Đếm đơn có trạng thái `in_transit`, `at_hub` hoặc `out_for_delivery`.**

**Nhấn Chi tiết đơn hàng để xem toàn bộ lịch sử, sản phẩm, phương thức thanh toán, địa chỉ và tiến trình vận chuyển.**

## **Step 8: Kiểm Tra Sách Đã Mua Trong Thư Viện**

**Mở Tab Thư viện ➔ Chọn mục Sách đã mua.**

**Ứng dụng gọi `GET /api/orders`, tổng hợp các sản phẩm trong `order_items` và loại bỏ sách trùng lặp để tạo tủ sách cá nhân.**

**Mỗi sách hiển thị ảnh bìa lấy từ trường `imageUrl`, tên sách và số lượng đã mua. Nếu CDN ảnh tạm thời không hoạt động, ứng dụng hiển thị bìa dự phòng.**

**Nhấn vào sách đã mua để mở màn hình đọc và tiếp tục lưu tiến độ đọc.**

## **Step 9: Đăng Ký Trở Thành Tác Giả**

**Mở Tab Cá nhân ➔ Chọn Đăng ký làm tác giả.**

**Nhập Họ tên thật, Bút danh, Email, Số điện thoại, Tiểu sử, Tài liệu định danh và Đường dẫn tác phẩm ➔ Nhấn Gửi đăng ký.**

**Đơn được lưu trong bảng `author_applications` với trạng thái `pending`.**

**Admin xem xét đơn đăng ký ➔ Chọn Phê duyệt hoặc Từ chối ➔ Nếu được duyệt, hệ thống tạo hồ sơ tác giả và cập nhật vai trò tài khoản phù hợp.**

## **Step 10: Dành Riêng Cho Tài Khoản Admin (Quản Trị Hệ Thống)**

**Đăng nhập bằng tài khoản có vai trò `admin` và trạng thái `active` ➔ Hệ thống tự động điều hướng đến Trung tâm quản trị.**

**Quản lý tài khoản người dùng:** **Xem danh sách user, cập nhật thông tin, phân quyền và khóa/mở tài khoản.**

**Quản lý tác giả:** **Xem hồ sơ tác giả, cập nhật thông tin, khóa/mở tác giả và xét duyệt đơn đăng ký tác giả.**

**Quản trị sách:** **Thêm sách mới, chỉnh sửa thông tin, duyệt nội dung, từ chối hoặc khóa sách vi phạm.**

**Quản lý đánh giá:** **Xem toàn bộ đánh giá của người dùng và khóa/mở đánh giá không phù hợp.**

**Quản lý đơn hàng:** **Theo dõi toàn bộ đơn hàng của khách hàng ➔ Cập nhật trạng thái `confirmed` ➔ `packing` ➔ `in_transit` ➔ `at_hub` ➔ `out_for_delivery` ➔ `delivered`.**

**Cập nhật vận chuyển:** **Nhập địa điểm và mô tả cho mỗi shipping event để người dùng theo dõi hành trình đơn hàng.**

**Quản lý thanh toán:** **Xem giao dịch COD, QR hoặc VNPay; kiểm tra mã giao dịch, số tiền và trạng thái thanh toán.**

## **Step 11: Quản Lý Tài Khoản & Địa Chỉ Tại Profile**

**Mở Tab Cá nhân để xem thông tin tài khoản, mã người dùng, trạng thái gói hội viên, thông báo và lịch sử đơn hàng.**

**Chọn Địa chỉ để xem địa chỉ nhận hàng mặc định. Hệ thống ưu tiên dữ liệu Secure Storage; nếu chưa có, địa chỉ được khôi phục từ đơn hàng gần nhất.**

**Chọn Đơn hàng và vận chuyển để xem danh sách đơn cùng trạng thái chi tiết.**

**Chọn Đăng xuất để xóa phiên đăng nhập đã lưu trên thiết bị và quay lại màn hình chào mừng.**

## **Step 12: Một Số Lưu Ý Khi Sử Dụng**

**Nếu ứng dụng báo Không thể kết nối API:** **Kiểm tra Docker MySQL, `npm run dev`, cổng 3000 và địa chỉ `API_BASE_URL`.**

**Nếu ảnh bìa không hiển thị:** **Kiểm tra kết nối Internet và DNS của emulator; ảnh sẽ tạm thời được thay bằng bìa dự phòng.**

**Nếu badge đơn hàng chưa đổi:** **Chọn lại Tab Cá nhân hoặc kéo xuống để refresh.**

**Nếu địa chỉ chưa xuất hiện:** **Đăng nhập đúng tài khoản đã đặt đơn ➔ Hot Restart ứng dụng ➔ Mở lại Cá nhân ➔ Địa chỉ.**

**Nếu vừa cập nhật model, dependency hoặc cấu hình session:** **Sử dụng Hot Restart thay vì chỉ Hot Reload.**
