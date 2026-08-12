from rest_framework import serializers
from .models import ExportJob


class ExportJobCreateSerializer(serializers.ModelSerializer):
    class Meta:
        model = ExportJob
        fields = ('nom', 'type_donnees', 'periode_debut', 'periode_fin', 'filtres', 'format')


class ExportJobSerializer(serializers.ModelSerializer):
    demande_par_nom = serializers.SerializerMethodField()
    fichier_url = serializers.SerializerMethodField()

    class Meta:
        model = ExportJob
        fields = (
            'id', 'nom', 'type_donnees', 'periode_debut', 'periode_fin', 'filtres',
            'format', 'statut', 'taille_octets', 'demande_par_nom', 'fichier_url', 'created_at',
        )

    def get_demande_par_nom(self, obj):
        return obj.demande_par.get_full_name() or obj.demande_par.username

    def get_fichier_url(self, obj):
        request = self.context.get('request')
        if obj.fichier and request:
            return request.build_absolute_uri(obj.fichier.url)
        return None
