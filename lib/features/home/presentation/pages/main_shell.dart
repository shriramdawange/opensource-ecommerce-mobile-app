import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/navigation/app_navigator.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../marketplace/presentation/pages/artbook_marketplace_page.dart';
import '../../../marketplace/presentation/pages/artbook_categories_page.dart';
import '../../../commerce/presentation/pages/artbook_cart_page.dart';
import '../../../account/presentation/pages/artbook_account_page.dart';

/// ArtBook's Supabase-backed application shell.
///
/// The legacy Bagisto screens remain in the repository for reference while
/// their features are migrated. The active tabs now use ArtBook repositories.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  static final GlobalKey<MainShellState> navigatorKey =
      GlobalKey<MainShellState>();

  @override
  State<MainShell> createState() => MainShellState();
}

class MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  final List<int> _tabHistory = [0];

  void switchToTab(int index) {
    if (index < 0 || index > 3 || index == _currentIndex) return;

    setState(() {
      if (_tabHistory.isEmpty || _tabHistory.last != _currentIndex) {
        _tabHistory.add(_currentIndex);
      }
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
          bottomNavigationBar: _buildBottomNav(context, isDark),
        ),
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context, bool isDark) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.neutral800 : AppColors.neutral50,
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.transparent : AppColors.neutral100,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                index: 0,
                icon: Icons.home_outlined,
                activeIcon: Icons.home,
                label: l10n.mainTabHome,
              ),
              _buildNavItem(
                index: 1,
                icon: Icons.grid_view_outlined,
                activeIcon: Icons.grid_view,
                label: l10n.mainTabCategories,
              ),
              _buildNavItem(
                index: 2,
                icon: Icons.shopping_cart_outlined,
                activeIcon: Icons.shopping_cart,
                label: l10n.mainTabCart,
              ),
              _buildNavItem(
                index: 3,
                icon: Icons.person_outline,
                activeIcon: Icons.person,
                label: l10n.mainTabAccount,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isActive = _currentIndex == index;

    return GestureDetector(
      onTap: () => switchToTab(index),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              size: 24,
              color: isActive
                  ? AppColors.primary500
                  : isDark
                      ? AppColors.neutral300
                      : AppColors.neutral800,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: isActive
                    ? AppColors.primary500
                    : isDark
                        ? AppColors.neutral300
                        : AppColors.neutral800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
