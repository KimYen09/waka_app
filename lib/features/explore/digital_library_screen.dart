import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class DigitalLibraryItem {
  const DigitalLibraryItem({
    required this.title,
    required this.imageUrl,
    this.badgeText,
    this.isRedBanner = false,
  });

  final String title;
  final String imageUrl;
  final String? badgeText;
  final bool isRedBanner;
}

class DigitalLibraryScreen extends StatelessWidget {
  const DigitalLibraryScreen({super.key});

  static const List<DigitalLibraryItem> _libraries = [
    DigitalLibraryItem(
      title: 'Tủ sách số thư viện Bắc Ninh số 2',
      imageUrl: 'https://images.unsplash.com/photo-1541339907198-e08756dedf3f?w=800',
      badgeText: 'BẮC NINH SỐ 2',
      isRedBanner: true,
    ),
    DigitalLibraryItem(
      title: 'Tủ sách trường THCS Lê Văn Thiêm',
      imageUrl: 'https://images.unsplash.com/photo-1562774053-701939374585?w=800',
      badgeText: 'THCS LÊ VĂN THIÊM',
    ),
    DigitalLibraryItem(
      title: 'Tủ sách Thư viện Thành phố Cần Thơ',
      imageUrl: 'https://images.unsplash.com/photo-1521587760476-6c12a4b040da?w=800',
      badgeText: 'THƯ VIỆN CẦN THƠ',
    ),
    DigitalLibraryItem(
      title: 'Thư viện điện tử Doanh Nghiệp',
      imageUrl: 'https://images.unsplash.com/photo-1522071820081-009f0129c71c?w=800',
      badgeText: 'DOANH NGHIỆP',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WakaColors.background,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E88E5),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Thư viện số 4.0',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          // SECTION 1: Thư viện của bạn (Khớp Ảnh 2)
          const Text(
            'Thư viện của bạn',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),

          // Thẻ Vega Group Tủ sách
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFE3F2FD), Color(0xFFE0F7FA)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFF90CAF9)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Top badge: Vega Group Tủ sách
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1976D2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.auto_awesome_rounded, color: Color(0xFFFFD54F), size: 16),
                      SizedBox(width: 6),
                      Text(
                        'Vega Group Tủ sách',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(width: 6),
                      Icon(Icons.auto_awesome_rounded, color: Color(0xFFFFD54F), size: 16),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Trích dẫn quote
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      '“',
                      style: TextStyle(
                        color: Color(0xFF81D4FA),
                        fontSize: 42,
                        fontWeight: FontWeight.w900,
                        height: 0.8,
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Đón đầu xu hướng, dẫn lối thành công',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF0D47A1),
                          fontSize: 16.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      '”',
                      style: TextStyle(
                        color: Color(0xFF81D4FA),
                        fontSize: 42,
                        fontWeight: FontWeight.w900,
                        height: 0.8,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  '««« XEM THÊM »»»',
                  style: TextStyle(
                    color: Color(0xFF0288D1),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 22),

                // Nút TRUY CẬP THƯ VIỆN >
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E88E5),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    elevation: 3,
                  ),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Đang mở Thư viện số Vega Group...'),
                        backgroundColor: Color(0xFF1976D2),
                      ),
                    );
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text(
                        'TRUY CẬP THƯ VIỆN',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 13.5,
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(width: 6),
                      Icon(Icons.chevron_right_rounded, size: 22),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Banner Bar: Tạo thư viện cho tổ chức của bạn? (Khớp Ảnh 2)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: WakaColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF00ACC1)),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Tạo thư viện cho tổ chức của bạn?',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00ACC1),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  onPressed: () {
                    showDialog<void>(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: WakaColors.surface,
                        title: const Text('Liên hệ Khởi tạo Thư viện Số 4.0',
                            style: TextStyle(color: Colors.white, fontSize: 18)),
                        content: const Text(
                          'Hotline tư vấn tổ chức & doanh nghiệp: 1900 545482\nEmail: thuvienso@waka.vn',
                          style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
                        ),
                        actions: [
                          TextButton(
                            child: const Text('Đóng', style: TextStyle(color: WakaColors.accent)),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),
                    );
                  },
                  child: const Text(
                    'Liên hệ ngay',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // SECTION 2: Danh sách thư viện (Khớp Ảnh 1 & 2)
          const Text(
            'Danh sách thư viện',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),

          ..._libraries.map((lib) => _buildLibraryCard(context, lib)),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildLibraryCard(BuildContext context, DigitalLibraryItem lib) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: WakaColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              Image.network(
                lib.imageUrl,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  height: 180,
                  color: lib.isRedBanner ? const Color(0xFFD32F2F) : const Color(0xFF1E88E5),
                  child: const Center(
                    child: Icon(Icons.school_rounded, color: Colors.white, size: 50),
                  ),
                ),
              ),
              if (lib.badgeText != null)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: lib.isRedBanner ? const Color(0xFFD32F2F) : const Color(0xFF1976D2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      lib.badgeText!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Text(
              lib.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
