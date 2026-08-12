#!/bin/sh

echo "[CityFlow] Demarrage..."

MAX=6
I=0

until python manage.py migrate --noinput 2>&1; do
    I=$((I+1))

    if [ "$I" -ge "$MAX" ]; then
        echo "[CityFlow] Base de donnees inaccessible apres ${MAX} tentatives."
        echo "[CityFlow] Demarrage sans migration."
        break
    fi

    echo "[CityFlow] DB pas encore prete, nouvelle tentative dans 5s... ($I/$MAX)"
    sleep 5
done

SEGMENTS=$(python manage.py shell -c \
"from mobility.models import RoadSegment; print(RoadSegment.objects.count())" \
2>/dev/null) || SEGMENTS=""

if [ "$SEGMENTS" = "0" ]; then
    echo "[CityFlow] Premiere installation - chargement des donnees demo..."

    python manage.py import_osm_segments \
        --fichier /app/data/grand_abidjan.geojson

    python manage.py seed_demo_data \
        --users 100 \
        --days 30 \
        --seed 42

    python manage.py import_weather_history \
        --fichier /app/data/meteo_abidjan.json

    python manage.py seed_demo_reports --seed 42

    python manage.py recompute_predictions

    echo "[CityFlow] Donnees chargees !"
else
    echo "[CityFlow] Donnees deja presentes ($SEGMENTS segments). Skipping seed."
fi

echo "[CityFlow] Demarrage Gunicorn..."

exec gunicorn cityflow_backend.wsgi:application \
    --bind "0.0.0.0:${PORT:-8000}" \
    --workers 2 \
    --timeout 120