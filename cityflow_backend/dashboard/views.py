"""
dashboard.views — refonte pour l'écran Tableau de bord.

`DashboardExportView` (export CSV brut) est retiré : l'écran Export des
données a maintenant sa propre app (`exports`), avec configuration complète
et formats CSV/Excel/PDF. `CriticalZonesView` est conservée (dashboard
autorité, score composite congestion+signalements+météo).
"""
from datetime import timedelta

from django.db.models import Count, Max
from django.utils import timezone
from rest_framework.response import Response
from rest_framework.views import APIView

from accounts.models import User
from environment.models import WeatherEvent
from mobility.models import RoadSegment, Prediction
from reports.models import Report
from .models import DailySnapshot, ActivityLog
from .permissions import IsAutorite


def _composite_score(congestion, nb_reports_actifs, has_alerte_meteo):
    """score = 0.5×congestion + 0.3×(nb_reports×10) + 0.2×(100 si alerte météo)"""
    return (
        0.5 * congestion
        + 0.3 * min(nb_reports_actifs * 10, 100)
        + 0.2 * (100 if has_alerte_meteo else 0)
    )


class CriticalZonesView(APIView):
    permission_classes = [IsAutorite]

    def get(self, request):
        zones_alerte = set(
            WeatherEvent.objects.exclude(type='normal').values_list('zone', flat=True)
        )
        latest_pred_ids = (
            Prediction.objects.values('segment')
            .annotate(latest_id=Max('id'))
            .values_list('latest_id', flat=True)
        )
        predictions = Prediction.objects.filter(id__in=latest_pred_ids).select_related('segment')
        active_counts = dict(
            Report.objects.filter(statut__in=['nouveau', 'en_cours'])
            .values('segment')
            .annotate(cnt=Count('id'))
            .values_list('segment', 'cnt')
        )
        results = []
        for pred in predictions:
            seg = pred.segment
            nb_reports = active_counts.get(seg.id, 0)
            has_meteo = seg.zone_inondable and seg.zone in zones_alerte
            score = _composite_score(pred.score_predit, nb_reports, has_meteo)
            results.append({
                'segment_id': seg.id,
                'segment_nom': seg.nom,
                'zone': seg.zone,
                'zone_inondable': seg.zone_inondable,
                'congestion_predite': pred.score_predit,
                'nb_signalements_actifs': nb_reports,
                'alerte_meteo': has_meteo,
                'score_composite': round(score, 2),
            })
        results.sort(key=lambda x: x['score_composite'], reverse=True)
        return Response(results[:5])


class DashboardStatsView(APIView):
    """4 cartes KPI du Tableau de bord, avec variation vs hier (basée sur DailySnapshot)."""
    permission_classes = [IsAutorite]

    def get(self, request):
        today = timezone.localdate()
        yesterday = today - timedelta(days=1)

        signalements_jour = Report.objects.filter(created_at__date=today).count()
        incidents_actifs = Report.objects.filter(statut__in=['nouveau', 'en_cours']).count()
        zones_a_risque = RoadSegment.objects.filter(zone_inondable=True).values('zone').distinct().count()
        utilisateurs_actifs = User.objects.filter(is_active=True).count()

        snap = DailySnapshot.objects.filter(date=yesterday).first()

        def _variation(actuel, hier):
            if not hier:
                return None
            return round((actuel - hier) / hier * 100, 1)

        return Response({
            'signalements_aujourdhui': {
                'valeur': signalements_jour,
                'variation_pct': _variation(signalements_jour, snap.signalements_jour if snap else None),
            },
            'incidents_actifs': {
                'valeur': incidents_actifs,
                'variation_pct': _variation(incidents_actifs, snap.incidents_actifs if snap else None),
            },
            'zones_a_risque': {
                'valeur': zones_a_risque,
                'variation_pct': _variation(zones_a_risque, snap.zones_a_risque if snap else None),
            },
            'utilisateurs_actifs': {
                'valeur': utilisateurs_actifs,
                'variation_pct': _variation(utilisateurs_actifs, snap.utilisateurs_actifs if snap else None),
            },
        })


class IncidentsCarteView(APIView):
    """'Carte des incidents - Abidjan' — pins géolocalisés + type (couleur gérée côté app)."""
    permission_classes = [IsAutorite]

    def get(self, request):
        qs = Report.objects.filter(statut__in=['nouveau', 'en_cours']).exclude(latitude=None)
        return Response([
            {'id': r.id, 'type': r.type, 'latitude': r.latitude, 'longitude': r.longitude, 'zone': r.zone}
            for r in qs
        ])


class RepartitionParTypeView(APIView):
    """Donut 'Répartition par type' — réutilisé sur Tableau de bord ET Export des données."""
    permission_classes = [IsAutorite]

    def get(self, request):
        total = Report.objects.count()
        counts = Report.objects.values('type').annotate(total=Count('id')).order_by('-total')
        return Response({
            'total': total,
            'repartition': [
                {
                    'type': c['type'],
                    'total': c['total'],
                    'pourcentage': round(c['total'] / total * 100, 1) if total else 0,
                }
                for c in counts
            ],
        })


class ActiviteRecenteView(APIView):
    """Flux 'Activité récente' du Tableau de bord."""
    permission_classes = [IsAutorite]

    def get(self, request):
        limit = int(request.query_params.get('limit', 10))
        logs = ActivityLog.objects.select_related('user')[:limit]
        return Response([
            {
                'type': log.type,
                'description': log.description,
                'user': log.user.get_full_name() if log.user else None,
                'created_at': log.created_at.isoformat(),
            }
            for log in logs
        ])
