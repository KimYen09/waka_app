import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../shared/widgets/waka_empty_illustration.dart';
import '../../shared/widgets/waka_sub_screen_header.dart';

class ShippingAddressScreen extends StatefulWidget {
  const ShippingAddressScreen({super.key});

  @override
  State<ShippingAddressScreen> createState() => _ShippingAddressScreenState();
}

class _ShippingAddressScreenState extends State<ShippingAddressScreen> {
  bool _showForm = false;

  @override
  Widget build(BuildContext context) {
    if (_showForm) {
      return _AddressFormScreen(onClose: () => setState(() => _showForm = false));
    }

    return Scaffold(
      backgroundColor: WakaColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const WakaSubScreenHeader(title: 'Địa chỉ nhận hàng'),
            Expanded(
              child: WakaEmptyIllustration(
                type: WakaEmptyIllustrationType.address,
                message: 'Bạn chưa có địa chỉ',
                subtitle: 'Hãy tạo địa chỉ để đặt hàng bạn nhé!',
                actionLabel: 'Tạo địa chỉ',
                onAction: () => setState(() => _showForm = true),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddressFormScreen extends StatelessWidget {
  const _AddressFormScreen({required this.onClose});

  final VoidCallback onClose;

  static const _fields = [
    'Nhập họ và tên người nhận',
    'Nhập số điện thoại',
    'Nhập Email',
    'Chọn Tỉnh/Thành phố',
    'Chọn Xã/Phường/Thị trấn',
    'Loại địa chỉ',
    'Nhập Địa chỉ nhận hàng',
    'Ghi chú',
  ];

  static const _dropdownFields = {3, 4, 5};
  static const _multilineFields = {6, 7};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WakaColors.background,
      body: SafeArea(
        child: Column(
          children: [
            WakaSubScreenHeader(
              title: 'Địa chỉ nhận hàng',
              trailing: IconButton(
                onPressed: onClose,
                icon: const Icon(Icons.close_rounded, color: Colors.white),
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                itemCount: _fields.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final isDropdown = _dropdownFields.contains(index);
                  final isMultiline = _multilineFields.contains(index);
                  return Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: isMultiline ? 14 : 0,
                    ),
                    constraints: BoxConstraints(
                      minHeight: isMultiline ? 80 : 52,
                    ),
                    decoration: BoxDecoration(
                      color: WakaColors.surface,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: isDropdown
                        ? Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _fields[index],
                                  style: const TextStyle(
                                    color: WakaColors.mutedText,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: WakaColors.mutedText,
                              ),
                            ],
                          )
                        : TextField(
                            maxLines: isMultiline ? 3 : 1,
                            style: const TextStyle(color: WakaColors.text),
                            decoration: InputDecoration(
                              hintText: _fields[index],
                              hintStyle: const TextStyle(
                                color: WakaColors.mutedText,
                                fontSize: 15,
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                vertical: isMultiline ? 0 : 16,
                              ),
                            ),
                          ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
