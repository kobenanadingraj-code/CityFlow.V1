from rest_framework import generics, status, viewsets
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework_simplejwt.views import TokenObtainPairView

from .models import SavedPlace, UserPreferences, ZoneSurveillee
from .serializers import (
    CityFlowTokenSerializer, RegisterSerializer, UserSerializer, ProfileUpdateSerializer,
    SavedPlaceSerializer, UserPreferencesSerializer, ZoneSurveilleeSerializer,
)
from .throttles import LoginRateThrottle


class RegisterView(generics.CreateAPIView):
    """Écran Créer un compte."""
    permission_classes = [AllowAny]
    serializer_class = RegisterSerializer

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user = serializer.save()
        return Response(UserSerializer(user).data, status=status.HTTP_201_CREATED)


class LoginView(TokenObtainPairView):
    """Écran Bienvenue — connexion par email ou téléphone."""
    permission_classes = [AllowAny]
    throttle_classes = [LoginRateThrottle]
    serializer_class = CityFlowTokenSerializer


class MeView(generics.RetrieveUpdateAPIView):
    """Écran Profil — en-tête + informations personnelles."""
    permission_classes = [IsAuthenticated]

    def get_object(self):
        return self.request.user

    def get_serializer_class(self):
        if self.request.method in ('PUT', 'PATCH'):
            return ProfileUpdateSerializer
        return UserSerializer


class SavedPlaceViewSet(viewsets.ModelViewSet):
    """Écran Profil > 'Mes lieux enregistrés'."""
    serializer_class = SavedPlaceSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        return self.request.user.lieux.all()

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)


class PreferencesView(generics.RetrieveUpdateAPIView):
    """Écran Profil > 'Préférences'."""
    serializer_class = UserPreferencesSerializer
    permission_classes = [IsAuthenticated]

    def get_object(self):
        prefs, _ = UserPreferences.objects.get_or_create(user=self.request.user)
        return prefs


class ZoneSurveilleeViewSet(viewsets.ModelViewSet):
    """Écran Profil > 'Zones à surveiller'."""
    serializer_class = ZoneSurveilleeSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        return self.request.user.zones_surveillees.all()

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)
