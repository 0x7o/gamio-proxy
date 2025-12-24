FROM nginx:alpine

# Установка зависимостей для envsubst
RUN apk add --no-cache gettext ca-certificates

# Копирование шаблона конфигурации
COPY nginx.conf.template /etc/nginx/nginx.conf.template

# Создание директории для логов
RUN mkdir -p /var/log/nginx

# Скрипт для подстановки переменных окружения и запуска nginx
COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

EXPOSE 80

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["nginx", "-g", "daemon off;"]
