import 'package:flutter/material.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  // Key để kiểm tra Form
  final _formKey = GlobalKey<FormState>();

  final TextEditingController identifierController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  bool obscurePassword = true;
  bool obscureConfirmPassword = true;
  bool agreeTerms = true;

  final List<String> coverImages = const [
    'assets/images/covers/cover1.jpg',
    'assets/images/covers/cover2.jpg',
    'assets/images/covers/cover3.jpg',
    'assets/images/covers/cover4.jpg',
    'assets/images/covers/cover5.jpg',
    'assets/images/covers/cover6.jpg',
    'assets/images/covers/cover7.jpg',
    'assets/images/covers/cover8.jpg',
  ];

  @override
  void dispose() {
    identifierController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
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

  // Hàm xử lý đăng ký
  void register() {
    if (_formKey.currentState!.validate()) {
      String identifier = identifierController.text;
      String password = passwordController.text;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Tạo tài khoản thành công\nTài khoản: $identifier")),
      );

      print("Identifier: $identifier");
      print("Password: $password");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
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
                    color: const Color(0xFF2C2C2C),
                    child: Image.asset(
                      path,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(color: const Color(0xFF2C2C2C));
                      },
                    ),
                  );
                },
              ),
            ),
          ),
          Positioned.fill(
            child: Container(color: Colors.black.withOpacity(0.6)),
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
                  // Header: back - title - close
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Icon(Icons.arrow_back,
                            color: Colors.white, size: 26),
                      ),
                      const Expanded(
                        child: Center(
                          child: Text(
                            "Tạo tài khoản",
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Icon(Icons.close,
                            color: Colors.white, size: 26),
                      ),
                    ],
                  ),
                  const SizedBox(height: 90),
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
                  const SizedBox(height: 40),
                  const Center(
                    child: Text(
                      "Tạo tài khoản miễn phí",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Số điện thoại hoặc Email
                  _darkField(
                    controller: identifierController,
                    hint: "Số điện thoại hoặc Email",
                    keyboardType: TextInputType.emailAddress,
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
                  const SizedBox(height: 16),

                  // Mật khẩu
                  _darkField(
                    controller: passwordController,
                    hint: "Mật khẩu",
                    obscure: obscurePassword,
                    suffix: IconButton(
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
                  const SizedBox(height: 16),

                  // Nhập lại mật khẩu
                  _darkField(
                    controller: confirmPasswordController,
                    hint: "Nhập lại mật khẩu",
                    obscure: obscureConfirmPassword,
                    suffix: IconButton(
                      icon: Icon(
                        obscureConfirmPassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: Colors.white54,
                      ),
                      onPressed: () {
                        setState(() {
                          obscureConfirmPassword = !obscureConfirmPassword;
                        });
                      },
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Vui lòng nhập lại mật khẩu";
                      }

                      if (value != passwordController.text) {
                        return "Mật khẩu nhập lại không khớp";
                      }

                      return null;
                    },
                  ),
                  const SizedBox(height: 28),

                  // Nút tiếp tục
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: register,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00E5A0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text(
                        "TIẾP TỤC",
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

                  // Checkbox điều khoản
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            agreeTerms = !agreeTerms;
                          });
                        },
                        child: Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: agreeTerms
                                ? const Color(0xFF00E5A0)
                                : Colors.transparent,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: agreeTerms
                                  ? const Color(0xFF00E5A0)
                                  : Colors.white54,
                              width: 1.5,
                            ),
                          ),
                          child: agreeTerms
                              ? const Icon(Icons.check,
                                  color: Colors.black, size: 16)
                              : null,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: RichText(
                          text: const TextSpan(
                            style: TextStyle(color: Colors.white70, fontSize: 14),
                            children: [
                              TextSpan(text: "Tôi đồng ý với các "),
                              TextSpan(
                                text: "điều khoản",
                                style: TextStyle(color: Color(0xFF00E5A0)),
                              ),
                              TextSpan(text: " sử dụng"),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  Center(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Text(
                        "Đã có tài khoản?",
                        style: TextStyle(
                          color: Color(0xFF00E5A0),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
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

  Widget _darkField({
    required TextEditingController controller,
    required String hint,
    bool obscure = false,
    TextInputType keyboardType = TextInputType.text,
    Widget? suffix,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2E),
        borderRadius: BorderRadius.circular(30),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white54),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          suffixIcon: suffix,
        ),
        validator: validator,
      ),
    );
  }
}