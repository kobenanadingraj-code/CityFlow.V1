from django.contrib import admin
from .models import Report


@admin.register(Report)
class ReportAdmin(admin.ModelAdmin):
    list_display = ('type', 'priorite', 'statut', 'zone', 'segment', 'user', 'nb_confirmations', 'created_at')
    list_filter = ('type', 'priorite', 'statut')
    search_fields = ('zone', 'adresse', 'description')
