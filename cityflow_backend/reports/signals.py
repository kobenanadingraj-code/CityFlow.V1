"""
Peuple automatiquement dashboard.ActivityLog et notifications.Notification
quand un Report est créé ou passe à 'resolu'.

Imports de dashboard/notifications/accounts faits à l'intérieur des
fonctions (pas en haut du fichier) pour éviter tout souci d'ordre de
chargement des apps au démarrage de Django.

Note : les créations en masse via bulk_create() (seed_demo_reports, etc.) ne
déclenchent PAS ces signaux (comportement Django standard) — c'est voulu,
pour ne pas noyer l'activité récente / les notifications sous des centaines
d'entrées de seed.
"""
from django.db.models.signals import post_save, pre_save
from django.dispatch import receiver

from .models import Report


@receiver(pre_save, sender=Report)
def _stash_previous_statut(sender, instance, **kwargs):
    if instance.pk:
        try:
            instance._previous_statut = Report.objects.only('statut').get(pk=instance.pk).statut
        except Report.DoesNotExist:
            instance._previous_statut = None
    else:
        instance._previous_statut = None


@receiver(post_save, sender=Report)
def _on_report_saved(sender, instance, created, **kwargs):
    from accounts.models import ZoneSurveillee
    from dashboard.models import ActivityLog
    from notifications.models import Notification

    if created:
        ActivityLog.objects.create(
            type='signalement_cree',
            description=f"{instance.get_type_display()} signalé à {instance.zone}",
            user=instance.user,
        )

        # Notifie les utilisateurs qui surveillent cette zone (hors auteur du signalement)
        zones_surveillees = (
            ZoneSurveillee.objects
            .filter(zone__iexact=instance.zone)
            .exclude(user=instance.user)
            .select_related('user')
        )
        notifs = [
            Notification(
                user=zs.user,
                type='alerte',
                titre='Nouveau signalement dans une zone surveillée',
                message=f"{instance.get_type_display()} signalé à {instance.zone}.",
                lien_objet=f'report:{instance.id}',
            )
            for zs in zones_surveillees
        ]
        if notifs:
            Notification.objects.bulk_create(notifs)
        return

    # Passage à 'resolu' (comparé à l'état avant sauvegarde, voir _stash_previous_statut)
    previous = getattr(instance, '_previous_statut', None)
    if previous is not None and previous != 'resolu' and instance.statut == 'resolu':
        ActivityLog.objects.create(
            type='incident_resolu',
            description=f"{instance.get_type_display()} résolu à {instance.zone}",
            user=instance.user,
        )
        Notification.objects.create(
            user=instance.user,
            type='signalement',
            titre='Votre signalement a été résolu',
            message=f"Le signalement « {instance.get_type_display()} — {instance.zone} » est marqué résolu.",
            lien_objet=f'report:{instance.id}',
        )
