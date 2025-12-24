#!/bin/sh
set -e

# Подстановка переменных окружения в конфигурацию nginx
envsubst '${POSTHOG_REGION}' < /etc/nginx/nginx.conf.template > /etc/nginx/nginx.conf

# Проверка конфигурации nginx
nginx -t

# Запуск nginx
exec "$@"
