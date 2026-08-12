"""
accounts.models — refonte alignée sur les écrans Figma :
  - Créer un compte (nom complet, email, téléphone, mot de passe)
  - Bienvenue / Connexion (email OU téléphone + mot de passe)
  - Profil (avatar, infos perso, lieux enregistrés, préférences, zones à surveiller)

Changements vs version actuelle :
  - + telephone (unique, utilisé pour la connexion alternative à l'email)
  - + adresse, avatar (affichés dans Profil > Informations personnelles)
  - + SavedPlace (Profil > "Mes lieux enregistrés" : Maison / Travail / Favoris / Autre)
  - + UserPreferences (Profil > "Préférences" : notifications, mode de trajet)
  - + ZoneSurveillee (Profil > "Zones à surveiller")
  - `role` conservé (citoyen/autorite) — distingue app mobile (citoyen) et dashboard web (autorite)
"""
from django.contrib.auth.models import AbstractUser
from django.db import models


class User(AbstractUser):
    ROLE_CHOICES = [('citoyen', 'Citoyen'), ('autorite', 'Autorité')]

    role = models.CharField(max_length=20, choices=ROLE_CHOICES, default='citoyen')
    telephone = models.CharField(max_length=20, unique=True, null=True, blank=True)
    adresse = models.CharField(max_length=255, blank=True)
    avatar = models.ImageField(upload_to='avatars/', blank=True, null=True)
    zone = models.CharField(max_length=100, blank=True)

    def __str__(self):
        return self.get_full_name() or self.username


class SavedPlace(models.Model):
    """Écran Profil > 'Mes lieux enregistrés' (Maison, Travail, Favoris, Autres)."""
    TYPE_CHOICES = [
        ('maison', 'Maison'),
        ('travail', 'Travail'),
        ('favori', 'Favori'),
        ('autre', 'Autre'),
    ]

    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='lieux')
    type = models.CharField(max_length=10, choices=TYPE_CHOICES)
    label = models.CharField(max_length=100, blank=True)  # nom libre si type='autre'
    adresse = models.CharField(max_length=255)
    latitude = models.FloatField()
    longitude = models.FloatField()
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['type', '-created_at']

    def __str__(self):
        return f"{self.get_type_display()} — {self.user}"


class UserPreferences(models.Model):
    """Écran Profil > 'Préférences' (notifications, préférences de trajet)."""
    MODE_TRANSPORT_CHOICES = [
        ('voiture', 'Voiture'),
        ('moto', 'Moto'),
        ('pied', 'À pied'),
        ('transport_commun', 'Transport en commun'),
    ]

    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='preferences')
    notifications_actives = models.BooleanField(default=True)
    mode_transport = models.CharField(max_length=20, choices=MODE_TRANSPORT_CHOICES, default='voiture')
    eviter_zones_inondables = models.BooleanField(default=True)
    eviter_peages = models.BooleanField(default=False)

    def __str__(self):
        return f"Préférences {self.user}"


class ZoneSurveillee(models.Model):
    """Écran Profil > 'Zones à surveiller' — alertes push ciblées par zone."""
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='zones_surveillees')
    zone = models.CharField(max_length=100)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ('user', 'zone')

    def __str__(self):
        return f"{self.user} surveille {self.zone}"
