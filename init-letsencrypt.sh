#!/bin/bash

# Скрипт для первичной настройки SSL сертификатов Let's Encrypt
# Основан на https://github.com/wmnnd/nginx-certbot

if ! [ -x "$(command -v docker-compose)" ]; then
  echo 'Error: docker-compose is not installed.' >&2
  exit 1
fi

# Домен для сертификата
domains=(e.gamio.ru)
rsa_key_size=4096
data_path="./certbot"
email="" # Добавьте свой email для уведомлений от Let's Encrypt
staging=0 # Установите в 1 для тестирования (чтобы не исчерпать лимиты)

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Let's Encrypt SSL Setup ===${NC}"
echo

# Проверка email
if [ -z "$email" ]; then
  echo -e "${YELLOW}Введите email для уведомлений Let's Encrypt:${NC}"
  read -p "Email: " email
fi

if [ -z "$email" ]; then
  echo -e "${RED}Email обязателен!${NC}"
  exit 1
fi

# Подтверждение
echo -e "${YELLOW}Домены:${NC} ${domains[*]}"
echo -e "${YELLOW}Email:${NC} $email"
echo -e "${YELLOW}Staging mode:${NC} $staging"
echo
read -p "Продолжить? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  exit 1
fi

# Проверка существующих сертификатов
if [ -d "$data_path" ]; then
  read -p "Существующие данные для $domains будут удалены. Продолжить? (y/n) " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Удаление существующих данных...${NC}"
    rm -rf "$data_path"
  else
    exit 1
  fi
fi

echo -e "${GREEN}Создание директорий...${NC}"
mkdir -p "$data_path/conf/live/$domains"
mkdir -p "$data_path/www"

# Загрузка рекомендованных TLS параметров
echo -e "${GREEN}Загрузка рекомендованных TLS параметров...${NC}"
curl -s https://raw.githubusercontent.com/certbot/certbot/master/certbot-nginx/certbot_nginx/_internal/tls_configs/options-ssl-nginx.conf > "$data_path/conf/options-ssl-nginx.conf"
curl -s https://raw.githubusercontent.com/certbot/certbot/master/certbot/certbot/ssl-dhparams.pem > "$data_path/conf/ssl-dhparams.pem"

# Создание временного самоподписанного сертификата
echo -e "${GREEN}Создание временного сертификата для $domains...${NC}"
path="/etc/letsencrypt/live/$domains"
mkdir -p "$data_path/conf/live/$domains"
docker-compose run --rm --entrypoint "\
  openssl req -x509 -nodes -newkey rsa:$rsa_key_size -days 1\
    -keyout '$path/privkey.pem' \
    -out '$path/fullchain.pem' \
    -subj '/CN=localhost'" certbot

# Запуск nginx
echo -e "${GREEN}Запуск nginx...${NC}"
docker-compose up --force-recreate -d nginx-proxy

# Удаление временного сертификата
echo -e "${GREEN}Удаление временного сертификата...${NC}"
docker-compose run --rm --entrypoint "\
  rm -Rf /etc/letsencrypt/live/$domains && \
  rm -Rf /etc/letsencrypt/archive/$domains && \
  rm -Rf /etc/letsencrypt/renewal/$domains.conf" certbot

# Запрос настоящего сертификата
echo -e "${GREEN}Запрос сертификата Let's Encrypt для $domains...${NC}"

# Формирование domain_args
domain_args=""
for domain in "${domains[@]}"; do
  domain_args="$domain_args -d $domain"
done

# Выбор staging или production endpoint
case "$staging" in
  1) staging_arg="--staging" ;;
  *) staging_arg="" ;;
esac

docker-compose run --rm --entrypoint "\
  certbot certonly --webroot -w /var/www/certbot \
    $staging_arg \
    $domain_args \
    --email $email \
    --rsa-key-size $rsa_key_size \
    --agree-tos \
    --force-renewal \
    --non-interactive" certbot

echo -e "${GREEN}Перезагрузка nginx...${NC}"
docker-compose exec nginx-proxy nginx -s reload

echo
echo -e "${GREEN}=== Готово! ===${NC}"
echo -e "SSL сертификат успешно установлен для ${YELLOW}${domains[*]}${NC}"
echo
echo -e "Автоматическое продление настроено через certbot контейнер"
echo -e "Проверка продления будет происходить каждые 12 часов"
echo
echo -e "Проверьте ваш сайт: ${YELLOW}https://${domains[0]}${NC}"
