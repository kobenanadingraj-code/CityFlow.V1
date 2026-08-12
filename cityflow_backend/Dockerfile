FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
    libpq-dev \
    gcc \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .

RUN pip install --no-cache-dir -r requirements.txt

COPY cityflow_backend/ .

COPY data/ /app/data/

RUN python manage.py collectstatic --noinput || true

RUN chmod +x /app/start.sh

EXPOSE 8000

CMD ["/app/start.sh"]