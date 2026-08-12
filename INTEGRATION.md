# Intégrer la refonte dans ton repo

Ce dossier contient maintenant le backend Django complet, données comprises : les 8 apps (`accounts`, `mobility`, `environment`, `reports`, `conseil`, `dashboard`, `notifications`, `exports`), le pipeline de données (management commands), `manage.py`, `Dockerfile`, `start.sh`, `docker-compose.yml`, `requirements.txt`, plus `model.pkl`, `lookup.npy`, `grand_abidjan.geojson` et `meteo_abidjan.json` que tu as ajoutés.

## 1. Copier les fichiers
Remplace intégralement `cityflow_backend/` de ton repo par celui-ci. `notifications/` et `exports/` sont entièrement nouvelles. `grand_abidjan.geojson` et `meteo_abidjan.json` vont dans un dossier `data/` à la racine du repo (à côté de `docker-compose.yml`) — c'est là que Dockerfile/start.sh les cherchent maintenant.

⚠️ `data/meteo_abidjan.json` a été replacé ici. `grand_abidjan.geojson` est trop volumineux pour que je puisse le déplacer moi-même (mon bac à sable shell est indisponible et le fichier dépasse ce que je peux relire) — déplace-le toi-même de la racine du dossier vers `data/grand_abidjan.geojson`, et supprime la copie à la racine une fois le déplacement fait.

## 2. Bug corrigé au passage
`mobility/ml/predictor.py` filtrait les signalements actifs avec `statut='actif'` — un choix qui n'existe plus dans le nouveau modèle `Report` (`nouveau/en_cours/resolu/en_attente`). Corrigé en `statut__in=['nouveau', 'en_cours']`. Sans ce correctif, le bonus de congestion lié aux signalements (`POIDS_SIGNALEMENT`) ne se serait plus jamais appliqué, silencieusement.

`import_weather_history.py` a aussi été ajusté : ton `meteo_abidjan.json` (export Open-Meteo réel) a des timestamps horaires sans secondes (`"2026-06-08T00:00"`), un format que `datetime.fromisoformat()` ne sait lire qu'à partir de Python 3.11. Remplacé par `strptime` pour marcher sur toutes les versions.

## 3. Dépendances
`requirements.txt` complété : Pillow (avatars/photos), requests (client OSRM), openpyxl/reportlab (exports Excel/PDF).

## 4. Lancer en local (sans Docker)

```
cd cityflow_backend
python3 -m venv .venv && source .venv/bin/activate
pip install -r ../requirements.txt

export SECRET_KEY=$(python -c "import secrets; print(secrets.token_hex(50))")
export DEBUG=True

# Migrations — reports/environment/accounts/conseil/dashboard ont des modèles
# modifiés ou nouveaux, mobility est inchangée
rm reports/migrations/0*.py 2>/dev/null
python manage.py makemigrations accounts reports environment conseil dashboard notifications exports mobility
python manage.py migrate

# Pipeline de données (ordre obligatoire, fichiers dans data/ à la racine du repo)
python manage.py import_osm_segments --fichier ../data/grand_abidjan.geojson
python manage.py seed_demo_data --users 100 --days 30 --seed 42
python manage.py import_weather_history --fichier ../data/meteo_abidjan.json
python manage.py seed_demo_reports --seed 42
python manage.py recompute_predictions

# Vérification
python manage.py check_demo_readiness

# Compte autorité pour tester le dashboard
python manage.py createsuperuser

python manage.py runserver
```

`model.pkl`/`lookup.npy` sont déjà en place (`mobility/ml/`) — le predictor les charge automatiquement au démarrage, pas d'action requise.

## 5. OSRM (moteur de routing — écran Trajet)
Optionnel pour un premier test local :
```
bash scripts/prepare_osrm_data.sh   # une fois, télécharge + construit le graphe
docker compose up osrm -d
export OSRM_URL=http://localhost:5001
```
Sans ça, `/api/conseil/trajet/` et `/api/conseil/itineraires-recommandes/` répondent 503 proprement, le reste de l'API fonctionne normalement.

## 6. Tâche quotidienne
`python manage.py recompute_daily_snapshot` doit tourner une fois par jour (cron) pour que les KPIs du Tableau de bord affichent une variation "vs hier".

## 7. Ce qui reste volontairement de côté
- `tests.py` de chaque app (ex. `mobility/tests.py`, ~9.7 Ko de tests existants) — non reconstitués ici pour éviter de deviner du contenu non vérifié ; garde ceux de ton clone
- `render.yaml`, `.github/workflows/ci.yml`, `CHANGELOG.md`, `.flake8` — non touchés, à garder tels quels depuis ton repo
- Frontend Flutter — pas commencé

## 8. Notifications et activité récente — maintenant automatiques
`reports/signals.py`, `accounts/signals.py`, `environment/signals.py` (+ `ready()` ajouté dans les `apps.py` correspondants) peuplent `ActivityLog` et `Notification` automatiquement :
- Nouveau signalement → ActivityLog + notification des utilisateurs qui surveillent cette zone
- Signalement passé à "résolu" → ActivityLog + notification à l'auteur
- Nouvelle inscription → ActivityLog
- Alerte météo (pluie modérée/forte) → ActivityLog + notification des utilisateurs qui surveillent la zone

Ces signaux ne se déclenchent PAS sur les `bulk_create()` des commandes de seed (comportement standard Django) — voulu, pour ne pas noyer l'activité sous des centaines d'entrées de démo. Seules les créations via l'API (vraies inscriptions, vrais signalements) les déclenchent.

## 9. Export — les 4 types sont maintenant gérés
`exports/generators.py` génère désormais `signalements`, `utilisateurs`, `alertes` et `statistiques` (ce dernier à partir de `DailySnapshot` — pense à faire tourner `recompute_daily_snapshot` sur quelques jours pour avoir de la matière à exporter).
