"""
Reclasse la commune (`zone`) de tous les segments existants sans réimporter
le GeoJSON — utile pour corriger en place les segments déjà en base après un
changement de logique de classification (mobility/geo_zones.py).

Recalcule aussi zone_inondable.
"""
from django.core.management.base import BaseCommand

from mobility.models import RoadSegment
from mobility.geo_zones import classify_commune, is_inondable


class Command(BaseCommand):
    help = "Reclasse zone/zone_inondable de tous les RoadSegment (nom puis coordonnées)"

    def add_arguments(self, parser):
        parser.add_argument('--dry-run', action='store_true')

    def handle(self, *args, **options):
        dry_run = options['dry_run']

        segments = list(RoadSegment.objects.all())
        total = len(segments)
        self.stdout.write(f"Segments à traiter : {total}")

        commune_counts = {}
        to_update = []

        for seg in segments:
            new_zone = classify_commune(seg.nom, seg.latitude, seg.longitude)
            new_inondable = is_inondable(new_zone)
            if new_zone != seg.zone or new_inondable != seg.zone_inondable:
                seg.zone = new_zone
                seg.zone_inondable = new_inondable
                to_update.append(seg)
            commune_counts[new_zone] = commune_counts.get(new_zone, 0) + 1

        self.stdout.write("Distribution après correction :")
        for commune, count in sorted(commune_counts.items(), key=lambda x: -x[1]):
            self.stdout.write(f"  {commune}: {count}")

        self.stdout.write(f"Segments à mettre à jour : {len(to_update)}")

        if dry_run:
            self.stdout.write(self.style.WARNING("--dry-run : aucune écriture."))
            return

        BATCH = 1_000
        updated = 0
        for i in range(0, len(to_update), BATCH):
            chunk = to_update[i:i + BATCH]
            RoadSegment.objects.bulk_update(chunk, ['zone', 'zone_inondable'])
            updated += len(chunk)

        self.stdout.write(self.style.SUCCESS(f"fix_zones terminé : {updated} segments corrigés."))
