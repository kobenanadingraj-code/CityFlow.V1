"""
Journalise les alertes météo fortes/modérées dans dashboard.ActivityLog et
notifie les utilisateurs qui surveillent la zone concernée.

import_weather_history utilise bulk_create() pour l'historique (30 jours) —
ça ne déclenche pas post_save, donc pas de spam au premier import. Seuls les
WeatherEvent créés un par un (ex. saisie manuelle, future intégration API
météo live) déclenchent ce signal.
"""
from django.db.models.signals import post_save
from django.dispatch import receiver

from .models import WeatherEvent


@receiver(post_save, sender=WeatherEvent)
def _on_weather_event_created(sender, instance, created, **kwargs):
    if not created or instance.type == 'normal':
        return

    from accounts.models import ZoneSurveillee
    from dashboard.models import ActivityLog
    from notifications.models import Notification

    label = 'Pluie forte' if instance.type == 'pluie_forte' else 'Pluie modérée'

    ActivityLog.objects.create(
        type='alerte_declenchee',
        description=f"{label} — alerte météo déclenchée à {instance.zone}",
    )

    zones_surveillees = (
        ZoneSurveillee.objects.filter(zone__iexact=instance.zone).select_related('user')
    )
    notifs = [
        Notification(
            user=zs.user,
            type='alerte',
            titre=f"{label} à {instance.zone}",
            message=f"Une alerte météo ({label.lower()}) est active dans une zone que vous surveillez.",
            lien_objet=f'weather:{instance.id}',
        )
        for zs in zones_surveillees
    ]
    if notifs:
        Notification.objects.bulk_create(notifs)
