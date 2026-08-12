# Arborescence du backend refait

Légende :
- `[NOUVEAU]` — n'existait pas avant, à ajouter
- `[MODIFIÉ]` — existait, contenu changé pour coller à la maquette
- `[INCHANGÉ]` — copié tel quel depuis ton repo, aucune action
- `[À RÉGÉNÉRER]` — dossier migrations à recréer (`makemigrations`)
- `[FOURNI PAR TOI]` — fichier binaire/données que tu as ajouté toi-même

```
nexus-2/                                          racine du repo
├── data/
│   ├── grand_abidjan.geojson                     [FOURNI PAR TOI — à déplacer ici toi-même]
│   └── meteo_abidjan.json                        [FOURNI PAR TOI]
├── docker-compose.yml                             [MODIFIÉ]        + service osrm
├── requirements.txt                               [MODIFIÉ]        + Pillow, requests, openpyxl, reportlab
├── .env.example                                   [MODIFIÉ]        + OSRM_URL
├── scripts/
│   └── prepare_osrm_data.sh                       [NOUVEAU]
│
└── cityflow_backend/
    ├── manage.py                                  [INCHANGÉ]
    ├── Dockerfile                                 [MODIFIÉ]        chemins données déplacés
    ├── start.sh                                   [MODIFIÉ]        idem
    │
    ├── cityflow_backend/                          (settings du projet)
    │   ├── __init__.py                            [INCHANGÉ]
    │   ├── settings.py                            [MODIFIÉ]        +apps, +MEDIA_URL/ROOT, +OSRM
    │   ├── urls.py                                [MODIFIÉ]        +routes notifications/exports, +media
    │   ├── wsgi.py                                [INCHANGÉ]
    │   └── asgi.py                                [INCHANGÉ]
    │
    ├── accounts/
    │   ├── __init__.py                            [INCHANGÉ]
    │   ├── apps.py                                [MODIFIÉ]        +ready() enregistre signals.py
    │   ├── admin.py                               [MODIFIÉ]        +telephone/adresse/avatar, +3 admins
    │   ├── models.py                              [MODIFIÉ]        +telephone/adresse/avatar
    │   │                                                            +SavedPlace, UserPreferences, ZoneSurveillee
    │   ├── serializers.py                         [MODIFIÉ]        login email/téléphone, inscription, profil
    │   ├── views.py                                [MODIFIÉ]
    │   ├── urls.py                                 [MODIFIÉ]        +me/lieux, +me/zones-surveillees, +preferences
    │   ├── signals.py                              [NOUVEAU]        ActivityLog auto à l'inscription
    │   ├── throttles.py                            [INCHANGÉ]
    │   └── migrations/                             [À RÉGÉNÉRER]
    │
    ├── conseil/
    │   ├── __init__.py                             [INCHANGÉ]
    │   ├── apps.py                                 [INCHANGÉ]
    │   ├── admin.py                                [NOUVEAU]
    │   ├── models.py                               [NOUVEAU]        l'app n'avait aucun modèle avant
    │   ├── corridors.py                            [INCHANGÉ]
    │   ├── routing.py                              [NOUVEAU]        client OSRM
    │   ├── matching.py                             [NOUVEAU]        rattachement segments ↔ tracé OSRM
    │   ├── views.py                                [MODIFIÉ]        +trajet_libre, +itineraires_recommandes
    │   ├── urls.py                                 [MODIFIÉ]
    │   └── migrations/                             [À RÉGÉNÉRER]
    │
    ├── dashboard/
    │   ├── __init__.py                             [INCHANGÉ]
    │   ├── apps.py                                 [INCHANGÉ]
    │   ├── permissions.py                          [INCHANGÉ]
    │   ├── models.py                               [NOUVEAU]        DailySnapshot, ActivityLog
    │   ├── views.py                                [MODIFIÉ]        retrait export CSV, +4 endpoints KPI/carte
    │   ├── urls.py                                 [MODIFIÉ]
    │   ├── management/
    │   │   ├── __init__.py                         [NOUVEAU]
    │   │   └── commands/
    │   │       ├── __init__.py                     [NOUVEAU]
    │   │       └── recompute_daily_snapshot.py      [NOUVEAU]
    │   └── migrations/                             [À RÉGÉNÉRER]
    │
    ├── environment/
    │   ├── __init__.py                             [INCHANGÉ]
    │   ├── apps.py                                 [MODIFIÉ]        +ready() enregistre signals.py
    │   ├── admin.py                                [MODIFIÉ]        +condition, +temperature
    │   ├── models.py                               [MODIFIÉ]        +condition, +temperature
    │   ├── serializers.py                          [MODIFIÉ]
    │   ├── views.py                                [INCHANGÉ]
    │   ├── urls.py                                 [INCHANGÉ]
    │   ├── signals.py                              [NOUVEAU]        ActivityLog + Notification sur alerte météo
    │   ├── management/
    │   │   ├── __init__.py                         [INCHANGÉ]
    │   │   └── commands/
    │   │       ├── __init__.py                     [INCHANGÉ]
    │   │       └── import_weather_history.py       [MODIFIÉ]        parsing timestamps sans secondes
    │   └── migrations/                             [À RÉGÉNÉRER]
    │
    ├── exports/                                    [NOUVELLE APP]
    │   ├── __init__.py
    │   ├── apps.py
    │   ├── models.py                                ExportJob
    │   ├── serializers.py
    │   ├── generators.py                            CSV/Excel/PDF — signalements, utilisateurs, alertes, statistiques
    │   ├── views.py
    │   ├── urls.py
    │   └── migrations/                              [À GÉNÉRER]
    │
    ├── mobility/
    │   ├── __init__.py                             [INCHANGÉ]
    │   ├── apps.py                                 [INCHANGÉ]
    │   ├── admin.py                                [INCHANGÉ]
    │   ├── models.py                               [INCHANGÉ]       aucun changement de modèle
    │   ├── serializers.py                          [INCHANGÉ]
    │   ├── throttles.py                            [INCHANGÉ]
    │   ├── views.py                                [MODIFIÉ]        +CartePrevisionsView
    │   ├── urls.py                                 [MODIFIÉ]        +previsions/
    │   ├── aggregation.py                          [NOUVEAU]        heures de pointe, zones à risque
    │   ├── ml/
    │   │   ├── __init__.py                         [INCHANGÉ]
    │   │   ├── predictor.py                        [MODIFIÉ]        bug statut='actif' corrigé
    │   │   ├── weights.py                          [INCHANGÉ]
    │   │   ├── model.pkl                           [FOURNI PAR TOI]
    │   │   └── lookup.npy                          [FOURNI PAR TOI]
    │   ├── management/
    │   │   ├── __init__.py                         [INCHANGÉ]
    │   │   └── commands/
    │   │       ├── __init__.py                     [INCHANGÉ]
    │   │       ├── import_osm_segments.py          [INCHANGÉ]
    │   │       ├── seed_demo_data.py                [INCHANGÉ]
    │   │       ├── seed_traffic_minimal.py          [INCHANGÉ]
    │   │       ├── recompute_predictions.py         [INCHANGÉ]
    │   │       ├── check_demo_readiness.py          [INCHANGÉ]
    │   │       ├── fix_zones.py                     [INCHANGÉ]
    │   │       ├── train_model.py                   [INCHANGÉ]
    │   │       └── deduplicate_perfect_segments.py  [INCHANGÉ]
    │   ├── tests.py                                [GARDER LE TIEN — non reconstitué ici]
    │   └── migrations/                             [GARDER LES TIENNES — inchangées]
    │
    ├── notifications/                              [NOUVELLE APP]
    │   ├── __init__.py
    │   ├── apps.py
    │   ├── models.py                                Notification
    │   ├── serializers.py
    │   ├── views.py
    │   ├── urls.py
    │   └── migrations/                              [À GÉNÉRER]
    │
    └── reports/
        ├── __init__.py                             [INCHANGÉ]
        ├── apps.py                                 [MODIFIÉ]        +ready() enregistre signals.py
        ├── admin.py                                [MODIFIÉ]        gravite → priorite
        ├── permissions.py                          [INCHANGÉ]
        ├── throttles.py                            [INCHANGÉ]
        ├── models.py                               [MODIFIÉ]        types/statuts/priorité alignés maquette
        ├── serializers.py                          [MODIFIÉ]
        ├── views.py                                 [MODIFIÉ]
        ├── pagination.py                            [NOUVEAU]
        ├── signals.py                               [NOUVEAU]        ActivityLog + Notification auto
        ├── urls.py                                  [INCHANGÉ]
        ├── management/
        │   ├── __init__.py
        │   └── commands/
        │       ├── __init__.py
        │       └── seed_demo_reports.py             [MODIFIÉ]       nouveaux types/statuts
        └── migrations/                              [À SUPPRIMER PUIS RÉGÉNÉRER]
```

## Ce qui n'apparaît volontairement pas dans ce dossier

- `tests.py` de chaque app — garde ceux de ton clone
- `render.yaml`, `.github/workflows/ci.yml`, `CHANGELOG.md`, `.flake8`, `README.md`, `CLAUDE.md` — non touchés
- Les migrations elles-mêmes (fichiers `0001_initial.py` etc.) — générées chez toi, pas ici

Le reste des instructions (ordre des commandes, variables d'environnement, OSRM) est dans `INTEGRATION.md`.
