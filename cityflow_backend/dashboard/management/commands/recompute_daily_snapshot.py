"""
Capture les compteurs du jour dans DailySnapshot — nécessaire pour que
DashboardStatsView puisse calculer les variations '+12% vs hier' affichées
sur le Tableau de bord.

À lancer une fois par jour (cron, ex. 23h55) :
    python manage.py recompute_daily_snapshot
"""
from django.core.management.base import BaseCommand
from django.utils import timezone

from accounts.models import User
from dashboard.models import DailySnapshot
from mobility.models import RoadSegment
from reports.models import Report


class Command(BaseCommand):
    help = "Enregistre un DailySnapshot pour la date du jour (idempotent)."

    def handle(self, *args, **options):
        today = timezone.localdate()
        snapshot, created = DailySnapshot.objects.update_or_create(
            date=today,
            defaults={
                'signalements_jour': Report.objects.filter(created_at__date=today).count(),
                'incidents_actifs': Report.objects.filter(statut__in=['nouveau', 'en_cours']).count(),
                'zones_a_risque': RoadSegment.objects.filter(zone_inondable=True)
                    .values('zone').distinct().count(),
                'utilisateurs_actifs': User.objects.filter(is_active=True).count(),
            },
        )
        action = 'créé' if created else 'mis à jour'
        self.stdout.write(self.style.SUCCESS(f"Snapshot {today} {action} (id={snapshot.id})."))
