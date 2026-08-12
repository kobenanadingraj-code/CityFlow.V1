import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/cityflow_logo.dart';
import 'auth/welcome_screen.dart';
import 'dashboard/dashboard_shell.dart';
import 'main_shell.dart';

/// Écran 1 — Splash.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final auth = context.read<AuthService>();
    final results = await Future.wait([
      auth.tryAutoLogin(),
      Future.delayed(const Duration(milliseconds: 1400)),
    ]);
    if (!mounted) return;
    final loggedIn = results[0] as bool;
    final isAutorite = auth.currentUser?.isAutorite ?? false;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => !loggedIn
            ? const WelcomeScreen()
            : (isAutorite ? const DashboardShell() : const MainShell()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Color(0xFFE9E7FB)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 2),
              const CityFlowLogo(size: 88),
              const SizedBox(height: 18),
              RichText(
                text: TextSpan(
                  style: GoogleFonts.inter(fontSize: 26, fontWeight: FontWeight.bold),
                  children: const [
                    TextSpan(text: 'CityFlow ', style: TextStyle(color: AppColors.textPrimary)),
                    TextSpan(text: 'AI', style: TextStyle(color: AppColors.primary)),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Déplacez-vous intelligent,\narrivez en toute sérénité.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.5),
              ),
              const Spacer(flex: 2),
              const _RouteIllustration(),
              const Spacer(),
              const _PageDots(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

/// Approximation de l'illustration 'ville + route + voiture' de la maquette —
/// je n'ai pas d'outil de génération d'image dans cet environnement, donc ceci
/// est construit avec des formes Flutter simples plutôt qu'un vrai asset
/// vectoriel. Remplace par la vraie illustration si tu l'as sous la main.
class _RouteIllustration extends StatelessWidget {
  const _RouteIllustration();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 140,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Positioned(
            left: 20,
            right: 20,
            bottom: 36,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _building(60, AppColors.primary.withValues(alpha: 0.18)),
                _building(90, AppColors.primary.withValues(alpha: 0.28)),
                _building(50, AppColors.primary.withValues(alpha: 0.15)),
                _building(75, AppColors.primary.withValues(alpha: 0.22)),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 24,
            child: Container(height: 10, color: AppColors.textPrimary.withValues(alpha: 0.85)),
          ),
          Positioned(
            bottom: 27,
            child: Row(
              children: List.generate(10, (i) => Container(width: 14, height: 3, margin: const EdgeInsets.symmetric(horizontal: 6), color: Colors.white)),
            ),
          ),
          const Positioned(
            bottom: 30,
            child: Icon(Icons.directions_car_filled_rounded, color: AppColors.success, size: 34),
          ),
        ],
      ),
    );
  }

  Widget _building(double height, Color color) {
    return Container(width: 34, height: height, decoration: BoxDecoration(color: color, borderRadius: const BorderRadius.vertical(top: Radius.circular(4))));
  }
}

class _PageDots extends StatelessWidget {
  const _PageDots();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(width: 22, height: 6, margin: const EdgeInsets.symmetric(horizontal: 3), decoration: BoxDecoration(color: AppColors.success, borderRadius: BorderRadius.circular(3))),
        Container(width: 6, height: 6, margin: const EdgeInsets.symmetric(horizontal: 3), decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(3))),
        Container(width: 6, height: 6, margin: const EdgeInsets.symmetric(horizontal: 3), decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(3))),
      ],
    );
  }
}
