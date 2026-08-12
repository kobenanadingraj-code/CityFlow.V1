import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/api_client.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/cityflow_logo.dart';
import '../main_shell.dart';

/// Écran 2 — Créer un compte.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _telCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscure1 = true;
  bool _obscure2 = true;
  bool _loading = false;
  bool _accepteConditions = false;
  String? _error;

  @override
  void dispose() {
    _nomCtrl.dispose();
    _emailCtrl.dispose();
    _telCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_accepteConditions) {
      setState(() => _error = "Merci d'accepter les conditions d'utilisation et la politique de confidentialité.");
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await context.read<AuthService>().register(
            nomComplet: _nomCtrl.text.trim(),
            email: _emailCtrl.text.trim(),
            telephone: _telCtrl.text.trim().isEmpty ? null : _telCtrl.text.trim(),
            motDePasse: _passwordCtrl.text,
          );
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainShell()),
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
      appBar: AppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Center(child: CityFlowLogo(size: 64)),
                const SizedBox(height: 16),
                const Text(
                  'Créer un compte',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Rejoignez CityFlow AI et simplifiez\nvos déplacements.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 24),
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
                const _FieldLabel('Nom complet'),
                TextFormField(
                  controller: _nomCtrl,
                  decoration: const InputDecoration(hintText: 'Votre nom'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Champ requis' : null,
                ),
                const SizedBox(height: 14),
                const _FieldLabel('Email'),
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(hintText: 'exemple@mail.com'),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Champ requis';
                    if (!v.contains('@')) return 'Email invalide';
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                const _FieldLabel('Téléphone'),
                TextFormField(
                  controller: _telCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(hintText: '07 00 00 00 00'),
                ),
                const SizedBox(height: 14),
                const _FieldLabel('Mot de passe'),
                TextFormField(
                  controller: _passwordCtrl,
                  obscureText: _obscure1,
                  decoration: InputDecoration(
                    hintText: '••••••••••',
                    suffixIcon: IconButton(
                      icon: Icon(_obscure1 ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                      onPressed: () => setState(() => _obscure1 = !_obscure1),
                    ),
                  ),
                  validator: (v) => (v == null || v.length < 8) ? '8 caractères minimum' : null,
                ),
                const SizedBox(height: 14),
                const _FieldLabel('Confirmer le mot de passe'),
                TextFormField(
                  controller: _confirmCtrl,
                  obscureText: _obscure2,
                  decoration: InputDecoration(
                    hintText: '••••••••••',
                    suffixIcon: IconButton(
                      icon: Icon(_obscure2 ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                      onPressed: () => setState(() => _obscure2 = !_obscure2),
                    ),
                  ),
                  validator: (v) => v != _passwordCtrl.text ? 'Les mots de passe ne correspondent pas' : null,
                ),
                const SizedBox(height: 18),
                InkWell(
                  onTap: () => setState(() => _accepteConditions = !_accepteConditions),
                  borderRadius: BorderRadius.circular(8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Checkbox(
                        value: _accepteConditions,
                        activeColor: AppColors.success,
                        onChanged: (v) => setState(() => _accepteConditions = v ?? false),
                      ),
                      const Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(top: 14),
                          child: Text.rich(
                            TextSpan(
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5, height: 1.4),
                              children: [
                                TextSpan(text: "J'accepte les "),
                                TextSpan(text: "Conditions d'utilisation", style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
                                TextSpan(text: ' et la '),
                                TextSpan(text: 'Politique de confidentialité', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const SizedBox(
                          width: 22, height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                        )
                      : const Text('Créer mon compte'),
                ),
                const SizedBox(height: 16),
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text.rich(
                      TextSpan(
                        style: TextStyle(color: AppColors.textSecondary),
                        children: [
                          TextSpan(text: 'Déjà un compte ? '),
                          TextSpan(text: 'Se connecter', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
    );
  }
}
