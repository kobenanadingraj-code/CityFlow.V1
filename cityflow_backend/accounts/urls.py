from django.urls import path, include
from rest_framework.routers import DefaultRouter
from rest_framework_simplejwt.views import TokenRefreshView

from .views import (
    RegisterView, LoginView, MeView, PreferencesView,
    SavedPlaceViewSet, ZoneSurveilleeViewSet,
)

router = DefaultRouter()
router.register('me/lieux', SavedPlaceViewSet, basename='saved-place')
router.register('me/zones-surveillees', ZoneSurveilleeViewSet, basename='zone-surveillee')

urlpatterns = [
    path('register/', RegisterView.as_view(), name='auth-register'),
    path('login/', LoginView.as_view(), name='auth-login'),
    path('refresh/', TokenRefreshView.as_view(), name='auth-refresh'),
    path('me/', MeView.as_view(), name='auth-me'),
    path('me/preferences/', PreferencesView.as_view(), name='auth-preferences'),
    path('', include(router.urls)),
]
