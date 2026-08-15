from django.contrib import admin

from .models import DailySnapshot, ActivityLog


@admin.register(DailySnapshot)
class DailySnapshotAdmin(admin.ModelAdmin):
    list_display = ['date', 'signalements_jour', 'incidents_actifs', 'zones_a_risque', 'utilisateurs_actifs']
    ordering = ['-date']


@admin.register(ActivityLog)
class ActivityLogAdmin(admin.ModelAdmin):
    list_display = ['type', 'description', 'user', 'created_at']
    list_filter = ['type']
    ordering = ['-created_at']