import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/api_client.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/cityflow_logo.dart';
import '../dashboard/dashboard_shell.dart';
import '../main_shell.dart';
import 'register_screen.dart';

/// Écran 3 — Bienvenue / Connexion (email ou téléphone).
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifiantCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _identifiantCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final auth = context.read<AuthService>();
      await auth.login(
        identifiant: _identifiantCtrl.text.trim(),
        motDePasse: _passwordCtrl.text,
      );
      if (!mounted) return;
      final isAutorite = auth.currentUser?.isAutorite ?? false;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => isAutorite ? const DashboardShell() : const MainShell()),
        (route) => false,
      );
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = 'Une erreur est survenue. Réessaie.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                const Center(child: CityFlowLogo(size: 72)),
                const SizedBox(height: 20),
                const Text(
                  'Bienvenue !',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Connectez-vous à votre compte',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 32),
                if (_error != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.accident.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(_error!, style: const TextStyle(color: AppColors.accident, fontSize: 13)),
                  ),
                  const SizedBox(height: 16),
                ],
                const Text('Email ou téléphone', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _identifiantCtrl,
                  decoration: const InputDecoration(hintText: 'exemple@mail.com'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Champ requis' : null,
                ),
                const SizedBox(height: 16),
                const Text('Mot de passe', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _passwordCtrl,
                  obscureText: _obscure,
                  decoration: InputDecoration(
                    hintText: '••••••••••',
                    suffixIcon: IconButton(
                      icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  validator: (v) => (v == null || v.isEmpty) ? 'Champ requis' : null,
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {},
                    child: const Text('Mot de passe oublié ?', style: TextStyle(color: AppColors.primary)),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const SizedBox(
                          width: 22, height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                        )
                      : const Text('Se connecter'),
                ),
                const SizedBox(height: 20),
                Center(
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(color: AppColors.textSecondary),
                      children: [
                        const TextSpan(text: "Vous n'avez pas de compte ? "),
                        TextSpan(
                          text: "S'inscrire",
                          style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
                          recognizer: (TapGestureRecognizer()
                            ..onTap = () => Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => const RegisterScreen()),
                                )),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
