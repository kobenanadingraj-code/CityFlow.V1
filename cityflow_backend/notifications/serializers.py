from rest_framework import serializers
from .models import Notification


class NotificationSerializer(serializers.ModelSerializer):
    class Meta:
        model = Notification
        fields = ('id', 'type', 'titre', 'message', 'lu', 'lien_objet', 'created_at')
        read_only_fields = ('id', 'created_at')
