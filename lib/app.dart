import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'providers/app_provider.dart';
import 'screens/home_shell.dart';
import 'screens/login_screen.dart';
import 'theme/app_theme.dart';

class DeyaarApp extends StatelessWidget {
  const DeyaarApp({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    return MaterialApp(
      title: 'Deyaar Constructions',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: app.themeMode,
      home: const _RootGate(),
    );
  }
}

class _RootGate extends StatelessWidget {
  const _RootGate();

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    if (app.loading) return const AppSplashScreen();
    if (!app.unlocked) return const LoginScreen();
    return const HomeShell();
  }
}

/// Opening loader — matches loading.jpeg (dark splash + logo glow + version).
class AppSplashScreen extends StatelessWidget {
  const AppSplashScreen({super.key});

  static const _bg = AppColors.darkBg;
  static const _tagline = Color(0xFF8EB6FF);

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: _bg,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: _bg,
        body: SafeArea(
          child: SizedBox.expand(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Spacer(flex: 3),
                const _LogoGlow(),
                const SizedBox(height: 28),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'DEYAAR CONSTRUCTIONS',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                  ),
                ),
                const SizedBox(height: 8),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'BUILDING YOUR VISION',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _tagline,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      letterSpacing: 2.4,
                    ),
                  ),
                ),
                const SizedBox(height: 36),
                const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color: AppColors.primaryBlue,
                  ),
                ),
                const Spacer(flex: 4),
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Text(
                    'v1.0.0',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.55),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LogoGlow extends StatelessWidget {
  const _LogoGlow();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 168,
        height: 168,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.55),
              blurRadius: 42,
              spreadRadius: 10,
            ),
            BoxShadow(
              color: AppColors.primaryBlue.withValues(alpha: 0.22),
              blurRadius: 60,
              spreadRadius: 4,
            ),
          ],
        ),
        padding: const EdgeInsets.all(30),
        child: Image.asset(
          'assets/brand/logo.png',
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) => const Icon(
            Icons.apartment,
            size: 64,
            color: AppColors.navy,
          ),
        ),
      ),
    );
  }
}
