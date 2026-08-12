from rest_framework.pagination import PageNumberPagination


class ReportPagination(PageNumberPagination):
    """Dashboard 'Gestion des signalements' : '10 par page' sélectionnable, jusqu'à 100."""
    page_size = 10
    page_size_query_param = 'page_size'
    max_page_size = 100
