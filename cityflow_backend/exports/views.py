from rest_framework import generics, status
from rest_framework.response import Response

from dashboard.permissions import IsAutorite
from .models import ExportJob
from .serializers import ExportJobSerializer, ExportJobCreateSerializer
from .generators import build_export


class ExportJobListCreateView(generics.ListCreateAPIView):
    """Écran Export des données — 'Configurer un nouvel export' + table 'Exports récents'."""
    permission_classes = [IsAutorite]

    def get_serializer_class(self):
        if self.request.method == 'POST':
            return ExportJobCreateSerializer
        return ExportJobSerializer

    def get_queryset(self):
        return ExportJob.objects.select_related('demande_par').all()

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        job = serializer.save(demande_par=request.user, statut='en_cours')

        try:
            build_export(job)
        except NotImplementedError as exc:
            job.statut = 'echec'
            job.save(update_fields=['statut'])
            return Response(
                {'erreur': str(exc)},
                status=status.HTTP_501_NOT_IMPLEMENTED,
            )
        except Exception as exc:
            job.statut = 'echec'
            job.save(update_fields=['statut'])
            return Response(
                {'erreur': "Échec de la génération de l'export.", 'detail': str(exc)},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR,
            )

        return Response(
            ExportJobSerializer(job, context={'request': request}).data,
            status=status.HTTP_201_CREATED,
        )
