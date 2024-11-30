#!/bin/bash

set -e

# Function to wait for postgres
wait_for_postgres() {
    echo "Waiting for PostgreSQL..."
    while ! nc -z ${DB_HOST:-localhost} ${DB_PORT:-5432}; do
        sleep 0.1
    done
    echo "PostgreSQL started"
}

# Wait for postgres if we're using it
if [ "$DATABASE_URL" != "" ]; then
    wait_for_postgres
fi

# Collect static files
echo "Collecting static files..."
python manage.py collectstatic --noinput

# Apply database migrations
echo "Applying database migrations..."
python manage.py migrate

# Create cache table
echo "Creating cache table..."
python manage.py createcachetable

# Start Gunicorn
echo "Starting Gunicorn..."
exec gunicorn config.wsgi:application \
    --name budget_tracker \
    --bind 0.0.0.0:8000 \
    --workers 3 \
    --threads 2 \
    --worker-class=gthread \
    --worker-tmp-dir /dev/shm \
    --log-level=info \
    --access-logfile=- \
    --error-logfile=-