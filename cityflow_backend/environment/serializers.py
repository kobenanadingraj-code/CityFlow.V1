from rest_framework import serializers
from .models import WeatherEvent


class WeatherEventSerializer(serializers.ModelSerializer):
    """Écran Accueil (mobile) — carte 'Météo : 28°C, Ensoleillé'."""

    class Meta:
        model = WeatherEvent
        fields = ('id', 'zone', 'type', 'condition', 'temperature', 'intensite', 'timestamp', 'source')
