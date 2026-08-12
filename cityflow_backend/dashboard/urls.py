from django.urls import path
from .views import (
    CriticalZonesView, DashboardStatsView, IncidentsCarteView,
    RepartitionParTypeView, ActiviteRecenteView,
)

urlpatterns = [
    path('critical-zones/', CriticalZonesView.as_view(), name='dashboard-critical-zones'),
    path('stats/', DashboardStatsView.as_view(), name='dashboard-stats'),
    path('incidents-carte/', IncidentsCarteView.as_view(), name='dashboard-incidents-carte'),
    path('repartition-par-type/', RepartitionParTypeView.as_view(), name='dashboard-repartition-type'),
    path('activite-recente/', ActiviteRecenteView.as_view(), name='dashboard-activite-recente'),
]
