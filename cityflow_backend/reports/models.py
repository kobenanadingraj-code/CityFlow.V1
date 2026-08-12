"""
reports.models — refonte alignée sur les écrans Figma :
  - Alertes (app mobile) : filtres Toutes/Accidents/Inondations/Travaux
  - Gestion des signalements (dashboard web) : table avec type/statut/priorité/date

Changements vs version actuelle :
  - TYPE_CHOICES remplacé : accident / embouteillage / inondation / travaux / autre
    (avant : accident / nid_de_poule / route_barree / vehicule_en_panne — ne
    correspondait à aucune icône de la maquette)
  - `gravite` renommé `priorite`, valeurs Élevée/Moyenne/Faible (avant :
    faible/moyen/critique)
  - STATUT_CHOICES remplacé : nouveau / en_cours / resolu / en_attente
    (avant : actif / fusionne / resolu — ne correspondait pas aux filtres du
    dashboard "Tous les statuts")
  - + description, adresse (texte affiché "Yopougon, à 500 m" dans la maquette)
  - + photo (les signalements citoyens incluent souvent une preuve photo)
  - `segment` devient optionnel : un signalement peut être créé par
    lat/lng libres (recherche "Où allez-vous ?") sans être rattaché à un
    RoadSegment connu
"""
from django.conf import settings
from django.db import models
from mobility.models import RoadSegment

PRIORITE_PAR_TYPE = {
    'accident': 'elevee',
    'inondation': 'elevee',
    'embouteillage': 'moyenne',
    'travaux': 'faible',
    'autre': 'faible',
}


def classify_priority(type_incident):
    return PRIORITE_PAR_TYPE.get(type_incident, 'moyenne')


class Report(models.Model):
    TYPE_CHOICES = [
        ('accident', 'Accident'),
        ('embouteillage', 'Embouteillage'),
        ('inondation', 'Route inondée'),
        ('travaux', 'Travaux en cours'),
        ('autre', 'Autre'),
    ]
    PRIORITE_CHOICES = [
        ('elevee', 'Élevée'),
        ('moyenne', 'Moyenne'),
        ('faible', 'Faible'),
    ]
    STATUT_CHOICES = [
        ('nouveau', 'Nouveau'),
        ('en_cours', 'En cours'),
        ('resolu', 'Résolu'),
        ('en_attente', 'En attente'),
    ]

    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='reports')
    segment = models.ForeignKey(
        RoadSegment, on_delete=models.CASCADE, related_name='reports', null=True, blank=True
    )
    zone = models.CharField(max_length=100, db_index=True)
    adresse = models.CharField(max_length=255, blank=True)
    latitude = models.FloatField(null=True, blank=True)
    longitude = models.FloatField(null=True, blank=True)

    type = models.CharField(max_length=20, choices=TYPE_CHOICES)
    description = models.TextField(blank=True)
    photo = models.ImageField(upload_to='reports/', blank=True, null=True)

    priorite = models.CharField(max_length=10, choices=PRIORITE_CHOICES, default='moyenne')
    statut = models.CharField(max_length=10, choices=STATUT_CHOICES, default='nouveau')
    nb_confirmations = models.IntegerField(default=1)

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-created_at']
        indexes = [models.Index(fields=['type', 'statut']), models.Index(fields=['zone'])]

    def __str__(self):
        return f"Report {self.type} {self.zone} ({self.statut})"
