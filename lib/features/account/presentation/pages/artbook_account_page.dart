import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../artisan/presentation/pages/artisan_listings_page.dart';
import '../../../artisan/presentation/pages/artisan_onboarding_page.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/pages/login_page.dart';
import '../../../auth/presentation/pages/sign_up_page.dart';

class ArtBookAccountPage extends StatelessWidget {
  const ArtBookAccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.neutral900 : const Color(0xFFFAF7F1),
      appBar: AppBar(
        title: const Text('Your ArtBook'),
        backgroundColor: isDark ? AppColors.neutral900 : const Color(0xFFFAF7F1),
      ),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is AuthLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is! AuthAuthenticated) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE9D8C5),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Icon(Icons.person_outline, size: 38, color: Color(0xFF6F3E2B)),
                    ),
                    const SizedBox(height: 16),
                    const Text('Welcome to ArtBook', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 8),
                    const Text(
                      'Sign in to manage your orders, build your artisan identity and publish your creations.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF8B735F), height: 1.4),
                    ),
                    if (state is AuthError) ...[
                      const SizedBox(height: 12),
                      Text(state.message, style: const TextStyle(color: Colors.red)),
                    ],
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const SignUpPage()),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF6F3E2B),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                        ),
                        child: const Text('Create account'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const LoginPage()),
                        ),
                        child: const Text('Sign in'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(18),
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFF4B2B20),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 25,
                      backgroundColor: Color(0xFFE9D8C5),
                      child: Icon(Icons.person, color: Color(0xFF6F3E2B), size: 28),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            state.userName ?? 'ArtBook User',
                            style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 3),
                          Text(state.userEmail ?? '', style: const TextStyle(color: Color(0xFFE9D8C5), fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              _menuTile(
                context,
                icon: Icons.storefront_outlined,
                title: 'Artisan profile',
                subtitle: 'Tell buyers who you are and where your craft comes from',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ArtisanOnboardingPage()),
                ),
              ),
              const SizedBox(height: 10),
              _menuTile(
                context,
                icon: Icons.inventory_2_outlined,
                title: 'My product listings',
                subtitle: 'Create drafts, upload photos and request publication',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ArtisanListingsPage()),
                ),
              ),
              const SizedBox(height: 10),
              _menuTile(
                context,
                icon: Icons.receipt_long_outlined,
                title: 'My orders',
                subtitle: 'Order history and artisan order requests are coming next',
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Order history is being connected to ArtBook.')),
                ),
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () => context.read<AuthBloc>().add(const AuthLogoutRequested()),
                icon: const Icon(Icons.logout),
                label: const Text('Sign out'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF8B3E30),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _menuTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Theme.of(context).brightness == Brightness.dark ? AppColors.neutral800 : Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFE9D8C5),
          child: Icon(icon, color: const Color(0xFF6F3E2B)),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 11)),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
