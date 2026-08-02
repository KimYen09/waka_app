import 'package:flutter/material.dart';

/// Dải phân cách + hàng nút đăng nhập mạng xã hội, dùng chung cho màn Đăng nhập
/// và màn Đăng ký để hai nơi không lệch giao diện khi chỉnh sửa.
class SocialAuthRow extends StatelessWidget {
  const SocialAuthRow({
    super.key,
    required this.label,
    required this.enabled,
    required this.onGoogle,
    required this.onFacebook,
    this.showPlaceholders = false,
  });

  /// Ví dụ: 'Hoặc đăng nhập với' / 'Hoặc đăng ký với'.
  final String label;

  /// Tắt toàn bộ nút trong lúc màn cha đang gọi API.
  final bool enabled;
  final VoidCallback onGoogle;
  final VoidCallback onFacebook;

  /// Hiện thêm hai biểu tượng Apple/thẻ chưa được nối luồng đăng nhập.
  final bool showPlaceholders;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            const Expanded(child: Divider(color: Colors.white24, thickness: 1)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                label,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ),
            const Expanded(child: Divider(color: Colors.white24, thickness: 1)),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            if (showPlaceholders) const SocialAuthIcon(icon: Icons.apple),
            SocialAuthIcon(
              icon: Icons.facebook,
              label: 'Facebook',
              onTap: enabled ? onFacebook : null,
            ),
            SocialAuthIcon(
              icon: Icons.g_mobiledata,
              size: 32,
              label: 'Google',
              onTap: enabled ? onGoogle : null,
            ),
            if (showPlaceholders) const SocialAuthIcon(icon: Icons.credit_card),
          ],
        ),
      ],
    );
  }
}

class SocialAuthIcon extends StatelessWidget {
  const SocialAuthIcon({
    super.key,
    required this.icon,
    this.size = 26,
    this.label,
    this.onTap,
  });

  final IconData icon;
  final double size;
  final String? label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: onTap != null,
      label: label,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white30, width: 1.2),
          ),
          child: Icon(icon, color: Colors.white, size: size),
        ),
      ),
    );
  }
}
