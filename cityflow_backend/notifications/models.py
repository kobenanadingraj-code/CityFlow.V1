"""
notifications.models — nouvelle app, nécessaire pour :
  - la cloche avec badge sur Accueil et Profil (app mobile)
  - déclenchées par : nouveau signalement dans une zone surveillée
    (accounts.ZoneSurveillee), changement de statut d'un signalement que
    l'utilisateur a créé, alerte météo forte sur une zone surveillée.

N'existait pas du tout dans le backend actuel.
"""
from django.conf import settings
from django.db import models


class Notification(models.Model):
    TYPE_CHOICES = [
        ('alerte', 'Alerte'),
        ('signalement', 'Signalement'),
        ('systeme', 'Système'),
    ]

    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='notifications')
    type = models.CharField(max_length=15, choices=TYPE_CHOICES)
    titre = models.CharField(max_length=150)
    message = models.CharField(max_length=500)
    lu = models.BooleanField(default=False)
    # référence libre vers l'objet source, ex: "report:42", "weather:cocody"
    lien_objet = models.CharField(max_length=100, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-created_at']
        indexes = [models.Index(fields=['user', 'lu'])]

    def __str__(self):
        return f"[{self.type}] {self.titre} → {self.user}"
