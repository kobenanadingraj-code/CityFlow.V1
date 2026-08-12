"""
L'app conseil n'avait pas d'admin.py avant (elle n'avait pas de modèles).
Enregistrement du nouveau modèle Itineraire pour pouvoir gérer les
itinéraires prédéfinis (is_predefini=True) depuis /admin/.
"""
from django.contrib import admin
from .models import Itineraire, ItineraireSegment


class ItineraireSegmentInline(admin.TabularInline):
    model = ItineraireSegment
    extra = 1


@admin.register(Itineraire)
class ItineraireAdmin(admin.ModelAdmin):
    list_display = ('origine_label', 'destination_label', 'type', 'is_predefini', 'user', 'created_at')
    list_filter = ('type', 'is_predefini')
    inlines = [ItineraireSegmentInline]
