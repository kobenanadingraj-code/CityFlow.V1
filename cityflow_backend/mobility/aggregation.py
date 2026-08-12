"""
Agrégations pour l'écran Carte (mobile) : 'Heures de pointe prévues' (créneaux
08h/12h/17h/20h) et 'Zones à risque de congestion' (zone + créneau le plus
chargé). Calculées sur l'historique simulé (TrafficRecord, source='simule',
30 jours par défaut — voir seed_demo_data dans le pipeline du README).
"""
from django.db.models import Avg

from .models import TrafficRecord

_CRENEAUX_H = [8, 12, 17, 20]
_LABELS = [(85, 'Très dense'), (65, 'Dense'), (40, 'Modérée'), (0, 'Fluide')]


def _label(score):
    for seuil, label in _LABELS:
        if score >= seuil:
            return label
    return 'Fluide'


def heures_de_pointe_globales(zone=None):
    """Niveau de trafic moyen (toutes zones ou une zone donnée) par créneau horaire fixe."""
    qs = TrafficRecord.objects.filter(source='simule')
    if zone:
        qs = qs.filter(segment__zone__iexact=zone)

    resultats = []
    for h in _CRENEAUX_H:
        avg = qs.filter(timestamp__hour=h).aggregate(m=Avg('niveau_congestion'))['m'] or 0
        resultats.append({'heure': f"{h:02d}:00", 'score_moyen': round(avg), 'niveau': _label(avg)})
    return resultats


def zones_a_risque(top_n=3):
    """Pour chaque zone connue, l'heure où la congestion moyenne est la plus forte."""
    zones = (
        TrafficRecord.objects.filter(source='simule')
        .values_list('segment__zone', flat=True)
        .distinct()
    )
    resultats = []
    for zone in zones:
        pire = (
            TrafficRecord.objects.filter(source='simule', segment__zone=zone)
            .values('timestamp__hour')
            .annotate(m=Avg('niveau_congestion'))
            .order_by('-m')
            .first()
        )
        if not pire:
            continue
        h = pire['timestamp__hour']
        resultats.append({
            'zone': zone,
            'creneau': f"{h:02d}:00 - {(h + 2) % 24:02d}:00",
            'score_moyen': round(pire['m']),
            'niveau': _label(pire['m']),
        })

    resultats.sort(key=lambda r: r['score_moyen'], reverse=True)
    return resultats[:top_n]
