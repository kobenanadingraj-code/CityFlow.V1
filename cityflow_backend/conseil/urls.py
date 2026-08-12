from django.urls import path
from .views import conseil_trajet, trajet_libre, itineraires_recommandes

urlpatterns = [
    path('', conseil_trajet, name='conseil-corridors'),
    path('trajet/', trajet_libre, name='conseil-trajet-libre'),
    path('itineraires-recommandes/', itineraires_recommandes, name='conseil-itineraires-recommandes'),
]
