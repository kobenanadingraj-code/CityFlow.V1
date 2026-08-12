from django.db.models import Max
from rest_framework.decorators import api_view, permission_classes, throttle_classes
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework import status

from mobility.throttles import PredictionsReadThrottle
from .corridors import CORRIDORS, generer_conseil
from .routing import get_route, RoutingUnavailable
from .matching import segments_near_route


@api_view(['GET'])
@permission_classes([AllowAny])
@throttle_classes([PredictionsReadThrottle])
def conseil_trajet(request):
    """
    GET /api/conseil/                  — liste des corridors historiques
    GET /api/conseil/?corridor=<key>   — analyse et conseil pour ce corridor
    Corridors pré-configurés (voir corridors.py) — inchangé.
    """
    corridor_key = request.query_params.get('corridor')
    if not corridor_key:
        corridors_list = [
            {'key': key, 'nom': conf['nom'], 'depart': conf['depart'],
             'arrivee': conf['arrivee'], 'description': conf['description']}
            for key, conf in CORRIDORS.items()
        ]
        return Response({'corridors': corridors_list})

    if corridor_key not in CORRIDORS:
        return Response(
            {'erreur': f"Corridor '{corridor_key}' inconnu.", 'corridors_valides': list(CORRIDORS.keys())},
            status=status.HTTP_404_NOT_FOUND,
        )
    return Response(generer_conseil(corridor_key))


def _score_to_trafic(score):
    if score is None:
        return 'inconnu'
    if score >= 70:
        return 'dense'
    if score >= 45:
        return 'modéré'
    return 'fluide'


def _score_segments(segments):
    """Moyenne des dernières prédictions pour un ensemble de segments (peut être vide)."""
    from mobility.models import Prediction
    if not segments:
        return None
    ids = [s.id for s in segments]
    latest_ids = (
        Prediction.objects.filter(segment_id__in=ids)
        .values('segment').annotate(latest_id=Max('id')).values_list('latest_id', flat=True)
    )
    scores = list(Prediction.objects.filter(id__in=latest_ids).values_list('score_predit', flat=True))
    return round(sum(scores) / len(scores)) if scores else None


@api_view(['GET'])
@permission_classes([IsAuthenticated])
@throttle_classes([PredictionsReadThrottle])
def trajet_libre(request):
    """
    Écran Trajet — recherche libre 'Où allez-vous ?'.
    GET ?origine_lat=&origine_lng=&destination_lat=&destination_lng=&destination_label=

    Jusqu'à 3 itinéraires (recommandé / autre / alternatif) : distance_km et
    duree_min via OSRM, niveau de trafic dérivé des RoadSegment proches du
    tracé (voir matching.py). Si OSRM est indisponible : erreur 503 explicite,
    jamais un résultat inventé.
    """
    try:
        origine_lat = float(request.query_params['origine_lat'])
        origine_lng = float(request.query_params['origine_lng'])
        destination_lat = float(request.query_params['destination_lat'])
        destination_lng = float(request.query_params['destination_lng'])
    except (KeyError, ValueError):
        return Response(
            {'erreur': "origine_lat, origine_lng, destination_lat, destination_lng sont requis (float)."},
            status=status.HTTP_400_BAD_REQUEST,
        )
    destination_label = request.query_params.get('destination_label', 'Destination')

    try:
        routes = get_route(origine_lat, origine_lng, destination_lat, destination_lng, alternatives=True)
    except RoutingUnavailable as exc:
        return Response(
            {'erreur': "Service de calcul d'itinéraire indisponible.", 'detail': str(exc)},
            status=status.HTTP_503_SERVICE_UNAVAILABLE,
        )

    routes = routes[:3]
    types = ['recommande', 'autre', 'alternatif']
    resultats = []
    for i, route in enumerate(routes):
        segments = segments_near_route(route['geometry'])
        score = _score_segments(segments)
        resultats.append({
            'type': types[i] if i < len(types) else 'autre',
            'destination_label': destination_label,
            'distance_km': route['distance_km'],
            'duree_min': route['duree_min'],
            'trafic': _score_to_trafic(score),
            'score_congestion': score,
            'nb_segments_analyses': len(segments),
            # [lng, lat] par point — pour tracer l'itinéraire sur la carte
            # (écran Trajet de la maquette). Simplifié côté OSRM
            # (overview=simplified) donc léger à transporter en JSON.
            'geometry': route['geometry'],
        })

    conseil_texte = None
    if resultats and resultats[0]['trafic'] == 'dense':
        conseil_texte = (
            "Trafic dense sur l'itinéraire recommandé — envisagez de partir "
            "plus tôt ou de prendre un itinéraire alternatif."
        )

    return Response({'itineraires': resultats, 'conseil': conseil_texte})


@api_view(['GET'])
@permission_classes([IsAuthenticated])
@throttle_classes([PredictionsReadThrottle])
def itineraires_recommandes(request):
    """
    Écran Carte — bloc 'Itinéraires recommandés'. Personnalisé : Domicile →
    Travail / Travail → Domicile si l'utilisateur a enregistré ces lieux
    (accounts.SavedPlace) ; sinon liste vide — pas de repli générique inventé.
    """
    from accounts.models import SavedPlace

    lieux = {p.type: p for p in SavedPlace.objects.filter(user=request.user, type__in=['maison', 'travail'])}
    maison, travail = lieux.get('maison'), lieux.get('travail')

    paires = []
    if maison and travail:
        paires = [
            ('Domicile', maison, 'Travail', travail),
            ('Travail', travail, 'Domicile', maison),
        ]

    resultats = []
    for label_o, origine, label_d, destination in paires:
        try:
            routes = get_route(
                origine.latitude, origine.longitude, destination.latitude, destination.longitude,
                alternatives=False,
            )
        except RoutingUnavailable:
            continue
        if not routes:
            continue
        route = routes[0]
        segments = segments_near_route(route['geometry'])
        score = _score_segments(segments)
        resultats.append({
            'origine_label': label_o,
            'destination_label': label_d,
            'distance_km': route['distance_km'],
            'duree_min': route['duree_min'],
            'trafic': _score_to_trafic(score),
        })

    return Response({'itineraires_recommandes': resultats})
