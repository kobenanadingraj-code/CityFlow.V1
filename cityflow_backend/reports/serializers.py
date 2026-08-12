from django.utils import timezone
from datetime import timedelta
from rest_framework import serializers

from .models import Report, classify_priority


class ReportSerializer(serializers.ModelSerializer):
    """Lecture — écran Alertes (mobile) et table 'Gestion des signalements' (dashboard web)."""
    segment_nom = serializers.CharField(source='segment.nom', read_only=True, default=None)
    signale_par = serializers.SerializerMethodField()

    class Meta:
        model = Report
        fields = (
            'id', 'type', 'description', 'photo',
            'zone', 'adresse', 'latitude', 'longitude', 'segment', 'segment_nom',
            'priorite', 'statut', 'nb_confirmations',
            'signale_par', 'created_at', 'updated_at',
        )
        read_only_fields = (
            'priorite', 'nb_confirmations', 'created_at', 'updated_at', 'segment_nom', 'signale_par',
        )

    def get_signale_par(self, obj):
        return obj.user.get_full_name() or obj.user.username


class ReportCreateSerializer(serializers.ModelSerializer):
    """Écriture — bouton 'Envoyer un signalement' (Alertes, Carte)."""

    class Meta:
        model = Report
        fields = ('type', 'description', 'photo', 'zone', 'adresse', 'latitude', 'longitude', 'segment')
        extra_kwargs = {'segment': {'required': False}}

    def create(self, validated_data):
        user = self.context['request'].user
        segment = validated_data.get('segment')
        type_incident = validated_data['type']

        # Dédup : même segment + même type + actif depuis < 5 min → on confirme au lieu de dupliquer.
        if segment is not None:
            cutoff = timezone.now() - timedelta(minutes=5)
            existing = Report.objects.filter(
                segment=segment, type=type_incident, statut__in=('nouveau', 'en_cours'),
                created_at__gte=cutoff,
            ).first()
            if existing:
                existing.nb_confirmations += 1
                existing.save(update_fields=['nb_confirmations'])
                return existing

        return Report.objects.create(
            user=user,
            priorite=classify_priority(type_incident),
            **validated_data,
        )


class ReportPatchSerializer(serializers.ModelSerializer):
    """Autorité uniquement — dashboard, colonne 'Actions' (changer statut/priorité)."""

    class Meta:
        model = Report
        fields = ('statut', 'priorite')
