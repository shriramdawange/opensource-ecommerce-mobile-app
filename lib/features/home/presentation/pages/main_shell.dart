import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/navigation/app_navigator.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../marketplace/presentation/pages/artbook_marketplace_page.dart';
import '../../../marketplace/presentation/pages/artbook_categories_page.dart';
import '../../../commerce/presentation/pages/artbook_cart_page.dart';
import '../../../account/presentation/pages/artbook_account_page.dart';

/// ArtBook's Supabase-backed application shell.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  static final GlobalKey<MainShellState> navigatorKey = GlobalKey<MainShellState>();

  @override
  State<MainShell> createState() => MainShellState();
}

class MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  final List<int> _tabHistory = [0];

  static const _clay = Color(0xFF9A4F36);

  void switchToTab(int index) {
    if (index < 0 || index > 3 || index == _currentIndex) return;
    setState(() {
      if (_tabHistory.isEmpty || _tabHistory.last != _currentIndex) _tabHistory.add(_currentIndex);
      _currentIndex = index;
    });
  }

  int get currentTab => _currentIndex;

  Future<bool> _onWillPop() async {
    if (_tabHistory.isNotEmpty) {
      final previousTab = _tabHistory.removeLast();
      setState(() => _currentIndex = previousTab);
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    // ignore: deprecated_member_use
    return WillPopScope(
      onWillPop: _onWillPop,
      child: AppNavigator(
        switchToTab: switchToTab,
        currentTab: () => _currentIndex,
        child: Scaffold(
          body: IndexedStack(
            index: _currentIndex,
            children: const [
              ArtBookMarketplacePage(),
              ArtBookCategoriesPage(),
              ArtBookCartPage(),
              ArtBookAccountPage(),
            ],
          ),
          bottomNavigationBar: _buildBottomNav(context),
        ),
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    final surface = isDark ? AppColors.neutral800 : Colors.white;
    final inactive = isDark ? Colors.white60 : const Color(0xFF898176);
    final items = [
      (Icons.storefront_outlined, Icons.storefront_rounded, l10n.mainTabHome),
      (Icons.grid_view_outlined, Icons.grid_view_rounded, l10n.mainTabCategories),
      (Icons.shopping_bag_outlined, Icons.shopping_bag_rounded, l10n.mainTabCart),
      (Icons.person_outline_rounded, Icons.person_rounded, l10n.mainTabAccount),
    ];

    return Container(
      decoration: BoxDecoration(
        color: surface,
        border: Border(top: BorderSide(color: isDark ? AppColors.neutral700 : const Color(0xFFECE5DA))),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0 : .045), blurRadius: 18, offset: const Offset(0, -5))],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(9, 8, 9, 5),
          child: Row(
            children: List.generate(items.length, (index) {
              final active = _currentIndex == index;
              final item = items[index];
              return Expanded(
                child: Semantics(
                  button: true,
                  selected: active,
                  label: item.$3,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => switchToTab(index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOut,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      padding: const EdgeInsets.symmetric(vertical: 7),
                      decoration: BoxDecoration(
                        color: active ? _clay.withValues(alpha: .10) : Colors.transparent,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Icon(active ? item.$2 : item.$1, size: 22, color: active ? _clay : inactive),
                        const SizedBox(height: 3),
                        Text(item.$3, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 10, fontWeight: active ? FontWeight.w800 : FontWeight.w500, color: active ? _clay : inactive)),
                      ]),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
