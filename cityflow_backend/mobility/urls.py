from rest_framework.routers import DefaultRouter
from django.urls import path, include
from .views import RoadSegmentViewSet, PredictionViewSet, CommuneStatsView, CartePrevisionsView

router = DefaultRouter()
router.register('segments', RoadSegmentViewSet, basename='segment')
router.register('predictions', PredictionViewSet, basename='prediction')

urlpatterns = [
    path('', include(router.urls)),
    path('communes/', CommuneStatsView.as_view(), name='commune-stats'),
    path('previsions/', CartePrevisionsView.as_view(), name='carte-previsions'),
]
