import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../shared/navigation/app_navigation.dart';

/// Màn "Đổi mật khẩu" trong Thông tin tài khoản (khác với màn Quên mật khẩu
/// ở luồng đăng nhập) - yêu cầu nhập mật khẩu cũ.
class AccountChangePasswordScreen extends StatefulWidget {
  const AccountChangePasswordScreen({super.key});

  @override
  State<AccountChangePasswordScreen> createState() =>
      _AccountChangePasswordScreenState();
}

class _AccountChangePasswordScreenState
    extends State<AccountChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController oldPasswordController = TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  bool obscureOld = true;
  bool obscureNew = true;
  bool obscureConfirm = true;

  @override
  void dispose() {
    oldPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  void _updatePassword() {
    if (_formKey.currentState!.validate()) {
      // TODO: gọi API đổi mật khẩu thật ở đây, dùng oldPassword + newPassword

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Đổi mật khẩu thành công')));

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WakaColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => AppNavigation.goBackOrExit(context),
                      child: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      'Đổi mật khẩu',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),

                const Text(
                  'Mật khẩu của bạn phải có từ 6 đến 20 kí tự',
                  style: TextStyle(color: WakaColors.mutedText, fontSize: 15),
                ),
                const SizedBox(height: 16),

                _PasswordField(
                  controller: oldPasswordController,
                  hint: 'Nhập mật khẩu cũ',
                  obscure: obscureOld,
                  onToggle: () => setState(() => obscureOld = !obscureOld),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập mật khẩu cũ';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                _PasswordField(
                  controller: newPasswordController,
                  hint: 'Nhập mật khẩu mới',
                  obscure: obscureNew,
                  onToggle: () => setState(() => obscureNew = !obscureNew),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập mật khẩu mới';
                    }
                    if (value.length < 6 || value.length > 20) {
                      return 'Mật khẩu phải có từ 6 đến 20 kí tự';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                _PasswordField(
                  controller: confirmPasswordController,
                  hint: 'Nhập lại mật khẩu mới',
                  obscure: obscureConfirm,
                  onToggle: () =>
                      setState(() => obscureConfirm = !obscureConfirm),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập lại mật khẩu mới';
                    }
                    if (value != newPasswordController.text) {
                      return 'Mật khẩu nhập lại không khớp';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 28),

                Center(
                  child: SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(30),
                      child: Ink(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF00E5A0), Color(0xFF00C853)],
                          ),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(30),
                          onTap: _updatePassword,
                          child: Container(
                            alignment: Alignment.center,
                            child: const Text(
                              'CẬP NHẬT',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ),
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
    );
  }
}

class _PasswordField extends StatelessWidget {
  const _PasswordField({
    required this.controller,
    required this.hint,
    required this.obscure,
    required this.onToggle,
    this.validator,
  });

  final TextEditingController controller;
  final String hint;
  final bool obscure;
  final VoidCallback onToggle;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: WakaColors.surface,
        borderRadius: BorderRadius.circular(30),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          prefixIcon: const Icon(
            Icons.lock_outline_rounded,
            color: WakaColors.accent,
            size: 22,
          ),
          hintText: hint,
          hintStyle: const TextStyle(color: WakaColors.mutedText),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 4,
            vertical: 18,
          ),
          suffixIcon: IconButton(
            icon: Icon(
              obscure
                  ? Icons.remove_red_eye_outlined
                  : Icons.visibility_off_outlined,
              color: WakaColors.mutedText,
            ),
            onPressed: onToggle,
          ),
        ),
        validator: validator,
      ),
    );
  }
}
