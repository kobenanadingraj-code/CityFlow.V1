"""
Crée des signalements de seed pour que le dashboard autorités ne soit pas vide à l'ouverture.
Ces signalements sont DISTINCTS du signalement fait en direct pendant la démo jury.
Doit être lancé après seed_demo_data.

Mis à jour pour le nouveau modèle Report (types/statuts alignés sur la maquette
Figma — voir REFONTE_MODELE_DONNEES.md). Toujours reproductible avec --seed 42.
"""
import random
from django.core.management.base import BaseCommand, CommandError

from accounts.models import User
from mobility.models import RoadSegment
from reports.models import Report, classify_priority


class Command(BaseCommand):
    help = "Crée des signalements de demo (seed). Distincts du signalement live en démo."

    def add_arguments(self, parser):
        parser.add_argument('--count', type=int, default=8)
        parser.add_argument('--seed', type=int, default=42)

    def handle(self, *args, **options):
        count = options['count']
        seed = options['seed']
        rng = random.Random(seed)

        users = list(User.objects.filter(role='citoyen'))
        if not users:
            raise CommandError("Aucun utilisateur citoyen trouvé. Lancez d'abord seed_demo_data.")

        segments = list(RoadSegment.objects.filter(source_geometrie='osm'))
        if not segments:
            raise CommandError("Aucun segment OSM trouvé. Lancez d'abord import_osm_segments.")

        types = ['accident', 'embouteillage', 'inondation', 'travaux', 'autre']
        statuts = ['nouveau', 'nouveau', 'en_cours', 'en_attente', 'resolu']
        reports = []
        for i in range(count):
            type_incident = rng.choice(types)
            statut = rng.choice(statuts)
            segment = rng.choice(segments)
            report = Report(
                user=rng.choice(users),
                segment=segment,
                zone=segment.zone,
                adresse=f"{segment.nom}, {segment.zone}",
                latitude=segment.latitude,
                longitude=segment.longitude,
                type=type_incident,
                priorite=classify_priority(type_incident),
                statut=statut,
                nb_confirmations=rng.randint(1, 4),
            )
            reports.append(report)

        Report.objects.bulk_create(reports)

        self.stdout.write(self.style.SUCCESS(
            f"{count} signalements de seed créés (seed={seed})."
        ))
