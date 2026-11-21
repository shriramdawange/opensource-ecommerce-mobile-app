import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  final Widget nextScreen;

  const SplashScreen({super.key, required this.nextScreen});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    Future.delayed(const Duration(milliseconds: 1400), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => widget.nextScreen),
      );
    });
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F1),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: const Color(0xFF6F3E2B),
                borderRadius: BorderRadius.circular(26),
              ),
              child: const Icon(
                Icons.auto_awesome,
                color: Color(0xFFFFE8C9),
                size: 44,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'ARTBOOK',
              style: TextStyle(
                color: Color(0xFF4B2B20),
                fontSize: 25,
                fontWeight: FontWeight.w900,
                letterSpacing: 3.2,
              ),
            ),
            const SizedBox(height: 7),
            const Text(
              'Stories made by hand',
              style: TextStyle(
                color: Color(0xFF8B735F),
                fontSize: 13,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 28),
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
