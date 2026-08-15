from django.db.models import Avg, Count, Max, Q
from django.utils import timezone
from rest_framework import generics, viewsets
from rest_framework.decorators import action
from rest_framework.pagination import LimitOffsetPagination
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework.exceptions import NotFound

from .models import RoadSegment, TrafficRecord, Prediction
from .serializers import RoadSegmentSerializer, TrafficRecordSerializer, PredictionSerializer
from .throttles import PredictionsReadThrottle
from .aggregation import heures_de_pointe_globales, zones_a_risque
from .geo_zones import COMMUNE_CENTERS

# Dérivée de geo_zones.py (source unique de vérité pour les communes) — évite
# la désynchronisation qui excluait silencieusement Cocody/Marcory/Plateau/
# Attécoubé des résultats de /api/predictions/ et /api/communes/.
_KNOWN_COMMUNES = list(COMMUNE_CENTERS.keys()) + ['Abidjan']


class PredictionPagination(LimitOffsetPagination):
    default_limit = 25
    max_limit = 100


class RoadSegmentViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = RoadSegment.objects.all()
    serializer_class = RoadSegmentSerializer
    permission_classes = [AllowAny]

    def get_queryset(self):
        qs = super().get_queryset()
        zone = self.request.query_params.get('zone')
        if zone:
            qs = qs.filter(zone__icontains=zone)
        return qs

    @action(detail=True, methods=['get'], url_path='history',
            throttle_classes=[PredictionsReadThrottle])
    def history(self, request, pk=None):
        try:
            segment = RoadSegment.objects.get(pk=pk)
        except RoadSegment.DoesNotExist:
            raise NotFound(f"Segment {pk} introuvable.")
        records = TrafficRecord.objects.filter(segment=segment).order_by('-timestamp')[:100]
        return Response(TrafficRecordSerializer(records, many=True).data)

    @action(detail=True, methods=['get'], url_path='predict',
            throttle_classes=[PredictionsReadThrottle])
    def predict(self, request, pk=None):
        """Prédiction live (appel direct du predictor ML/fallback)."""
        from .ml.predictor import predict_congestion
        try:
            result = predict_congestion(int(pk))
        except ValueError as exc:
            raise NotFound(str(exc))
        return Response(result)


class PredictionViewSet(viewsets.ReadOnlyModelViewSet):
    serializer_class = PredictionSerializer
    permission_classes = [AllowAny]
    throttle_classes = [PredictionsReadThrottle]
    pagination_class = PredictionPagination

    def get_queryset(self):
        if self.action == 'list':
            latest_ids = (
                Prediction.objects.values('segment')
                .annotate(latest_id=Max('id'))
                .values_list('latest_id', flat=True)
            )
            qs = Prediction.objects.filter(id__in=latest_ids).order_by('-score_predit')
            zone = self.request.query_params.get('zone')
            if zone:
                qs = qs.filter(segment__zone__iexact=zone)
            return qs
        segment_id = self.kwargs.get('pk')
        if segment_id and not RoadSegment.objects.filter(pk=segment_id).exists():
            raise NotFound(f"Segment {segment_id} introuvable.")
        return Prediction.objects.filter(segment_id=self.kwargs.get('pk'))


class CommuneStatsView(generics.GenericAPIView):
    permission_classes = [AllowAny]
    throttle_classes = [PredictionsReadThrottle]

    def get(self, request):
        latest_ids = (
            Prediction.objects.values('segment')
            .annotate(latest_id=Max('id'))
            .values_list('latest_id', flat=True)
        )
        stats = (
            Prediction.objects
            .filter(id__in=latest_ids, segment__zone__in=_KNOWN_COMMUNES)
            .values('segment__zone')
            .annotate(
                nb_segments=Count('id'),
                score_moyen=Avg('score_predit'),
                score_max=Max('score_predit'),
                nb_critiques=Count('id', filter=Q(score_predit__gte=70)),
            )
            .order_by('-score_moyen')
        )
        return Response([
            {
                'zone': s['segment__zone'],
                'nb_segments': s['nb_segments'],
                'score_moyen': round(s['score_moyen'] or 0),
                'score_max': s['score_max'] or 0,
                'nb_critiques': s['nb_critiques'],
            }
            for s in stats
        ])


class CartePrevisionsView(APIView):
    """
    Écran Carte (mobile) : 'Heures de pointe prévues' (créneaux 08h/12h/17h/
    20h) + 'Zones à risque de congestion' (zone + créneau le plus chargé) en
    un seul appel, avec l'horodatage de dernière mise à jour affiché dans la
    maquette ('Dernière mise à jour : aujourd'hui à 09:30').
    """
    permission_classes = [IsAuthenticated]
    throttle_classes = [PredictionsReadThrottle]

    def get(self, request):
        zone = request.query_params.get('zone')
        return Response({
            'heures_de_pointe': heures_de_pointe_globales(zone=zone),
            'zones_a_risque': zones_a_risque(top_n=int(request.query_params.get('top', 3))),
            'derniere_mise_a_jour': timezone.now().isoformat(),
        })