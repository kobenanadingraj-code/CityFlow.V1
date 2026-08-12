from django.apps import AppConfig


class EnvironmentConfig(AppConfig):
    name = 'environment'

    def ready(self):
        from . import signals  # noqa: F401 — enregistre les receivers
