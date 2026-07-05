import 'package:flutter/material.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';
import 'auth_background.dart';
import '../../main.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  // Key để kiểm tra Form
  final _formKey = GlobalKey<FormState>();

  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool obscurePassword = true;

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  // Kiểm tra định dạng email
  bool _isEmail(String value) {
    return RegExp(r'^[\w\.\-]+@[\w\-]+\.[\w\-\.]+$').hasMatch(value);
  }

  // Kiểm tra định dạng số điện thoại VN (10 số, bắt đầu bằng 0)
  bool _isPhone(String value) {
    return RegExp(r'^0[0-9]{9}$').hasMatch(value);
  }

  // Hàm xử lý đăng nhập
  // Hàm xử lý đăng nhập
  void login() {
    if (_formKey.currentState!.validate()) {
      String username = usernameController.text;
      String password = passwordController.text;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Đăng nhập thành công\nTài khoản: $username")),
      );

      print("Username: $username");
      print("Password: $password");

      // 🔥 THÊM ĐOẠN CODE CHUYỂN HƯỚNG VÀO ĐÂY ĐỂ VÀO TRANG CHỦ
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => const WakaShell(), // Gọi class màn hình Trang chủ của bạn kia
        ),
        (route) => false, // Dòng này cực kỳ quan trọng: xóa sạch các màn hình trước đó (Welcome, Login) để user không bấm nút Back quay lại màn Login được nữa.
      );
    }
  }

  // Danh sách đường dẫn ảnh bìa sách thật
  // Bỏ ảnh vào assets/images/covers/ rồi đặt tên đúng như dưới đây
  // (hoặc đổi tên trong list này cho khớp tên file ông có)
  final List<String> coverImages = const [
    'assets/images/covers/cover1.jpg',
    'assets/images/covers/cover2.jpg',
    'assets/images/covers/cover3.jpg',
    'assets/images/covers/cover4.jpg',
    'assets/images/covers/cover5.jpg',
    'assets/images/covers/cover6.jpg',
    'assets/images/covers/cover7.jpg',
    'assets/images/covers/cover8.jpg',
    'assets/images/covers/cover9.jpg',
    'assets/images/covers/cover10.jpg',
    'assets/images/covers/cover11.jpg',
    'assets/images/covers/cover12.jpg',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          const AuthBackground(),
          // Background: lưới bìa sách mờ
          Positioned.fill(
            child: Opacity(
              opacity: 0.35,
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  childAspectRatio: 0.68,
                ),
                itemCount: coverImages.length * 3,
                itemBuilder: (context, index) {
                  final path = coverImages[index % coverImages.length];
                  return Container(
                    margin: const EdgeInsets.all(2),
                    color: const Color(0xFF2C2C2C), // màu nền dự phòng
                    child: Image.asset(
                      path,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        // Nếu chưa có ảnh, hiện màu xám thay vì crash app
                        return Container(color: const Color(0xFF2C2C2C));
                      },
                    ),
                  );
                },
              ),
            ),
          ),
          // Overlay tối
          Positioned.fill(
            child: Container(color: Colors.black.withOpacity(0.55)),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Form(
                key: _formKey,
                child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  // Hàng: Hỗ trợ - X
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.headset_mic,
                                color: Colors.white, size: 20),
                            SizedBox(width: 8),
                            Text(
                              "Hỗ trợ",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () {},
                        child: const Icon(Icons.close,
                            color: Colors.white, size: 28),
                      ),
                    ],
                  ),
                  const SizedBox(height: 100),
                  const Center(
                    child: Text(
                      "Chào mừng bạn đến với Waka",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Center(
                    child: Text(
                      "WAKA",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 56,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    "Đăng nhập để đồng bộ dữ liệu của tài khoản trên nhiều thiết bị",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontSize: 15),
                  ),
                  const SizedBox(height: 28),

                  // Username / phone / email field
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF2C2C2E),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: TextFormField(
                      controller: usernameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: "Số điện thoại hoặc Email",
                        hintStyle: TextStyle(color: Colors.white54),
                        border: InputBorder.none,
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Vui lòng nhập số điện thoại hoặc email";
                        }

                        if (!_isEmail(value) && !_isPhone(value)) {
                          return "Số điện thoại hoặc email không hợp lệ";
                        }

                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Password field
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF2C2C2E),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: TextFormField(
                      controller: passwordController,
                      obscureText: obscurePassword,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: "Mật khẩu",
                        hintStyle: const TextStyle(color: Colors.white54),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 18),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: Colors.white54,
                          ),
                          onPressed: () {
                            setState(() {
                              obscurePassword = !obscurePassword;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Vui lòng nhập mật khẩu";
                        }

                        if (value.length <= 6) {
                          return "Mật khẩu phải trên 6 ký tự";
                        }

                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Nút Đăng nhập
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00E5A0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text(
                        "ĐĂNG NHẬP",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Đăng ký ngay / Quên mật khẩu
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const RegisterPage(),
                            ),
                          );
                        },
                        child: const Text(
                          "Đăng ký ngay",
                          style: TextStyle(
                            color: Color(0xFF00E5A0),
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const ForgotPasswordPage(),
                            ),
                          );
                        },
                        child: const Text(
                          "Quên mật khẩu?",
                          style: TextStyle(
                            color: Color(0xFF00E5A0),
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Hoặc đăng nhập với
                  Row(
                    children: const [
                      Expanded(
                        child: Divider(color: Colors.white24, thickness: 1),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          "Hoặc đăng nhập với",
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                      ),
                      Expanded(
                        child: Divider(color: Colors.white24, thickness: 1),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Social login icons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _socialIcon(Icons.apple),
                      _socialIcon(Icons.facebook),
                      _socialIcon(Icons.g_mobiledata, size: 32),
                      _socialIcon(Icons.credit_card),
                    ],
                  ),
                  const SizedBox(height: 40),
                ],
              ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _socialIcon(IconData icon, {double size = 26}) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white30, width: 1.2),
      ),
      child: Icon(icon, color: Colors.white, size: size),
    );
  }
}