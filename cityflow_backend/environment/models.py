"""
environment.models — refonte alignée sur l'écran Accueil (app mobile) :
  "Météo : 28°C, Ensoleillé"

Changements vs version actuelle :
  - + condition (Ensoleillé/Nuageux/Pluvieux/Orageux) : label d'affichage
    grand public, distinct de `type` qui reste le signal utilisé par le
    predictor ML (impact congestion, pluie uniquement)
  - + temperature (°C) : affichée telle quelle sur l'écran Accueil
  - `type`/`intensite`/`source` inchangés — ne pas casser predictor.py
"""
from django.db import models


class WeatherEvent(models.Model):
    TYPE_CHOICES = [
        ('normal', 'Normal'),
        ('pluie_moderee', 'Pluie modérée'),
        ('pluie_forte', 'Pluie forte'),
    ]
    CONDITION_CHOICES = [
        ('ensoleille', 'Ensoleillé'),
        ('nuageux', 'Nuageux'),
        ('pluvieux', 'Pluvieux'),
        ('orageux', 'Orageux'),
    ]
    SOURCE_CHOICES = [('historique_reel', 'Historique réel'), ('manuel', 'Manuel')]

    zone = models.CharField(max_length=100)
    type = models.CharField(max_length=20, choices=TYPE_CHOICES, default='normal')
    condition = models.CharField(max_length=20, choices=CONDITION_CHOICES, default='ensoleille')
    temperature = models.FloatField(default=27.0)
    intensite = models.FloatField()
    timestamp = models.DateTimeField()
    source = models.CharField(max_length=20, choices=SOURCE_CHOICES, default='manuel')

    class Meta:
        ordering = ['-timestamp']

    def __str__(self):
        return f"Météo {self.zone} {self.type} @ {self.timestamp}"


def get_active_weather(zone):
    return WeatherEvent.objects.filter(zone=zone).order_by('-timestamp').first()
