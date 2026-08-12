import 'package:flutter/material.dart';

import '../models/notification.dart';
import '../services/notifications_service.dart';
import '../theme/app_theme.dart';

/// Écran Notifications — accessible depuis la cloche de l'Accueil.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _service = NotificationsService();
  List<AppNotification> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final items = await _service.list();
      if (!mounted) return;
      setState(() => _items = items);
    } catch (_) {
      // liste vide en cas d'échec réseau
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  IconData _iconFor(String type) {
    switch (type) {
      case 'alerte':
        return Icons.warning_amber_rounded;
      case 'signalement':
        return Icons.campaign_rounded;
      default:
        return Icons.info_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (_items.any((n) => !n.lu))
            TextButton(
              onPressed: () async {
                await _service.markAllRead();
                _load();
              },
              child: const Text('Tout marquer lu'),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? const Center(
                  child: Text('Aucune notification pour le moment.', style: TextStyle(color: AppColors.textSecondary)),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final n = _items[i];
                      return InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () async {
                          if (!n.lu) {
                            await _service.markRead(n.id);
                            _load();
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: n.lu ? AppColors.surface : AppColors.primary.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(_iconFor(n.type), color: AppColors.primary, size: 22),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(n.titre, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                    const SizedBox(height: 4),
                                    Text(n.message, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                                  ],
                                ),
                              ),
                              if (!n.lu)
                                Container(
                                  margin: const EdgeInsets.only(left: 8, top: 4),
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
