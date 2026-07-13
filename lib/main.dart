import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/theme/app_theme.dart';
import 'features/home/home_screen.dart';
import 'features/offers/offer_screen.dart';
import 'features/profile/profile_screen.dart';
import 'features/shop/shop_screen.dart';
import 'features/welcome/welcome_screen.dart';
import 'shared/widgets/waka_bottom_nav.dart';

void main() {
  runApp(const WakaDemoApp());
}

class WakaDemoApp extends StatelessWidget {
  const WakaDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Waka Demo',
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
    final pages = <Widget>[
      const HomeScreen(),
      const ShopScreen(),
      const OfferScreen(),
      const _ComingSoonScreen(title: 'Khám phá'),
      const _ComingSoonScreen(title: 'Thư viện'),
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

class _ComingSoonScreen extends StatelessWidget {
  const _ComingSoonScreen({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Text(title, style: Theme.of(context).textTheme.headlineMedium),
      ),
    );
  }
}
