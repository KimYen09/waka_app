import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import 'welcome_constants.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key, required this.onEnter});

  final ValueChanged<BuildContext> onEnter;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WakaColors.background,
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final scale = (constraints.maxHeight / WelcomeLayout.minScaleHeight)
                .clamp(WelcomeLayout.minScale, 1.0);
            final bottomInset = MediaQuery.paddingOf(context).bottom;

            return SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: WelcomeLayout.horizontalPadding,
                  ),
                  child: Column(
                    children: [
                      SizedBox(
                        height:
                            constraints.maxHeight *
                            WelcomeLayout.heroHeightFactor,
                        child: const _WelcomeHero(),
                      ),
                      SizedBox(height: WelcomeLayout.titleGap * scale),
                      _GradientTitle(scale: scale),
                      SizedBox(height: WelcomeLayout.descriptionGap * scale),
                      _WelcomeDescription(scale: scale),
                      SizedBox(height: WelcomeLayout.buttonTopGap * scale),
                      _PrimaryWelcomeButton(
                        onPressed: () => onEnter(context),
                        scale: scale,
                      ),
                      SizedBox(height: WelcomeLayout.buttonGap * scale),
                      _SecondaryWelcomeButton(
                        onPressed: () => onEnter(context),
                        scale: scale,
                      ),
                      SizedBox(height: bottomInset + WelcomeLayout.bottomGap),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _WelcomeHero extends StatelessWidget {
  const _WelcomeHero();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0.05, -0.1),
                radius: 0.8,
                colors: [
                  const Color(0xFF273723).withValues(alpha: 0.24),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Image.asset(
            'assets/images/welcome_books.jpg',
            width: double.infinity,
            fit: BoxFit.contain,
          ),
        ),
      ],
    );
  }
}

class _GradientTitle extends StatelessWidget {
  const _GradientTitle({required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) => const LinearGradient(
        colors: [Color(0xFF09BFD0), Color(0xFF28C08E), Color(0xFFD6B319)],
      ).createShader(bounds),
      child: Text(
        'CHÀO MỪNG BẠN ĐẾN VỚI\nWAKA',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white,
          fontSize: WelcomeFontSizes.title * scale,
          fontWeight: FontWeight.w900,
          height: 1.18,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class _WelcomeDescription extends StatelessWidget {
  const _WelcomeDescription({required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context) {
    return Text(
      'Hơn 20000+ tựa sách bản quyền đa\n'
      'dạng thể loại, hình thức từ sách điện tử,\n'
      'sách nói, sách giấy đến sách tương tác',
      textAlign: TextAlign.center,
      style: TextStyle(
        color: Colors.white,
        fontSize: WelcomeFontSizes.description * scale,
        fontWeight: FontWeight.w400,
        height: 1.36,
        letterSpacing: 0,
      ),
    );
  }
}

class _PrimaryWelcomeButton extends StatelessWidget {
  const _PrimaryWelcomeButton({required this.onPressed, required this.scale});

  final VoidCallback onPressed;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return _WelcomeButtonFrame(
      onPressed: onPressed,
      height: WelcomeLayout.primaryButtonHeight * scale,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(40),
        gradient: const LinearGradient(
          colors: [Color(0xFF14F45D), Color(0xFF1CBBA8), Color(0xFF2730C8)],
        ),
      ),
      child: Text(
        'ĐĂNG KÝ ĐỂ NHẬN QUÀ',
        maxLines: 1,
        style: TextStyle(
          color: Colors.white,
          fontSize: WelcomeFontSizes.primaryButton * scale,
          fontWeight: FontWeight.w900,
          height: 1,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class _SecondaryWelcomeButton extends StatelessWidget {
  const _SecondaryWelcomeButton({required this.onPressed, required this.scale});

  final VoidCallback onPressed;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        height: WelcomeLayout.secondaryButtonHeight * scale,
        width: double.infinity,
        child: CustomPaint(
          painter: const _LoginButtonBorderPainter(),
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                'ĐĂNG NHẬP',
                maxLines: 1,
                style: TextStyle(
                  color: WakaColors.accent,
                  fontSize: WelcomeFontSizes.secondaryButton * scale,
                  fontWeight: FontWeight.w900,
                  height: 1,
                  letterSpacing: 0,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LoginButtonBorderPainter extends CustomPainter {
  const _LoginButtonBorderPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      (Offset.zero & size).deflate(1),
      Radius.circular(size.height / 2),
    );
    final paint = Paint()
      ..color = WakaColors.accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.35
      ..isAntiAlias = true;

    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _WelcomeButtonFrame extends StatelessWidget {
  const _WelcomeButtonFrame({
    required this.onPressed,
    required this.height,
    required this.decoration,
    required this.child,
  });

  final VoidCallback onPressed;
  final double height;
  final BoxDecoration decoration;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: height,
        width: double.infinity,
        decoration: decoration,
        child: Center(
          child: FittedBox(fit: BoxFit.scaleDown, child: child),
        ),
      ),
    );
  }
}
