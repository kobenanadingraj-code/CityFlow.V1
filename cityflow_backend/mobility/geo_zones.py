"""
Classification des segments routiers par commune du district d'Abidjan.

Les tags OSM addr:city / is_in:city / addr:suburb sont quasi toujours absents
sur les ways routiers (ils servent surtout à taguer bâtiments/POI) — d'où un
classement en deux passes :
  1. Nom de commune détecté en toutes lettres dans le nom de la rue.
  2. Sinon, commune dont le centre est géographiquement le plus proche
     (distance euclidienne lat/lon — suffisant à l'échelle d'Abidjan).

Centres approximatifs (lat, lon), source Wikipédia (page par commune).

Zones à risque d'inondation documentées (sources : BNETD, Plan de Gestion des
Inondations Abidjan 2018, rapports OCHA ; Adjamé ajoutée d'après les
inondations d'octobre 2021 qui ont touché Yopougon/Abobo/Attécoubé/Adjamé) :
"""

COMMUNE_KEYWORDS = [
    ('yopougon', 'Yopougon'),
    ('abobo', 'Abobo'),
    ('attécoubé', 'Attécoubé'),
    ('attecoube', 'Attécoubé'),
    ('cocody', 'Cocody'),
    ('adjamé', 'Adjamé'),
    ('adjame', 'Adjamé'),
    ('koumassi', 'Koumassi'),
    ('marcory', 'Marcory'),
    ('plateau', 'Plateau'),
    ('treichville', 'Treichville'),
    ('port-bouët', 'Port-Bouët'),
    ('port-bouet', 'Port-Bouët'),
    ('port bouet', 'Port-Bouët'),
    ('bingerville', 'Bingerville'),
    ('anyama', 'Anyama'),
    ('songon', 'Songon'),
]

COMMUNE_CENTERS = {
    'Abobo': (5.417, -4.017),
    'Adjamé': (5.350, -4.033),
    'Attécoubé': (5.333, -4.033),
    'Cocody': (5.350, -3.967),
    'Koumassi': (5.300, -3.950),
    'Marcory': (5.300, -3.983),
    'Plateau': (5.317, -4.017),
    'Port-Bouët': (5.267, -3.900),
    'Treichville': (5.295, -4.005),
    'Yopougon': (5.317, -4.067),
    'Bingerville': (5.356, -3.882),
    'Anyama': (5.494, -4.051),
    'Songon': (5.276, -4.263),
}

ZONES_INONDABLES = {'yopougon', 'abobo', 'attécoubé', 'adjamé'}


def classify_commune(nom: str, lat: float, lon: float) -> str:
    """Détermine la commune d'un segment à partir de son nom, puis de ses coordonnées."""
    nom_lower = (nom or '').lower()
    for keyword, commune in COMMUNE_KEYWORDS:
        if keyword in nom_lower:
            return commune

    best_commune, best_dist = 'Abidjan', float('inf')
    for commune, (clat, clon) in COMMUNE_CENTERS.items():
        dist = (lat - clat) ** 2 + (lon - clon) ** 2
        if dist < best_dist:
            best_dist = dist
            best_commune = commune
    return best_commune


def is_inondable(zone: str) -> bool:
    z = zone.lower()
    return any(zi in z for zi in ZONES_INONDABLES)
