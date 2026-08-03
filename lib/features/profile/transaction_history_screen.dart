import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../shared/widgets/waka_empty_illustration.dart';
import '../../shared/widgets/waka_sub_screen_header.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  State<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  late int _selectedTab;
  int _subFilter = 0;

  static const _tabs = ['Thanh toán', 'Hạt Sồi', 'Lá Xanh', 'Điểm'];

  static const _pointTransactions = [
    _Transaction(
      title: 'Đọc/nghe trên 30 phút/ngày',
      date: '06-07-2026 18:00:04',
      amount: '+1',
      color: Color(0xFFFF2F6E),
    ),
    _Transaction(
      title: 'Đọc/nghe trên 30 phút/ngày',
      date: '05-07-2026 18:00:04',
      amount: '+1',
      color: Color(0xFFFF2F6E),
    ),
    _Transaction(
      title: 'Đọc/nghe trên 30 phút/ngày',
      date: '04-07-2026 18:00:04',
      amount: '+1',
      color: Color(0xFFFF2F6E),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTab;
  }

  bool get _showSubFilters => _selectedTab == 1 || _selectedTab == 2;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WakaColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const WakaSubScreenHeader(title: 'Lịch sử giao dịch'),
            const SizedBox(height: 8),
            SizedBox(
              height: 40,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: _tabs.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final isSelected = index == _selectedTab;
                  return GestureDetector(
                    onTap: () => setState(() {
                      _selectedTab = index;
                      _subFilter = 0;
                    }),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(24),
                        border: isSelected
                            ? null
                            : Border.all(color: const Color(0xFF3A3A3D)),
                      ),
                      child: Text(
                        _tabs[index],
                        style: TextStyle(
                          color: isSelected ? Colors.black : WakaColors.text,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            if (_showSubFilters) ...[
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _SubFilterChip(
                      label: 'Lịch sử cộng',
                      selected: _subFilter == 0,
                      onTap: () => setState(() => _subFilter = 0),
                    ),
                    const SizedBox(width: 10),
                    _SubFilterChip(
                      label: 'Lịch sử trừ',
                      selected: _subFilter == 1,
                      onTap: () => setState(() => _subFilter = 1),
                    ),
                  ],
                ),
              ),
            ],
            if (_selectedTab == 0) ...[
              const SizedBox(height: 16),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Lưu ý: Ở đây chỉ hiển thị lịch sử giao dịch theo từng nền tảng',
                  style: TextStyle(
                    color: WakaColors.mutedText,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ),
            ],
            Expanded(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_selectedTab == 3) {
      return ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        itemCount: _pointTransactions.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) =>
            _TransactionTile(transaction: _pointTransactions[index]),
      );
    }

    return WakaEmptyIllustration(
      message: 'Chưa có giao dịch nào',
      type: WakaEmptyIllustrationType.wallet,
    );
  }
}

class _SubFilterChip extends StatelessWidget {
  const _SubFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? Colors.white : const Color(0xFF3A3A3D),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.black : WakaColors.text,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _Transaction {
  const _Transaction({
    required this.title,
    required this.date,
    required this.amount,
    required this.color,
  });

  final String title;
  final String date;
  final String amount;
  final Color color;
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({required this.transaction});

  final _Transaction transaction;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: WakaColors.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.title,
                  style: const TextStyle(
                    color: WakaColors.text,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  transaction.date,
                  style: const TextStyle(
                    color: WakaColors.mutedText,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Text(
            transaction.amount,
            style: const TextStyle(
              color: WakaColors.accent,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: transaction.color,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.star, color: Colors.white, size: 14),
          ),
        ],
      ),
    );
  }
}
