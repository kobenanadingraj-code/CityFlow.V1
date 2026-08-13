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

echo "[CityFlow] Collecte des fichiers statiques..."
python manage.py collectstatic --noinput

echo "[CityFlow] Demarrage Gunicorn..."

exec gunicorn cityflow_backend.wsgi:application \
    --bind "0.0.0.0:${PORT:-8000}" \
    --workers 2 \
    --timeout 120