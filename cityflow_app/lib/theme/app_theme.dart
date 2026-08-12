import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Palette CityFlow AI.
///
/// ⚠️ Couleurs approximées visuellement depuis les captures de la maquette
/// Figma ("2 eme maquette CityFlow") — je n'ai pas pu extraire les tokens
/// exacts (hex précis, échelle d'espacement) car l'extension Claude in
/// Chrome n'était pas connectée au moment de construire cet écran. Si tu as
/// accès aux tokens Figma (Inspect / mode Dev), remplace les valeurs
/// ci-dessous — tout le reste de l'app référence ces constantes, donc un
/// seul endroit à corriger.
class AppColors {
  AppColors._();

  // Identité — logo + boutons principaux
  static const Color primary = Color(0xFF4F46E5); // indigo/violet (logo, liens, accents)
  static const Color primaryDark = Color(0xFF1E1B4B); // sidebar dashboard, fond foncé
  static const Color success = Color(0xFF22C55E); // boutons CTA verts (Se connecter, Créer mon compte)
  static const Color successLight = Color(0xFFDCFCE7);

  // États de trafic / signalements — confirmés sur les captures de la
  // maquette fournies par l'utilisateur (légende carte + donut dashboard).
  static const Color accident = Color(0xFFEF4444); // rouge
  static const Color embouteillage = Color(0xFFF59E0B); // ambre/orange
  static const Color inondation = Color(0xFF3B82F6); // bleu (pas violet — corrigé)
  static const Color travaux = Color(0xFFEAB308); // doré/jaune, distinct de l'ambre

  static const Color trafficFluide = Color(0xFF22C55E);
  static const Color trafficModere = Color(0xFFF59E0B);
  static const Color trafficDense = Color(0xFFEF4444);
  static const Color trafficTresDense = Color(0xFF991B1B); // rouge foncé — distinct de 'Dense'

  // Neutres
  static const Color background = Color(0xFFF8F9FC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE5E7EB);
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textMuted = Color(0xFF9CA3AF);

  static Color typeColor(String type) {
    switch (type) {
      case 'accident':
        return accident;
      case 'embouteillage':
        return embouteillage;
      case 'inondation':
        return inondation;
      case 'travaux':
        return travaux;
      default:
        return textSecondary;
    }
  }

  static Color trafficColor(String niveau) {
    switch (niveau) {
      case 'très dense':
      case 'Très dense':
        return trafficTresDense;
      case 'dense':
      case 'Dense':
        return trafficDense;
      case 'modéré':
      case 'Modérée':
        return trafficModere;
      default:
        return trafficFluide;
    }
  }
}

class AppTheme {
  AppTheme._();

  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        surface: AppColors.surface,
      ),
      scaffoldBackgroundColor: AppColors.background,
    );

    return base.copyWith(
      // Inter via google_fonts : les 4 fichiers .ttf de la maquette n'étant
      // pas récupérables par cet outil (fichiers binaires), la police est
      // téléchargée et mise en cache au premier lancement plutôt que
      // bundlée localement. Remplace par des assets locaux + `fontFamily:
      // 'Inter'` si tu préfères une app 100% hors-ligne dès l'installation.
      textTheme: GoogleFonts.interTextTheme(base.textTheme).apply(
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: false,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.success,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          side: const BorderSide(color: AppColors.border),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.background,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        hintStyle: const TextStyle(color: AppColors.textMuted),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textMuted,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
      ),
    );
  }
}
