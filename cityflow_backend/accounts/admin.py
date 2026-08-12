from django.contrib import admin
from django.contrib.auth.admin import UserAdmin
from .models import User, SavedPlace, UserPreferences, ZoneSurveillee


@admin.register(User)
class CustomUserAdmin(UserAdmin):
    list_display = ('username', 'email', 'telephone', 'role', 'zone', 'is_active')
    list_filter = ('role', 'is_active')
    fieldsets = UserAdmin.fieldsets + (
        ('CityFlow', {'fields': ('role', 'zone', 'telephone', 'adresse', 'avatar')}),
    )


@admin.register(SavedPlace)
class SavedPlaceAdmin(admin.ModelAdmin):
    list_display = ('user', 'type', 'label', 'adresse')
    list_filter = ('type',)


@admin.register(UserPreferences)
class UserPreferencesAdmin(admin.ModelAdmin):
    list_display = ('user', 'notifications_actives', 'mode_transport')


@admin.register(ZoneSurveillee)
class ZoneSurveilleeAdmin(admin.ModelAdmin):
    list_display = ('user', 'zone', 'created_at')
