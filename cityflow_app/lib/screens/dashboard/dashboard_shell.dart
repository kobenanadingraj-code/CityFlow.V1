import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/cityflow_logo.dart';
import '../auth/welcome_screen.dart';
import 'alerts_management_screen.dart';
import 'dashboard_home_screen.dart';
import 'exports_screen.dart';
import 'parametres_screen.dart';
import 'reports_management_screen.dart';
import 'statistiques_screen.dart';
import 'utilisateurs_screen.dart';

/// Coquille du dashboard web (autorités) — navigation latérale +
/// Tableau de bord / Gestion des signalements / Export des données.
class DashboardShell extends StatefulWidget {
  const DashboardShell({super.key});

  @override
  State<DashboardShell> createState() => _DashboardShellState();
}

class _DashboardShellState extends State<DashboardShell> {
  int _index = 0;

  static const _screens = [
    DashboardHomeScreen(),
    ReportsManagementScreen(),
    AlertsManagementScreen(),
    UtilisateursScreen(),
    StatistiquesScreen(),
    ExportsScreen(),
    ParametresScreen(),
  ];

  static const _labels = ['Tableau de bord', 'Signalements', 'Alertes', 'Utilisateurs', 'Statistiques', 'Export des données', 'Paramètres'];
  static const _icons = [
    Icons.dashboard_rounded,
    Icons.report_rounded,
    Icons.warning_amber_rounded,
    Icons.people_alt_rounded,
    Icons.bar_chart_rounded,
    Icons.file_download_rounded,
    Icons.settings_rounded,
  ];

  Future<void> _logout() async {
    await context.read<AuthService>().logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().currentUser;
    final wide = MediaQuery.of(context).size.width >= 900;

    final sidebar = Container(
      width: 240,
      color: AppColors.primaryDark,
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 24),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CityFlowLogo(size: 36),
                SizedBox(width: 10),
                Text('CityFlow AI', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 32),
            for (var i = 0; i < _labels.length; i++)
              _SidebarItem(
                icon: _icons[i],
                label: _labels[i],
                selected: _index == i,
                onTap: () => setState(() => _index = i),
              ),
            const Spacer(),
            const Divider(color: Colors.white24, height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const CircleAvatar(radius: 16, backgroundColor: AppColors.primary, child: Icon(Icons.person, color: Colors.white, size: 16)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      user?.nomComplet ?? 'Autorité',
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.logout_rounded, color: Colors.white70, size: 18),
                    onPressed: _logout,
                    tooltip: 'Déconnexion',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: wide ? null : Drawer(child: sidebar),
      appBar: wide
          ? null
          : AppBar(title: Text(_labels[_index]), backgroundColor: AppColors.surface, foregroundColor: AppColors.textPrimary),
      body: Row(
        children: [
          if (wide) sidebar,
          Expanded(
            child: Column(
              children: [
                if (wide) _TopHeader(user: user, onLogout: _logout),
                Expanded(child: _screens[_index]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TopHeader extends StatelessWidget {
  final dynamic user;
  final VoidCallback onLogout;
  const _TopHeader({required this.user, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('d MMMM yyyy', 'fr_FR').format(DateTime.now());
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.calendar_today_rounded, size: 14, color: AppColors.textMuted),
                const SizedBox(width: 8),
                Text(date, style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          PopupMenuButton<String>(
            offset: const Offset(0, 44),
            onSelected: (v) {
              if (v == 'logout') onLogout();
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'logout', child: Text('Se déconnecter')),
            ],
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircleAvatar(radius: 16, backgroundColor: AppColors.primary, child: Icon(Icons.person, color: Colors.white, size: 16)),
                const SizedBox(width: 8),
                Text(user?.nomComplet ?? 'Admin', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                const Icon(Icons.expand_more_rounded, size: 18, color: AppColors.textMuted),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SidebarItem({required this.icon, required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: Material(
        color: selected ? Colors.white.withValues(alpha: 0.08) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(icon, color: selected ? Colors.white : Colors.white60, size: 19),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(color: selected ? Colors.white : Colors.white60, fontSize: 13, fontWeight: selected ? FontWeight.w600 : FontWeight.normal),
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
