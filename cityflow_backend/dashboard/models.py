"""
dashboard.models — le dashboard actuel n'a AUCUN modèle propre (tout est
recalculé à la volée depuis mobility/reports/environment). Ça suffisait pour
3 endpoints simples (critical-zones, stats, export CSV) mais pas pour l'écran
"Tableau de bord" de la maquette, qui affiche des variations ("+12% vs hier")
sur 4 KPIs. Recalculer une variation "vs hier" à chaque chargement de page en
comptant tout l'historique serait lent en prod — d'où ce snapshot quotidien.

  - DailySnapshot : 1 ligne/jour, remplie par une tâche planifiée (management
    command à lancer via cron, ex. `recompute_daily_snapshot`), sert de base
    de comparaison pour les KPIs du Tableau de bord.
  - ActivityLog : flux "Activité récente" (Tableau de bord) et "Exports
    récents" (Export des données) — évènements bruts, pas de recalcul.
"""
from django.conf import settings
from django.db import models


class DailySnapshot(models.Model):
    date = models.DateField(unique=True)
    signalements_jour = models.IntegerField(default=0)
    incidents_actifs = models.IntegerField(default=0)
    zones_a_risque = models.IntegerField(default=0)
    utilisateurs_actifs = models.IntegerField(default=0)

    class Meta:
        ordering = ['-date']

    def __str__(self):
        return f"Snapshot {self.date}"


class ActivityLog(models.Model):
    """Alimente le flux 'Activité récente' du Tableau de bord."""
    TYPE_CHOICES = [
        ('signalement_cree', 'Nouveau signalement ajouté'),
        ('utilisateur_inscrit', 'Utilisateur inscrit'),
        ('alerte_declenchee', 'Alerte déclenchée'),
        ('incident_resolu', 'Incident résolu'),
    ]

    type = models.CharField(max_length=30, choices=TYPE_CHOICES)
    description = models.CharField(max_length=255)
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, blank=True,
        related_name='activites',
    )
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return f"{self.get_type_display()} — {self.created_at:%d/%m %H:%M}"
