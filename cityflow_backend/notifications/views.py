from rest_framework import generics
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from .models import Notification
from .serializers import NotificationSerializer


class NotificationListView(generics.ListAPIView):
    """Cloche de notifications — Accueil et Profil (app mobile)."""
    serializer_class = NotificationSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        qs = self.request.user.notifications.all()
        lu = self.request.query_params.get('lu')
        if lu is not None:
            qs = qs.filter(lu=(lu == 'true'))
        return qs


class NotificationMarkReadView(generics.UpdateAPIView):
    serializer_class = NotificationSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        return self.request.user.notifications.all()

    def patch(self, request, *args, **kwargs):
        notif = self.get_object()
        notif.lu = True
        notif.save(update_fields=['lu'])
        return Response(NotificationSerializer(notif).data)


class NotificationMarkAllReadView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        request.user.notifications.filter(lu=False).update(lu=True)
        return Response({'status': 'ok'})


class NotificationUnreadCountView(APIView):
    """Badge numérique sur l'icône cloche."""
    permission_classes = [IsAuthenticated]

    def get(self, request):
        return Response({'non_lues': request.user.notifications.filter(lu=False).count()})
