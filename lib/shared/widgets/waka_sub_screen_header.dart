import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class WakaSubScreenHeader extends StatelessWidget {
  const WakaSubScreenHeader({
    super.key,
    required this.title,
    this.onBack,
    this.trailing,
  });

  final String title;
  final VoidCallback? onBack;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: Row(
        children: [
          IconButton(
            onPressed: onBack ?? () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          ),
          Expanded(
            child: Text(
              title,
              textAlign: trailing == null ? TextAlign.center : TextAlign.start,
              style: const TextStyle(
                color: WakaColors.text,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          if (trailing != null)
            trailing!
          else
            const SizedBox(width: 48),
        ],
      ),
    );
  }
}
