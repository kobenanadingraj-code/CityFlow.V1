"""
exports.models — nouvelle app, nécessaire pour l'écran "Export des données"
(dashboard web) : configuration d'export (type/période/filtres/format) +
table "Exports récents" avec historique, taille, statut.

L'existant (dashboard.DashboardExportView) ne fait qu'un CSV brut des zones
critiques, sans configuration, sans Excel/PDF, sans historique — insuffisant
pour cet écran.
"""
from django.conf import settings
from django.db import models


class ExportJob(models.Model):
    TYPE_DONNEES_CHOICES = [
        ('signalements', 'Signalements'),
        ('utilisateurs', 'Utilisateurs'),
        ('alertes', 'Alertes'),
        ('statistiques', 'Statistiques'),
    ]
    FORMAT_CHOICES = [
        ('csv', 'CSV'),
        ('xlsx', 'Excel'),
        ('pdf', 'PDF'),
    ]
    STATUT_CHOICES = [
        ('en_cours', 'En cours'),
        ('termine', 'Terminé'),
        ('echec', 'Échec'),
    ]

    demande_par = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='exports')
    nom = models.CharField(max_length=150, blank=True)  # ex: "Signalements_Mai_2024"
    type_donnees = models.CharField(max_length=20, choices=TYPE_DONNEES_CHOICES)
    periode_debut = models.DateField()
    periode_fin = models.DateField()
    filtres = models.JSONField(default=dict, blank=True)  # type, statut, priorité, zone, source...
    format = models.CharField(max_length=5, choices=FORMAT_CHOICES)

    fichier = models.FileField(upload_to='exports/', blank=True, null=True)
    taille_octets = models.BigIntegerField(null=True, blank=True)
    statut = models.CharField(max_length=10, choices=STATUT_CHOICES, default='en_cours')

    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return f"Export {self.type_donnees} ({self.format}) — {self.statut}"
