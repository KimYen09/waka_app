import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../shared/widgets/waka_sub_screen_header.dart';

class GeneralInfoScreen extends StatelessWidget {
  const GeneralInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WakaColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const WakaSubScreenHeader(title: 'Thông tin chung'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                children: const [
                  _SettingsSection(
                    title: 'Cài đặt chung',
                    items: [
                      _SettingsItem(
                        icon: Icons.favorite_rounded,
                        iconColor: Color(0xFFFF2F6E),
                        title: 'Thể loại sách yêu thích',
                      ),
                      _SettingsItem(
                        icon: Icons.favorite_rounded,
                        iconColor: Color(0xFF4DA6FF),
                        title: 'Thể loại truyện tranh yêu thích',
                      ),
                      _SettingsItem(
                        icon: Icons.notifications_rounded,
                        iconColor: Color(0xFFFF2F6E),
                        title: 'Cài đặt nhận thông báo',
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  _SettingsSection(
                    title: 'Thông tin chung',
                    items: [
                      _SettingsItem(
                        icon: Icons.description_outlined,
                        iconColor: Color(0xFF9B59FF),
                        title: 'Thỏa thuận sử dụng dịch vụ',
                      ),
                      _SettingsItem(
                        icon: Icons.privacy_tip_outlined,
                        iconColor: Color(0xFF9B59FF),
                        title: 'Chính sách quyền riêng tư',
                      ),
                      _SettingsItem(
                        icon: Icons.star_outline_rounded,
                        iconColor: Color(0xFF4DA6FF),
                        title: 'Tiếp nhận đánh giá, phản ánh tổ chức xã hội',
                      ),
                      _SettingsItem(
                        icon: Icons.list_alt_rounded,
                        iconColor: Color(0xFFFF2F6E),
                        title: 'Danh sách đánh giá, phản ánh tổ chức xã hội',
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  _SettingsSection(
                    title: 'Hỗ trợ khách hàng',
                    items: [
                      _SettingsItem(
                        icon: Icons.sync_rounded,
                        iconColor: Color(0xFFFF9E11),
                        title: 'Chính sách đổi trả',
                      ),
                      _SettingsItem(
                        icon: Icons.payments_outlined,
                        iconColor: Color(0xFFFFC716),
                        title: 'Chính sách thanh toán',
                      ),
                      _SettingsItem(
                        icon: Icons.chat_bubble_outline_rounded,
                        iconColor: Color(0xFF72BF48),
                        title: 'Giải quyết khiếu nại',
                      ),
                      _SettingsItem(
                        icon: Icons.shield_outlined,
                        iconColor: Color(0xFFFF2F6E),
                        title: 'Chính sách xác nhận/hủy',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.title, required this.items});

  final String title;
  final List<_SettingsItem> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            title,
            style: const TextStyle(
              color: WakaColors.mutedText,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: WakaColors.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              for (var i = 0; i < items.length; i++) ...[
                items[i],
                if (i != items.length - 1)
                  const Divider(
                    height: 1,
                    thickness: 0.7,
                    color: WakaColors.divider,
                    indent: 56,
                    endIndent: 14,
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SettingsItem extends StatelessWidget {
  const _SettingsItem({
    required this.icon,
    required this.iconColor,
    required this.title,
  });

  final IconData icon;
  final Color iconColor;
  final String title;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {},
      child: SizedBox(
        height: 56,
        child: Row(
          children: [
            const SizedBox(width: 14),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: iconColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: WakaColors.text,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: WakaColors.mutedText,
              size: 24,
            ),
            const SizedBox(width: 10),
          ],
        ),
      ),
    );
  }
}
