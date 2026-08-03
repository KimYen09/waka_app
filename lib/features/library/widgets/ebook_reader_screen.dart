import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// Trang đọc sách điện tử
class EbookReaderScreen extends StatefulWidget {
  final String title;
  final String imageUrl;
  final Color color;

  const EbookReaderScreen({
    super.key,
    required this.title,
    required this.imageUrl,
    required this.color,
  });

  @override
  State<EbookReaderScreen> createState() => _EbookReaderScreenState();
}

class _EbookReaderScreenState extends State<EbookReaderScreen> {
  int _currentPage = 1;
  final int _totalPages = 256;
  double _fontSize = 16;
  bool _isNightMode = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _isNightMode ? Colors.black : WakaColors.background,
      appBar: AppBar(
        backgroundColor: _isNightMode ? Colors.black87 : WakaColors.background,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back_rounded, color: WakaColors.text),
        ),
        title: Text(
          widget.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: WakaColors.text,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          GestureDetector(
            onTap: () => setState(() => _isNightMode = !_isNightMode),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Icon(
                _isNightMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                color: WakaColors.accent,
                size: 24,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Content area
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Book cover
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 140,
                      height: 200,
                      color: widget.color,
                      child: Image.network(
                        widget.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) =>
                            Center(
                              child: Icon(
                                Icons.menu_book_rounded,
                                color: Colors.white.withValues(alpha: 0.5),
                                size: 80,
                              ),
                            ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Sample text content
                  Text(
                    'Chương 1: Giới Thiệu',
                    style: TextStyle(
                      color: WakaColors.text,
                      fontSize: _fontSize + 4,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.\n\nDuis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.\n\nSed ut perspiciatis unde omnis iste natus error sit voluptatem accusantium doloremque laudantium, totam rem aperiam, eaque ipsa quae ab illo inventore veritatis et quasi architecto beatae vitae dicta sunt explicabo.',
                    style: TextStyle(
                      color: _isNightMode 
                          ? Colors.grey[300] 
                          : WakaColors.text,
                      fontSize: _fontSize,
                      height: 1.8,
                      fontWeight: FontWeight.w400,
                    ),
                    textAlign: TextAlign.justify,
                  ),
                ],
              ),
            ),
          ),
          // Controls & Progress
          Container(
            color: _isNightMode 
                ? Colors.black87 
                : WakaColors.surface,
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Font size control
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () => setState(() {
                        if (_fontSize > 12) _fontSize -= 2;
                      }),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: WakaColors.elevated,
                        ),
                        child: const Icon(
                          Icons.text_decrease_rounded,
                          color: WakaColors.accent,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'A',
                      style: TextStyle(
                        color: WakaColors.mutedText,
                        fontSize: _fontSize - 4,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Slider(
                      value: _fontSize,
                      min: 12,
                      max: 24,
                      activeColor: WakaColors.accent,
                      inactiveColor: WakaColors.elevated,
                      onChanged: (value) {
                        setState(() => _fontSize = value);
                      },
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'A',
                      style: TextStyle(
                        color: WakaColors.mutedText,
                        fontSize: _fontSize + 4,
                      ),
                    ),
                    const SizedBox(width: 16),
                    GestureDetector(
                      onTap: () => setState(() {
                        if (_fontSize < 24) _fontSize += 2;
                      }),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: WakaColors.elevated,
                        ),
                        child: const Icon(
                          Icons.text_increase_rounded,
                          color: WakaColors.accent,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Progress bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Trang $_currentPage/$_totalPages',
                      style: const TextStyle(
                        color: WakaColors.mutedText,
                        fontSize: 12,
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: _currentPage / _totalPages,
                            minHeight: 4,
                            backgroundColor: WakaColors.elevated,
                            color: WakaColors.accent,
                          ),
                        ),
                      ),
                    ),
                    Text(
                      '${(_currentPage / _totalPages * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(
                        color: WakaColors.accent,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Navigation buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    GestureDetector(
                      onTap: () => setState(() {
                        if (_currentPage > 1) _currentPage--;
                      }),
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: WakaColors.elevated,
                        ),
                        child: const Icon(
                          Icons.arrow_back_rounded,
                          color: WakaColors.accent,
                          size: 22,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: WakaColors.elevated,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Trang $_currentPage',
                        style: const TextStyle(
                          color: WakaColors.text,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(() {
                        if (_currentPage < _totalPages) _currentPage++;
                      }),
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: WakaColors.elevated,
                        ),
                        child: const Icon(
                          Icons.arrow_forward_rounded,
                          color: WakaColors.accent,
                          size: 22,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
