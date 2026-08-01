import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/services/auth_api_service.dart';
import 'features/offer/offer_screen.dart';
import 'features/admin/admin_dashboard_screen.dart';
import 'core/theme/app_theme.dart';
import 'features/library/library_screen.dart';
import 'features/home/home_screen.dart';
import 'features/profile/profile_screen.dart';
import 'features/shop/shop_screen.dart';
import 'features/welcome/welcome_screen.dart';
import 'shared/widgets/waka_bottom_nav.dart';
import 'features/explore/explore_screen.dart';

void main() {
  runApp(const WakaDemoApp());
}

class WakaDemoApp extends StatelessWidget {
  const WakaDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Waka',
      theme: WakaTheme.dark,
      home: const WelcomeScreen(),
    );
  }
}

class WakaShell extends StatefulWidget {
  const WakaShell({super.key});

  @override
  State<WakaShell> createState() => _WakaShellState();
}

class _WakaShellState extends State<WakaShell> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    // Quyền được kiểm tra thêm tại shell để mọi luồng đăng nhập (mật khẩu,
    // Google, Facebook) đều không thể đưa quản trị viên về nhầm giao diện đọc.
    if (AuthSession.current?.user.isAdmin ?? false) {
      return const AdminDashboardScreen();
    }

    final pages = <Widget>[
      const HomeScreen(),
      const ShopScreen(),
      const OffersScreen(),
      const ExploreScreen(),
      const LibraryScreen(),

      const ProfileScreen(),
    ];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;

        if (_selectedIndex != 0) {
          setState(() => _selectedIndex = 0);
          return;
        }

        SystemNavigator.pop();
      },
      child: Scaffold(
        backgroundColor: WakaColors.background,
        body: IndexedStack(index: _selectedIndex, children: pages),
        bottomNavigationBar: WakaBottomNav(
          selectedIndex: _selectedIndex,
          onChanged: (index) => setState(() => _selectedIndex = index),
        ),
      ),
    );
  }
}
