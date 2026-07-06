import 'package:flutter/material.dart';

class AuthBackground extends StatelessWidget {
  const AuthBackground({super.key});

  // 🌟 CHỖ ĐỂ ÔNG BỎ LINK ẢNH TRÊN MẠNG VÀO NÈ 🌟
  // Tui đã để sẵn vài link ảnh bìa sách thật để ông test,
  // Ông cứ copy link ảnh sách trên Google rồi thay thế vào trong ngoặc kép '' là được.
  static const List<String> networkCovers = [
    'https://images.unsplash.com/photo-1544947950-fa07a98d237f?q=80&w=600', // Đắc nhân tâm (Minh họa)
    'https://images.unsplash.com/photo-1589829085413-56de8ae18c73?q=80&w=600',
    'https://images.unsplash.com/photo-1629196914959-7157efd4cbf7?q=80&w=600',
    'https://images.unsplash.com/photo-1614113489855-66422ad300a4?q=80&w=600',
    'https://images.unsplash.com/photo-1532012197267-da84d127e765?q=80&w=600',
    'https://images.unsplash.com/photo-1512820790803-83ca734da794?q=80&w=600',
    'https://images.unsplash.com/photo-1589998059171-988d887df646?q=80&w=600',
    'https://images.unsplash.com/photo-1543002588-bfa74002ed7e?q=80&w=600',
  ];

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // LỚP 1: LƯỚI ẢNH BÌA SÁCH (Lấy từ mạng)
        GridView.builder(
          physics: const NeverScrollableScrollPhysics(), // Không cho cuộn nền
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4, // 4 cột ảnh
            childAspectRatio: 0.68,
          ),
          itemCount: networkCovers.length * 4, // Lặp lại ảnh cho đầy màn hình
          itemBuilder: (context, index) {
            final url = networkCovers[index % networkCovers.length];
            return Container(
              margin: const EdgeInsets.all(2),
              color: const Color(0xFF2C2C2C), // Màu chờ khi load ảnh mạng
              child: Image.network(
                url,
                fit: BoxFit.cover,
                // Hiệu ứng xoay tròn lúc đang tải ảnh trên mạng về
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Colors.white24,
                      strokeWidth: 2,
                    ),
                  );
                },
                // Nếu link ảnh bị lỗi/chết thì hiện màu xám
                errorBuilder: (context, error, stackTrace) =>
                    Container(color: const Color(0xFF2C2C2C)),
              ),
            );
          },
        ),

        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  // 🌟 Đã giảm độ đen ở phần trên và giữa để ảnh sáng hơn
                  Colors.black.withValues(alpha: 0.15),
                  Colors.black.withValues(alpha: 0.55),
                  Colors.black.withValues(alpha: 0.95),
                ],
                stops: const [
                  0.0,
                  0.5,
                  0.95,
                ], // Đẩy phần đen thui tụt hẳn xuống dưới đáy
              ),
            ),
          ),
        ),
      ],
    );
  }
}
