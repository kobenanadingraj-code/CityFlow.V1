"""
Importe l'historique de pluviométrie réel depuis un export CSV/JSON.
Source recommandée : Open-Meteo (https://open-meteo.com/), historique horaire Abidjan.
Période : les 30 jours couverts par seed_demo_data.
L'appel réseau se fait en amont — cette commande est reproductible sans dépendance réseau.

Seuils d'intensité (mm/h) :
  < 2.5  → normal
  2.5–7.5 → pluie_moderee
  > 7.5   → pluie_forte
Source seuils : OMM / WMO guide to meteorological observations.
"""
import csv
import json
import os
from datetime import datetime

from django.core.management.base import BaseCommand, CommandError
from django.utils import timezone

from environment.models import WeatherEvent

ZONE_DEFAULT = 'Abidjan'
SEUIL_FORTE = 7.5
SEUIL_MODEREE = 2.5


def _type_from_intensite(intensite):
    if intensite >= SEUIL_FORTE:
        return 'pluie_forte'
    if intensite >= SEUIL_MODEREE:
        return 'pluie_moderee'
    return 'normal'


class Command(BaseCommand):
    help = "Importe l'historique météo réel depuis un fichier CSV ou JSON"

    def add_arguments(self, parser):
        parser.add_argument('--fichier', required=True, help='Chemin CSV ou JSON')
        parser.add_argument('--zone', default=ZONE_DEFAULT, help='Zone/commune (défaut: Abidjan)')

    def handle(self, *args, **options):
        fichier = options['fichier']
        zone = options['zone']

        if not os.path.exists(fichier):
            raise CommandError(f"Fichier introuvable : {fichier}")

        events = []
        ext = os.path.splitext(fichier)[1].lower()

        if ext == '.csv':
            with open(fichier, encoding='utf-8') as f:
                reader = csv.DictReader(f)
                for row in reader:
                    intensite = float(row.get('precipitation', row.get('intensite', 0)) or 0)
                    ts_raw = row.get('time', row.get('timestamp', row.get('date', '')))
                    ts = datetime.fromisoformat(ts_raw.replace('Z', '+00:00'))
                    if timezone.is_naive(ts):
                        ts = timezone.make_aware(ts)
                    events.append(WeatherEvent(
                        zone=zone,
                        type=_type_from_intensite(intensite),
                        intensite=intensite,
                        timestamp=ts,
                        source='historique_reel',
                    ))
        elif ext == '.json':
            with open(fichier, encoding='utf-8') as f:
                data = json.load(f)
            entries = data if isinstance(data, list) else []
            times = data.get('hourly', {}).get('time', []) if isinstance(data, dict) else []
            precips = data.get('hourly', {}).get('precipitation', []) if isinstance(data, dict) else []
            if times and precips:
                # Export Open-Meteo : hourly.time est "YYYY-MM-DDTHH:MM" (sans
                # secondes) — datetime.fromisoformat() n'accepte ce format
                # sans secondes qu'à partir de Python 3.11. On utilise
                # strptime pour rester compatible avec toutes les versions.
                for ts_raw, intensite in zip(times, precips):
                    ts = datetime.strptime(ts_raw, '%Y-%m-%dT%H:%M')
                    ts = timezone.make_aware(ts, timezone.get_default_timezone())
                    intensite = float(intensite or 0)
                    events.append(WeatherEvent(
                        zone=zone,
                        type=_type_from_intensite(intensite),
                        intensite=intensite,
                        timestamp=ts,
                        source='historique_reel',
                    ))
            else:
                for entry in entries:
                    intensite = float(entry.get('precipitation', entry.get('intensite', 0)) or 0)
                    ts_raw = entry.get('time', entry.get('timestamp', ''))
                    try:
                        ts = datetime.strptime(ts_raw, '%Y-%m-%dT%H:%M')
                    except ValueError:
                        ts = datetime.fromisoformat(ts_raw)
                    if timezone.is_naive(ts):
                        ts = timezone.make_aware(ts)
                    events.append(WeatherEvent(
                        zone=zone,
                        type=_type_from_intensite(intensite),
                        intensite=intensite,
                        timestamp=ts,
                        source='historique_reel',
                    ))
        else:
            raise CommandError("Format non supporté : utilisez .csv ou .json")

        WeatherEvent.objects.bulk_create(events, ignore_conflicts=True)
        self.stdout.write(self.style.SUCCESS(
            f"{len(events)} WeatherEvent importés (source: historique_reel, zone: {zone})."
        ))
