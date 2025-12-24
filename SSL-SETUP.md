# SSL Setup - Быстрая инструкция

## Автоматическая настройка (Рекомендуется)

### Шаг 1: Проверка DNS

```bash
dig e.gamio.ru +short
# Должен вернуть IP вашего сервера
```

### Шаг 2: Запуск скрипта инициализации

```bash
chmod +x init-letsencrypt.sh
./init-letsencrypt.sh
```

Или используя Makefile:

```bash
make ssl-init
```

### Шаг 3: Следуйте инструкциям

Скрипт запросит:
1. Email для уведомлений Let's Encrypt
2. Подтверждение домена
3. Подтверждение удаления существующих сертификатов (если есть)

### Готово!

После завершения:
- SSL сертификат установлен
- HTTPS доступен на порту 443
- HTTP (порт 80) редиректит на HTTPS
- Автоматическое продление настроено

## Проверка работы

```bash
# Проверка HTTPS
curl https://e.gamio.ru/health

# Проверка сертификата
openssl s_client -connect e.gamio.ru:443 -servername e.gamio.ru < /dev/null 2>/dev/null | openssl x509 -noout -dates

# Статус сертификата
make ssl-check
# или
docker-compose run --rm certbot certificates
```

## Частые вопросы

### Что делать при ошибке "too many certificates already issued"?

Используйте staging режим для тестирования:

```bash
# Отредактируйте init-letsencrypt.sh
nano init-letsencrypt.sh

# Измените строку:
staging=0  →  staging=1

# Запустите снова
./init-letsencrypt.sh
```

### Как обновить сертификат вручную?

```bash
make ssl-renew
# или
docker-compose run --rm certbot renew --force-renewal
docker-compose exec nginx-proxy nginx -s reload
```

### Где хранятся сертификаты?

```
./certbot/conf/live/e.gamio.ru/
├── fullchain.pem   # Полная цепочка сертификатов
├── privkey.pem     # Приватный ключ
├── cert.pem        # Сертификат домена
└── chain.pem       # Промежуточные сертификаты
```

### Как проверить автоматическое продление?

```bash
# Проверка логов certbot
docker-compose logs certbot

# Тест продления (без фактического продления)
docker-compose run --rm certbot renew --dry-run
```

## Автоматическое продление

Certbot контейнер автоматически:
- Проверяет необходимость продления каждые 12 часов
- Обновляет сертификат за 30 дней до истечения
- Nginx перезагружается каждые 6 часов для применения новых сертификатов

Никаких дополнительных действий не требуется!

## Отладка

### Nginx не запускается после SSL

```bash
# Проверка конфигурации nginx
docker-compose exec nginx-proxy nginx -t

# Проверка логов
docker-compose logs nginx-proxy
```

### Ошибка "connection refused" при ACME challenge

```bash
# Убедитесь что порт 80 открыт
sudo ufw allow 80
sudo ufw allow 443

# Проверка что nginx запущен
docker-compose ps
```

### Сертификат не обновляется автоматически

```bash
# Проверка статуса certbot контейнера
docker-compose ps certbot

# Ручной запуск продления для тестирования
docker-compose run --rm certbot renew --dry-run

# Проверка логов
docker-compose logs certbot
```

## Переход со staging на production

Если вы тестировали с staging=1:

```bash
# Остановите контейнеры
docker-compose down

# Удалите staging сертификаты
rm -rf ./certbot/conf/

# Измените staging=1 на staging=0 в init-letsencrypt.sh
nano init-letsencrypt.sh

# Запустите инициализацию снова
./init-letsencrypt.sh
```

## Безопасность

Рекомендации:
- Используйте сильные SSH ключи для доступа к серверу
- Настройте firewall (ufw, iptables)
- Регулярно обновляйте Docker образы
- Мониторьте логи на подозрительную активность
- Используйте разные пароли для разных сервисов

```bash
# Базовая настройка firewall
sudo ufw allow 22/tcp   # SSH
sudo ufw allow 80/tcp   # HTTP
sudo ufw allow 443/tcp  # HTTPS
sudo ufw enable
```
