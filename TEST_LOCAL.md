# Tester CityFlow AI en local (backend + app Flutter)

Guide pas à pas pour lancer le backend Django en local (SQLite, pas besoin de Docker/Postgres) et l'app Flutter dessus, dans l'ordre.

Arborescence utile (racine du dossier `CityFlow`) :

```
CityFlow/
├── requirements.txt
├── data/
│   ├── grand_abidjan.geojson
│   └── meteo_abidjan.json
├── cityflow_backend/      ← manage.py est ici
└── cityflow_app/          ← projet Flutter
```

---

## Partie A — Backend Django

### 1. Environnement virtuel + dépendances

Ouvre un terminal (PowerShell) à la racine `CityFlow/` :

```powershell
cd C:\Users\HP\CityFlow
python -m venv venv
venv\Scripts\Activate.ps1
pip install -r requirements.txt
```

Si PowerShell bloque le script d'activation, lance d'abord :
`Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass`

### 2. Variables d'environnement (session courante)

`settings.py` exige `SECRET_KEY` — sans elle, Django refuse de démarrer. Toujours dans le même terminal :

```powershell
$env:SECRET_KEY = "dev-secret-key-changeme"
$env:DEBUG = "True"
```

(`DEBUG=True` est déjà la valeur par défaut, mais autant être explicite. Pas besoin de `DATABASE_URL` : sans elle, Django utilise SQLite automatiquement — un simple fichier `db.sqlite3`.)

### 3. Migrations

```powershell
cd cityflow_backend
python manage.py migrate
```

### 4. Chargement des données de démo (dans cet ordre précis — chaque commande dépend de la précédente)

```powershell
python manage.py import_osm_segments --fichier ..\data\grand_abidjan.geojson
python manage.py seed_demo_data --users 100 --days 30 --seed 42
python manage.py import_weather_history --fichier ..\data\meteo_abidjan.json
python manage.py seed_demo_reports --seed 42
python manage.py recompute_predictions
```

### 5. Vérifier que tout est prêt

```powershell
python manage.py check_demo_readiness
```

Tu dois voir des ✓ partout (segments importés, météo réelle chargée, prédictions récentes, signalements de seed).

### 6. Créer un compte pour te connecter

```powershell
python manage.py createsuperuser
```

Renseigne un email et un mot de passe — c'est ce compte que tu utiliseras pour te connecter depuis l'app.

**Important** : les 100 utilisateurs générés par `seed_demo_data` n'ont **pas** de mot de passe utilisable (créés en masse sans `set_password`) — impossible de se connecter avec eux. Pour tester le parcours **citoyen**, crée un compte directement depuis l'écran "Créer un compte" de l'app (il fonctionne normalement). Pour tester le **dashboard autorité**, utilise le superuser créé ci-dessus et passe son rôle en `autorite` :

1. Démarre le serveur (étape 7).
2. Va sur `http://127.0.0.1:8000/admin/`, connecte-toi avec le superuser.
3. Section **Users** → ouvre ton compte → change `role` de `citoyen` à `autorite` → enregistre.
4. Connecte-toi avec cet email/mot de passe dans l'app : tu arriveras directement sur le dashboard web au lieu de l'app mobile.

### 7. Lancer le serveur

```powershell
python manage.py runserver 0.0.0.0:8000
```

Le `0.0.0.0` (plutôt que le défaut `127.0.0.1`) permet aussi de tester depuis un vrai téléphone sur le même réseau Wi-Fi, en plus de l'émulateur.

Laisse ce terminal ouvert pendant tous tes tests.

---

## Partie B — App Flutter

Dans un **second terminal** :

```powershell
cd C:\Users\HP\CityFlow\cityflow_app
flutter pub get
```

### Lancer sur émulateur Android

Ouvre l'émulateur depuis Android Studio (ou `flutter emulators --launch <id>`), puis :

```powershell
flutter run
```

Par défaut l'app pointe vers `http://10.0.2.2:8000` — l'adresse spéciale que l'émulateur Android utilise pour joindre le `localhost` de ta machine. Comme le serveur Django tourne en local à l'étape précédente, ça fonctionne sans rien configurer de plus.

### Lancer sur simulateur iOS (si tu es sur Mac)

`10.0.2.2` ne fonctionne pas sur iOS — il faut pointer explicitement vers ta machine :

```powershell
flutter run --dart-define=API_BASE_URL=http://127.0.0.1:8000
```

### Lancer le dashboard web (Flutter web)

```powershell
flutter run -d chrome --dart-define=API_BASE_URL=http://127.0.0.1:8000
```

Connecte-toi avec le compte `autorite` créé plus haut pour voir directement le dashboard.

---

## Ce qui ne sera pas testable sans configuration supplémentaire

- **Écran Trajet / itinéraires recommandés (Carte)** : nécessitent OSRM (moteur de routing), qui n'est pas lancé par cette procédure. Sans lui, l'app affiche un message "service indisponible" au lieu de planter — c'est le comportement attendu. Pour l'activer : `docker-compose.yml` + `scripts/prepare_osrm_data.sh` à la racine du dossier (nécessite Docker et le téléchargement d'un extrait OSM de ~200 Mo — étape optionnelle, à faire seulement si tu veux tester le calcul d'itinéraire réel).
- **Upload de photo sur un signalement** : fonctionne normalement, mais nécessite d'autoriser l'accès aux photos/à la caméra sur l'émulateur si demandé.

## En cas de blocage

Si une commande échoue avec une erreur `ModuleNotFoundError`, vérifie que le venv est bien activé (`(venv)` doit apparaître au début de la ligne de commande). Si `flutter run` échoue sur un asset manquant, vérifie que `cityflow_app/assets/images/logo_cityflow.svg` existe bien — c'est le seul asset local requis désormais (les polices Inter sont téléchargées automatiquement via `google_fonts`).
