"""
conseil.models — refonte alignée sur les écrans Trajet et Carte (app mobile).

État actuel (avant refonte) : `conseil/corridors.py` contient un dictionnaire
Python figé de 4 corridors (Cocody→Plateau, Adjamé→Plateau, etc.) avec des
listes de segments codées en dur. Aucun modèle en base.

Ce que la maquette demande en plus :
  - Écran Trajet : recherche libre "Où allez-vous ?" → 3 itinéraires proposés
    (recommandé / autre / alternatif) avec durée (min) ET distance (km) réelles
  - Écran Carte : "Itinéraires recommandés" avec des paires origine/destination
    qui peuvent être n'importe où (pas seulement les 4 corridors historiques)

⚠️ Limite technique à trancher avec toi : ni le predictor ML ni les segments
OSM importés ne donnent de distance/vitesse réelle par tronçon (le corridors.py
actuel le précise déjà : "Aucune durée en minutes n'est produite"). Pour des
durées/distances réalistes sur une recherche libre, il faut un moteur de
routing (OSRM auto-hébergé sur les données OSM déjà importées, ou une API
tierce). Sans ça, on peut afficher un niveau de trafic (fluide/modéré/dense)
mais pas un "32 min, 12.4 km" fiable.

En attendant cette décision, le modèle ci-dessous est pensé pour marcher dans
les deux cas : distance_km/duree_min sont nullable (renseignés si un moteur de
routing est branché), et le niveau de trafic est toujours calculable via les
segments + predict_congestion().
"""
from django.conf import settings
from django.db import models
from mobility.models import RoadSegment


class Itineraire(models.Model):
    TYPE_CHOICES = [
        ('recommande', 'Itinéraire recommandé'),
        ('alternatif', 'Itinéraire alternatif'),
        ('autre', 'Autre itinéraire'),
    ]

    # Si créé par recherche libre côté app, user est renseigné.
    # Si c'est un itinéraire "favori" pré-configuré (ex: Domicile → Travail
    # affiché sur l'écran Carte), is_predefini=True et user peut être null.
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.CASCADE,
        related_name='itineraires', null=True, blank=True,
    )
    is_predefini = models.BooleanField(default=False)

    origine_label = models.CharField(max_length=150)
    origine_lat = models.FloatField()
    origine_lng = models.FloatField()
    destination_label = models.CharField(max_length=150)
    destination_lat = models.FloatField()
    destination_lng = models.FloatField()

    type = models.CharField(max_length=15, choices=TYPE_CHOICES, default='recommande')
    segments = models.ManyToManyField(RoadSegment, through='ItineraireSegment', related_name='itineraires')

    # Renseignés uniquement si un moteur de routing externe est branché
    distance_km = models.FloatField(null=True, blank=True)
    duree_min = models.FloatField(null=True, blank=True)

    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return f"{self.origine_label} → {self.destination_label} ({self.get_type_display()})"


class ItineraireSegment(models.Model):
    """Ordre des segments qui composent un itinéraire (pour le tracé + le calcul de score)."""
    itineraire = models.ForeignKey(Itineraire, on_delete=models.CASCADE)
    segment = models.ForeignKey(RoadSegment, on_delete=models.CASCADE)
    ordre = models.PositiveIntegerField()

    class Meta:
        ordering = ['ordre']
        unique_together = ('itineraire', 'ordre')
