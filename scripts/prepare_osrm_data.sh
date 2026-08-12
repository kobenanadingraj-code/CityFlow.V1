#!/usr/bin/env bash
# Prépare le graphe de routing OSRM pour Abidjan.
#
# À lancer UNE FOIS (et à refaire seulement si la carte doit être mise à jour),
# avant de démarrer le service `osrm` de docker-compose.yml. Ce n'est PAS un
# service qui tourne en continu — c'est un traitement offline qui produit des
# fichiers .osrm* consommés ensuite par osrm-routed.
#
# Prérequis : Docker. Aucune dépendance locale nécessaire (tout tourne dans
# le conteneur officiel project-osrm/osrm-backend).
#
# Pourquoi un fichier différent du GeoJSON déjà utilisé par import_osm_segments :
# OSRM a besoin de la topologie complète du réseau routier (noeuds, voies,
# intersections, sens de circulation) au format .osm.pbf, alors que le GeoJSON
# actuel ne contient que les segments déjà filtrés/simplifiés pour la DB
# CityFlow. Ce sont deux usages différents de données OSM.

set -euo pipefail

DATA_DIR="$(dirname "$0")/../osrm_data"
PBF_URL="https://download.geofabrik.de/africa/ivory-coast-latest.osm.pbf"
PBF_FILE="$DATA_DIR/ivory-coast-latest.osm.pbf"

mkdir -p "$DATA_DIR"

if [ ! -f "$PBF_FILE" ]; then
  echo "Téléchargement de l'extrait Côte d'Ivoire depuis Geofabrik..."
  curl -L -o "$PBF_FILE" "$PBF_URL"
fi

echo "Extraction (profil voiture)..."
docker run --rm -v "$DATA_DIR:/data" ghcr.io/project-osrm/osrm-backend \
  osrm-extract -p /opt/car.lua /data/ivory-coast-latest.osm.pbf

echo "Partition (MLD)..."
docker run --rm -v "$DATA_DIR:/data" ghcr.io/project-osrm/osrm-backend \
  osrm-partition /data/ivory-coast-latest.osrm

echo "Customize (MLD)..."
docker run --rm -v "$DATA_DIR:/data" ghcr.io/project-osrm/osrm-backend \
  osrm-customize /data/ivory-coast-latest.osrm

mv "$DATA_DIR/ivory-coast-latest.osrm"* "$DATA_DIR/abidjan.osrm" 2>/dev/null || true
for f in "$DATA_DIR"/ivory-coast-latest.osrm.*; do
  [ -e "$f" ] && mv "$f" "$DATA_DIR/abidjan.osrm.${f##*.}"
done

echo "Terminé. Lancez maintenant : docker compose up osrm -d"
