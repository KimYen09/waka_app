import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../auth/change_password_screen.dart';
/// Màn "Thông tin tài khoản" - hiện ra khi bấm vào dòng tên/avatar ở Profile.
class AccountInfoScreen extends StatelessWidget {
  const AccountInfoScreen({
    super.key,
    this.displayName = 'Chưa cập nhật',
    this.phoneNumber = '0932707674',
    this.userId = '10691059',
    this.email,
  });

  final String displayName;
  final String phoneNumber;
  final String userId;
  final String? email;

  String get _maskedPhone {
    if (phoneNumber.length < 7) return phoneNumber;
    final start = phoneNumber.substring(0, 4);
    final end = phoneNumber.substring(phoneNumber.length - 3);
    return '$start***$end';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WakaColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          children: [
            const SizedBox(height: 10),
            // Header: back + tiêu đề
            Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.arrow_back,
                      color: Colors.white, size: 28),
                ),
                const SizedBox(width: 16),
                const Text(
                  'Thông tin tài khoản',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),

            // Avatar + tên + sđt + id
            Center(
              child: Column(
                children: [
                  Stack(
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0xFF71FFDC), Color(0xFF18C58E)],
                          ),
                        ),
                        child: const Icon(Icons.person,
                            color: Color(0xCCFFFFFF), size: 76),
                      ),
                      Positioned(
                        right: 2,
                        bottom: 2,
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: const BoxDecoration(
                            color: Color(0xFF3A3A3D),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.camera_alt_outlined,
                              color: Colors.white, size: 18),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        displayName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.edit, color: Colors.white54, size: 20),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '($phoneNumber)',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'ID: $userId',
                    style: const TextStyle(
                      color: WakaColors.mutedText,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Card: Giới tính / Ngày sinh
            _InfoCard(
              children: [
                _InfoRow(
                  icon: Icons.male_rounded,
                  label: 'Giới tính',
                  trailingText: 'Thiết lập ngay',
                  onTap: () {},
                ),
                const _RowDivider(),
                _InfoRow(
                  icon: Icons.cake_outlined,
                  label: 'Ngày sinh',
                  trailingText: 'Thiết lập ngay',
                  onTap: () {},
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Card: SĐT / Email / Facebook / Google
            _InfoCard(
              children: [
                _InfoRow(
                  icon: Icons.call_outlined,
                  label: _maskedPhone,
                  labelColor: Colors.white,
                  trailingWidget: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Xác thực',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  onTap: () {},
                ),
                const _RowDivider(),
                _InfoRow(
                  icon: Icons.email_outlined,
                  label: email ?? 'Chưa cập nhật',
                  labelColor: WakaColors.mutedText,
                  trailingIcon: Icons.chevron_right_rounded,
                  onTap: () {},
                ),
                const _RowDivider(),
                _InfoRow(
                  icon: Icons.facebook,
                  iconColor: const Color(0xFF1877F2),
                  label: 'Chưa kết nối với Facebook',
                  labelColor: WakaColors.mutedText,
                  onTap: () {},
                ),
                const _RowDivider(),
                _InfoRow(
                  customIcon: const _GoogleIcon(),
                  label: 'Chưa kết nối với Google',
                  labelColor: WakaColors.mutedText,
                  onTap: () {},
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Card: Đổi mật khẩu / Xoá tài khoản
            _InfoCard(
              children: [
                _InfoRow(
                  icon: Icons.lock_outline_rounded,
                  iconColor: WakaColors.accent,
                  label: 'Đổi mật khẩu',
                  labelColor: Colors.white,
                  trailingIcon: Icons.chevron_right_rounded,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const AccountChangePasswordScreen(),
                      ),
                    );
                  },
                ),
                const _RowDivider(),
                _InfoRow(
                  icon: Icons.delete_outline_rounded,
                  iconColor: WakaColors.accent,
                  label: 'Xoá tài khoản',
                  labelColor: Colors.white,
                  trailingIcon: Icons.chevron_right_rounded,
                  onTap: () {},
                ),
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: WakaColors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(children: children),
    );
  }
}

class _RowDivider extends StatelessWidget {
  const _RowDivider();
  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 1,
      thickness: 0.7,
      color: Color(0xFF2E2E31),
      indent: 16,
      endIndent: 16,
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    this.icon,
    this.customIcon,
    this.iconColor = WakaColors.accent,
    required this.label,
    this.labelColor = Colors.white,
    this.trailingText,
    this.trailingIcon,
    this.trailingWidget,
    this.onTap,
  });

  final IconData? icon;
  final Widget? customIcon;
  final Color iconColor;
  final String label;
  final Color labelColor;
  final String? trailingText;
  final IconData? trailingIcon;
  final Widget? trailingWidget;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Row(
          children: [
            customIcon ?? Icon(icon, color: iconColor, size: 24),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: labelColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (trailingWidget != null) trailingWidget!,
            if (trailingText != null)
              Row(
                children: [
                  Text(
                    trailingText!,
                    style: const TextStyle(
                      color: WakaColors.accent,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(Icons.chevron_right_rounded,
                      color: WakaColors.accent, size: 22),
                ],
              ),
            if (trailingIcon != null)
              Icon(trailingIcon, color: WakaColors.mutedText, size: 26),
          ],
        ),
      ),
    );
  }
}

class _GoogleIcon extends StatelessWidget {
  const _GoogleIcon();
  @override
  Widget build(BuildContext context) {
    return const Icon(Icons.g_mobiledata_rounded,
        color: Colors.redAccent, size: 28);
  }
}