from django.urls import path
from .views import (
    NotificationListView, NotificationMarkReadView,
    NotificationMarkAllReadView, NotificationUnreadCountView,
)

urlpatterns = [
    path('', NotificationListView.as_view(), name='notification-list'),
    path('non-lues/', NotificationUnreadCountView.as_view(), name='notification-unread-count'),
    path('marquer-toutes-lues/', NotificationMarkAllReadView.as_view(), name='notification-mark-all-read'),
    path('<int:pk>/lu/', NotificationMarkReadView.as_view(), name='notification-mark-read'),
]
