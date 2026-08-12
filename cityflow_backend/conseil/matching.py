"""
Rattache un tracé OSRM (liste de points [lng, lat]) aux RoadSegment les plus
proches, pour pouvoir calculer un niveau de trafic sur un itinéraire
quelconque à partir des prédictions existantes.

Limite connue : RoadSegment ne stocke qu'un point (pas une géométrie de
ligne), donc c'est un rattachement par proximité, pas un vrai map-matching.
Suffisant pour classer un trajet en fluide/modéré/dense ; pas pour un tracé
segment-par-segment pixel-perfect. Si la précision devient un problème en
prod, la solution propre est d'ajouter PostGIS + une vraie géométrie de ligne
par segment plutôt que d'optimiser cette approximation.
"""
import math

from mobility.models import RoadSegment

_EARTH_RADIUS_M = 6371000
_BBOX_PAD_DEG = 0.01  # ~1.1 km, marge autour du tracé pour le pré-filtre


def _haversine_m(lat1, lng1, lat2, lng2):
    phi1, phi2 = math.radians(lat1), math.radians(lat2)
    dphi = math.radians(lat2 - lat1)
    dlambda = math.radians(lng2 - lng1)
    a = math.sin(dphi / 2) ** 2 + math.cos(phi1) * math.cos(phi2) * math.sin(dlambda / 2) ** 2
    return 2 * _EARTH_RADIUS_M * math.asin(math.sqrt(a))


def segments_near_route(geometry_coords, max_radius_m=300, sample_every=5):
    """geometry_coords : [[lng, lat], ...] — format GeoJSON renvoyé par OSRM."""
    if not geometry_coords:
        return []

    lats = [p[1] for p in geometry_coords]
    lngs = [p[0] for p in geometry_coords]
    candidates = list(
        RoadSegment.objects.filter(
            latitude__gte=min(lats) - _BBOX_PAD_DEG, latitude__lte=max(lats) + _BBOX_PAD_DEG,
            longitude__gte=min(lngs) - _BBOX_PAD_DEG, longitude__lte=max(lngs) + _BBOX_PAD_DEG,
        ).only('id', 'nom', 'latitude', 'longitude', 'zone')
    )
    if not candidates:
        return []

    sample_points = geometry_coords[::sample_every] or geometry_coords
    found = {}
    for lng, lat in sample_points:
        nearest, nearest_dist = None, max_radius_m
        for seg in candidates:
            d = _haversine_m(lat, lng, seg.latitude, seg.longitude)
            if d < nearest_dist:
                nearest, nearest_dist = seg, d
        if nearest:
            found[nearest.id] = nearest
    return list(found.values())
