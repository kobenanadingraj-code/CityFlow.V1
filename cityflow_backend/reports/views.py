from django.db.models import Q
from rest_framework import generics, status
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response

from .models import Report
from .permissions import IsAutorite
from .serializers import ReportSerializer, ReportCreateSerializer, ReportPatchSerializer
from .pagination import ReportPagination
from .throttles import ReportCreateThrottle


class ReportListCreateView(generics.ListCreateAPIView):
    """
    Écran Alertes (mobile, filtres Toutes/Accidents/Inondations/Travaux)
    + table 'Gestion des signalements' (dashboard web, filtres type/statut/
    priorité/période + recherche + pagination).
    """
    permission_classes = [IsAuthenticated]
    pagination_class = ReportPagination

    def get_serializer_class(self):
        if self.request.method == 'POST':
            return ReportCreateSerializer
        return ReportSerializer

    def get_throttles(self):
        if self.request.method == 'POST':
            return [ReportCreateThrottle()]
        return super().get_throttles()

    def get_queryset(self):
        qs = Report.objects.select_related('user', 'segment').all()
        params = self.request.query_params

        type_ = params.get('type')
        if type_ and type_ != 'toutes':
            qs = qs.filter(type=type_)

        statut = params.get('statut')
        if statut:
            qs = qs.filter(statut=statut)

        priorite = params.get('priorite')
        if priorite:
            qs = qs.filter(priorite=priorite)

        zone = params.get('zone')
        if zone:
            qs = qs.filter(zone__icontains=zone)

        date_debut = params.get('date_debut')
        if date_debut:
            qs = qs.filter(created_at__date__gte=date_debut)
        date_fin = params.get('date_fin')
        if date_fin:
            qs = qs.filter(created_at__date__lte=date_fin)

        q = params.get('q')
        if q:
            qs = qs.filter(
                Q(adresse__icontains=q) | Q(description__icontains=q) | Q(zone__icontains=q)
            )

        return qs

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data, context={'request': request})
        serializer.is_valid(raise_exception=True)
        report = serializer.save()
        return Response(ReportSerializer(report).data, status=status.HTTP_201_CREATED)


class ReportDetailView(generics.RetrieveUpdateDestroyAPIView):
    """Dashboard, colonne 'Actions' (voir / modifier statut-priorité / supprimer)."""
    queryset = Report.objects.select_related('user', 'segment').all()

    def get_serializer_class(self):
        if self.request.method == 'PATCH':
            return ReportPatchSerializer
        return ReportSerializer

    def get_permissions(self):
        if self.request.method in ('PATCH', 'DELETE'):
            return [IsAutorite()]
        return [IsAuthenticated()]
