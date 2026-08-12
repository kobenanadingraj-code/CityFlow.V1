from django.contrib import admin
from .models import WeatherEvent


@admin.register(WeatherEvent)
class WeatherEventAdmin(admin.ModelAdmin):
    list_display = ('zone', 'type', 'condition', 'temperature', 'intensite', 'timestamp', 'source')
    list_filter = ('type', 'condition', 'source', 'zone')
