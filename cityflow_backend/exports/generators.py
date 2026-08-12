"""
Génération des fichiers pour l'écran 'Export des données'.

Les 4 types de données du modèle ExportJob sont maintenant tous gérés :
signalements, utilisateurs, alertes, statistiques.

⚠️ Génération synchrone : suffisant pour le volume de données du Vibeathon.
Si le volume grossit en prod, ça bloquera la requête HTTP le temps de la
génération — prévoir de passer sur une tâche asynchrone (Celery + Redis, ou
django-rq) à ce moment-là plutôt que d'optimiser cette version synchrone.
"""
import csv
import io

from django.core.files.base import ContentFile
from openpyxl import Workbook
from reportlab.lib import colors
from reportlab.lib.pagesizes import A4
from reportlab.platypus import SimpleDocTemplate, Table, TableStyle

from accounts.models import User
from dashboard.models import DailySnapshot
from environment.models import WeatherEvent
from reports.models import Report

_ENTETES = {
    'signalements': ['ID', 'Type', 'Zone', 'Adresse', 'Priorité', 'Statut', 'Date'],
    'utilisateurs': ['ID', 'Nom complet', 'Email', 'Téléphone', 'Zone', 'Rôle', 'Inscrit le'],
    'alertes': ['ID', 'Zone', 'Type', 'Condition', 'Intensité (mm/h)', 'Température (°C)', 'Date'],
    'statistiques': ['Date', 'Signalements du jour', 'Incidents actifs', 'Zones à risque', 'Utilisateurs actifs'],
}


def _lignes_signalements(debut, fin, filtres):
    qs = Report.objects.filter(created_at__date__gte=debut, created_at__date__lte=fin).select_related('segment')
    if filtres.get('type'):
        qs = qs.filter(type=filtres['type'])
    if filtres.get('statut'):
        qs = qs.filter(statut=filtres['statut'])
    if filtres.get('priorite'):
        qs = qs.filter(priorite=filtres['priorite'])
    if filtres.get('zone'):
        qs = qs.filter(zone__icontains=filtres['zone'])
    return [
        [r.id, r.get_type_display(), r.zone, r.adresse, r.get_priorite_display(),
         r.get_statut_display(), r.created_at.strftime('%d/%m/%Y %H:%M')]
        for r in qs
    ]


def _lignes_utilisateurs(debut, fin, filtres):
    qs = User.objects.filter(date_joined__date__gte=debut, date_joined__date__lte=fin)
    if filtres.get('zone'):
        qs = qs.filter(zone__icontains=filtres['zone'])
    if filtres.get('role'):
        qs = qs.filter(role=filtres['role'])
    return [
        [u.id, u.get_full_name() or u.username, u.email, u.telephone or '—', u.zone or '—',
         u.get_role_display(), u.date_joined.strftime('%d/%m/%Y')]
        for u in qs
    ]


def _lignes_alertes(debut, fin, filtres):
    qs = WeatherEvent.objects.exclude(type='normal').filter(
        timestamp__date__gte=debut, timestamp__date__lte=fin
    )
    if filtres.get('zone'):
        qs = qs.filter(zone__icontains=filtres['zone'])
    return [
        [w.id, w.zone, w.get_type_display(), w.get_condition_display(), w.intensite, w.temperature,
         w.timestamp.strftime('%d/%m/%Y %H:%M')]
        for w in qs
    ]


def _lignes_statistiques(debut, fin, filtres):
    qs = DailySnapshot.objects.filter(date__gte=debut, date__lte=fin)
    return [
        [s.date.strftime('%d/%m/%Y'), s.signalements_jour, s.incidents_actifs,
         s.zones_a_risque, s.utilisateurs_actifs]
        for s in qs
    ]


_LIGNES_PAR_TYPE = {
    'signalements': _lignes_signalements,
    'utilisateurs': _lignes_utilisateurs,
    'alertes': _lignes_alertes,
    'statistiques': _lignes_statistiques,
}


def _entetes_et_lignes(export_job):
    fn = _LIGNES_PAR_TYPE.get(export_job.type_donnees)
    if fn is None:
        raise NotImplementedError(f"Export de type '{export_job.type_donnees}' inconnu.")
    lignes = fn(export_job.periode_debut, export_job.periode_fin, export_job.filtres or {})
    return _ENTETES[export_job.type_donnees], lignes


def generate_csv(entetes, lignes):
    buf = io.StringIO()
    writer = csv.writer(buf)
    writer.writerow(entetes)
    writer.writerows(lignes)
    return ContentFile(buf.getvalue().encode('utf-8'), name='export.csv')


def generate_xlsx(entetes, lignes):
    wb = Workbook()
    ws = wb.active
    ws.append(entetes)
    for row in lignes:
        ws.append(row)
    buf = io.BytesIO()
    wb.save(buf)
    return ContentFile(buf.getvalue(), name='export.xlsx')


def generate_pdf(entetes, lignes):
    buf = io.BytesIO()
    doc = SimpleDocTemplate(buf, pagesize=A4)
    data = [entetes] + [[str(c) for c in row] for row in lignes]
    table = Table(data, repeatRows=1)
    table.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, 0), colors.HexColor('#4B0082')),
        ('TEXTCOLOR', (0, 0), (-1, 0), colors.white),
        ('GRID', (0, 0), (-1, -1), 0.5, colors.grey),
        ('FONTSIZE', (0, 0), (-1, -1), 8),
    ]))
    doc.build([table])
    return ContentFile(buf.getvalue(), name='export.pdf')


GENERATORS = {'csv': generate_csv, 'xlsx': generate_xlsx, 'pdf': generate_pdf}


def build_export(export_job):
    """Remplit export_job.fichier/taille_octets/statut. Lève si le type n'est pas géré."""
    entetes, lignes = _entetes_et_lignes(export_job)
    content_file = GENERATORS[export_job.format](entetes, lignes)
    export_job.fichier.save(content_file.name, content_file, save=False)
    export_job.taille_octets = content_file.size
    export_job.statut = 'termine'
    export_job.save(update_fields=['fichier', 'taille_octets', 'statut'])
