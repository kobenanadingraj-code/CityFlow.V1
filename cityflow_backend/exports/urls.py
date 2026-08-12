from django.urls import path
from .views import ExportJobListCreateView

urlpatterns = [
    path('', ExportJobListCreateView.as_view(), name='export-list-create'),
]
