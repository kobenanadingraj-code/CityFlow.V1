"""
Client OSRM pour l'écran Trajet (durée/distance réelles sur une recherche
libre "Où allez-vous ?"). Suit le même principe que mobility/ml/predictor.py :
un chemin nominal (appel OSRM) + un repli explicite si le service est
indisponible, pour ne jamais faire planter l'API mobile.

Utilisation typique (dans une vue) :

    from .routing import get_route, RoutingUnavailable
    try:
        route = get_route(origine_lat, origine_lng, destination_lat, destination_lng)
    except RoutingUnavailable:
        route = None  # l'endpoint doit alors répondre sans distance_km/duree_min,
                       # seulement le niveau de trafic calculé via les segments.
"""
import os
import logging

import requests

logger = logging.getLogger('conseil')

OSRM_URL = os.environ.get('OSRM_URL', 'http://localhost:5001')
_TIMEOUT_S = 3


class RoutingUnavailable(Exception):
    """Levée si OSRM ne répond pas ou renvoie une erreur — jamais de 500 côté API."""


def get_route(origine_lat, origine_lng, destination_lat, destination_lng, alternatives=True):
    """
    Appelle OSRM /route/v1/driving et retourne jusqu'à 3 itinéraires :

        [
          {
            'distance_km': 12.4,
            'duree_min': 32,
            'geometry': <GeoJSON LineString coords>,
          },
          ...
        ]

    Lève RoutingUnavailable si OSRM est injoignable, mal configuré, ou ne
    trouve aucun itinéraire (ex: coordonnées hors de la zone couverte par
    l'extrait Côte d'Ivoire).
    """
    coords = f"{origine_lng},{origine_lat};{destination_lng},{destination_lat}"
    url = f"{OSRM_URL}/route/v1/driving/{coords}"
    params = {
        'alternatives': 'true' if alternatives else 'false',
        'overview': 'simplified',
        'geometries': 'geojson',
    }

    try:
        resp = requests.get(url, params=params, timeout=_TIMEOUT_S)
        resp.raise_for_status()
        data = resp.json()
    except requests.RequestException as exc:
        logger.error('routing: OSRM injoignable (%s) — %s', OSRM_URL, exc)
        raise RoutingUnavailable(str(exc)) from exc

    if data.get('code') != 'Ok' or not data.get('routes'):
        logger.warning('routing: OSRM sans itinéraire — code=%s', data.get('code'))
        raise RoutingUnavailable(data.get('code', 'NoRoute'))

    return [
        {
            'distance_km': round(route['distance'] / 1000, 1),
            'duree_min': round(route['duration'] / 60),
            'geometry': route['geometry']['coordinates'],
        }
        for route in data['routes']
    ]
