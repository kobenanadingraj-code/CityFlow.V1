# Refonte backend CityFlow AI — modèle de données v2

Basé sur l'inspection du repo `herverenard147/nexus-2` (branche `main`) et de la maquette Figma "2 eme maquette CityFlow".

## Fichiers livrés dans ce dossier

```
cityflow_backend/
  accounts/models.py       (réécrit)
  reports/models.py        (réécrit)
  environment/models.py    (réécrit)
  conseil/models.py        (nouveau — l'app existait mais n'avait pas de models.py)
  dashboard/models.py      (nouveau — l'app n'avait aucun modèle avant)
  notifications/models.py  (nouvelle app)
  exports/models.py        (nouvelle app)
```

`mobility/models.py` n'a pas besoin de changer — `RoadSegment`, `TrafficRecord`, `Prediction` couvrent déjà l'écran Carte et le moteur ML.

## Mapping écran → app → modèle

| Écran Figma | App Django | Modèle(s) |
|---|---|---|
| Créer un compte / Connexion | accounts | User (+ telephone) |
| Profil | accounts | User, SavedPlace, UserPreferences, ZoneSurveillee |
| Accueil (météo, trafic, cloche) | environment, mobility, notifications | WeatherEvent, Prediction, Notification |
| Alertes + Envoyer un signalement | reports | Report |
| Trajet | conseil, mobility | Itineraire, ItineraireSegment |
| Carte | mobility, conseil | Prediction (agrégée par zone/heure), Itineraire (prédéfinis) |
| Tableau de bord (dashboard web) | dashboard, reports, mobility | DailySnapshot, ActivityLog |
| Gestion des signalements (dashboard web) | reports | Report (déjà couvert, filtres à ajouter côté vue) |
| Export des données (dashboard web) | exports | ExportJob |

## Deux décisions à trancher avant la suite

**1. Moteur de routing pour l'écran Trajet.**
Le backend actuel (`conseil/corridors.py`) ne calcule pas de durée/distance réelles — seulement un niveau de trafic qualitatif sur 4 corridors codés en dur. La maquette montre "32 min · 12.4 km" pour une recherche libre ("Où allez-vous ?"). Sans moteur de routing (OSRM auto-hébergé sur les données OSM déjà importées, ou API tierce), on ne peut afficher que le niveau de trafic, pas des temps/distances fiables sur un trajet quelconque. Le modèle `Itineraire` est conçu pour marcher dans les deux cas (`distance_km`/`duree_min` nullable), mais il faut savoir si on ajoute OSRM ou si on limite au départ aux itinéraires prédéfinis (comme l'écran Carte, qui montre "Domicile → Travail" etc., faisable dès maintenant).

**2. Changement de valeurs sur `Report` (breaking change).**
Les types (`accident/nid_de_poule/route_barree/vehicule_en_panne` → `accident/embouteillage/inondation/travaux/autre`) et statuts (`actif/fusionne/resolu` → `nouveau/en_cours/resolu/en_attente`) changent pour coller exactement aux filtres et icônes de la maquette. Si des données de démo existent déjà en base (seed du Vibeathon), elles ne matcheront plus ces choices — il faudra soit les re-seed, soit écrire une migration de données.

## Prochaine étape

Une fois ce modèle validé : serializers + views + urls pour chaque app (accounts, reports, environment, conseil, dashboard, notifications, exports), + migrations, + mise à jour de `INSTALLED_APPS` et `cityflow_backend/urls.py` pour brancher `notifications` et `exports`.
