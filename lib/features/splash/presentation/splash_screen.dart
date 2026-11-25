import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

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
      backgroundColor: AppColors.white,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 124,
              height: 124,
              child: SvgPicture.asset(
                'assets/branding/darsh_mascot.svg',
                fit: BoxFit.contain,
                semanticsLabel: 'DARSH mascot',
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'DARSH',
              style: TextStyle(
                color: AppColors.neutral900,
                fontSize: 27,
                fontWeight: FontWeight.w800,
                letterSpacing: 2.4,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 7),
            const Text(
              'Creativity has no limits.',
              style: TextStyle(
                color: AppColors.neutral500,
                fontSize: 13,
                letterSpacing: 0.25,
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
