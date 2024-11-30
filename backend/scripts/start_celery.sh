#!/bin/bash

set -e

# Wait for RabbitMQ if we're using it
if [ "$RABBITMQ_URL" != "" ]; then
    echo "Waiting for RabbitMQ..."
    while ! nc -z ${RABBITMQ_HOST:-localhost} ${RABBITMQ_PORT:-5672}; do
        sleep 0.1
    done
    echo "RabbitMQ started"
fi

# Start Celery worker
echo "Starting Celery worker..."
celery -A config worker \
    --loglevel=info \
    --concurrency=2 \
    --max-tasks-per-child=100 \
    --task-events \
    --time-limit=3600 \
    --soft-time-limit=3540

# Start Celery beat for scheduled tasks
echo "Starting Celery beat..."
celery -A config beat \
    --loglevel=info \
    --scheduler django_celery_beat.schedulers:DatabaseScheduler