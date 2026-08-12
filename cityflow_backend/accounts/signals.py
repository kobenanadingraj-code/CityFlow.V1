"""
Journalise les inscriptions dans dashboard.ActivityLog.

Ne se déclenche que pour les créations via le endpoint d'inscription
(create_user), pas pour les utilisateurs de seed (bulk_create ne déclenche
pas post_save) — comportement voulu.
"""
from django.db.models.signals import post_save
from django.dispatch import receiver

from .models import User


@receiver(post_save, sender=User)
def _on_user_created(sender, instance, created, **kwargs):
    if not created or instance.role != 'citoyen':
        return
    from dashboard.models import ActivityLog
    ActivityLog.objects.create(
        type='utilisateur_inscrit',
        description=f"{instance.get_full_name() or instance.username} a rejoint CityFlow AI",
        user=instance,
    )
