# Gamio Universal Proxy

Универсальный nginx reverse proxy для проксирования PostHog и OpenRouter API с автоматическими SSL сертификатами Let's Encrypt.

## Возможности

- Проксирование PostHog Analytics (с поддержкой US/EU регионов)
- Проксирование OpenRouter API
- Автоматические SSL сертификаты Let's Encrypt с автопродлением
- Docker-based развертывание за 5 минут
- Health check endpoints
- CORS headers для всех API

## Архитектура

```
e.gamio.ru/p/*     → PostHog (us.i.posthog.com или eu.i.posthog.com)
e.gamio.ru/o/*     → OpenRouter API (openrouter.ai/api/)
e.gamio.ru/health  → Health check endpoint
```

## Быстрый старт

### Локальная разработка (без SSL)

#### 1. Настройка окружения

```bash
# Скопируйте пример файла окружения
cp .env.example .env

# Отредактируйте .env если нужен EU регион PostHog
# По умолчанию используется US регион
```

#### 2. Запуск proxy

```bash
# Сборка и запуск
docker-compose up -d

# Просмотр логов
docker-compose logs -f

# Остановка
docker-compose down
```

### Production развертывание (с SSL)

#### 1. Настройка DNS

Убедитесь, что A-запись для `e.gamio.ru` указывает на IP вашего сервера.

```bash
# Проверка DNS
dig e.gamio.ru +short
```

#### 2. Настройка окружения

```bash
cp .env.example .env
# Отредактируйте .env при необходимости
```

#### 3. Получение SSL сертификата

```bash
# Используя скрипт
chmod +x init-letsencrypt.sh
./init-letsencrypt.sh

# Или используя Makefile
make ssl-init
```

Скрипт:
- Запросит ваш email для уведомлений Let's Encrypt
- Создаст временный самоподписанный сертификат
- Запустит nginx
- Получит настоящий сертификат от Let's Encrypt
- Настроит автоматическое продление (каждые 12 часов проверка)

**Подробная инструкция по SSL:** См. [SSL-SETUP.md](SSL-SETUP.md)

#### 4. Проверка работоспособности

```bash
# Health check (HTTP для локальной разработки)
curl http://localhost/health

# Health check (HTTPS для production)
curl https://e.gamio.ru/health

# Тест PostHog
curl -I https://e.gamio.ru/p/decide?v=3

# Тест OpenRouter (требуется API ключ)
curl -X POST https://e.gamio.ru/o/v1/chat/completions \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"model":"openai/gpt-3.5-turbo","messages":[{"role":"user","content":"Hello"}]}'

# Проверка SSL сертификата
openssl s_client -connect e.gamio.ru:443 -servername e.gamio.ru < /dev/null 2>/dev/null | openssl x509 -noout -dates
```

## Интеграция в приложения

### PostHog

```javascript
// JavaScript SDK
posthog.init('YOUR_PROJECT_API_KEY', {
  api_host: 'https://e.gamio.ru/p',
  ui_host: 'https://us.posthog.com' // или 'https://eu.posthog.com'
})
```

```python
# Python SDK
posthog = Posthog(
    project_api_key='YOUR_PROJECT_API_KEY',
    host='https://e.gamio.ru/p'
)
```

### OpenRouter API

```javascript
// JavaScript (fetch)
const response = await fetch('https://e.gamio.ru/o/v1/chat/completions', {
  method: 'POST',
  headers: {
    'Authorization': 'Bearer YOUR_OPENROUTER_API_KEY',
    'Content-Type': 'application/json',
    'HTTP-Referer': 'https://gamio.ru', // Опционально
    'X-Title': 'Gamio App' // Опционально
  },
  body: JSON.stringify({
    model: 'openai/gpt-3.5-turbo',
    messages: [{ role: 'user', content: 'Hello!' }]
  })
});
```

```python
# Python (requests)
import requests

response = requests.post(
    'https://e.gamio.ru/o/v1/chat/completions',
    headers={
        'Authorization': 'Bearer YOUR_OPENROUTER_API_KEY',
        'Content-Type': 'application/json'
    },
    json={
        'model': 'openai/gpt-3.5-turbo',
        'messages': [{'role': 'user', 'content': 'Hello!'}]
    }
)
```

## Структура проекта

```
gamio-proxy/
├── nginx.conf.template    # Шаблон конфигурации nginx с SSL
├── Dockerfile            # Docker образ с nginx
├── docker-entrypoint.sh  # Скрипт запуска с подстановкой переменных
├── docker-compose.yml    # Docker Compose с nginx и certbot
├── init-letsencrypt.sh   # Скрипт для получения SSL сертификата
├── .env.example         # Пример файла окружения
├── .gitignore           # Git ignore файл
├── Makefile            # Команды для управления
├── logs/               # Логи nginx (создается автоматически)
├── certbot/            # SSL сертификаты Let's Encrypt (создается автоматически)
│   ├── conf/          # Конфигурация и сертификаты
│   └── www/           # ACME challenge файлы
└── README.md          # Документация
```

## Конфигурация

### Переменные окружения

| Переменная       | Значение по умолчанию | Описание                           |
|------------------|-----------------------|------------------------------------|
| POSTHOG_REGION   | us                    | Регион PostHog: 'us' или 'eu'     |

### Порты

По умолчанию proxy слушает порты:
- **80** (HTTP) - редирект на HTTPS и ACME challenge
- **443** (HTTPS) - основной трафик

### SSL/TLS

Автоматическое продление сертификатов настроено через certbot контейнер:
- Проверка продления каждые 12 часов
- Nginx перезагружается каждые 6 часов для применения новых сертификатов
- Сертификаты действительны 90 дней, автоматически обновляются за 30 дней до истечения

## SSL сертификаты - дополнительные опции

### Staging режим (для тестирования)

Если вы хотите протестировать получение сертификата без риска исчерпать лимиты Let's Encrypt:

```bash
# Отредактируйте init-letsencrypt.sh
# Измените: staging=0 на staging=1
nano init-letsencrypt.sh

# Запустите инициализацию
./init-letsencrypt.sh
```

Staging сертификаты не будут доверенными в браузерах, но позволяют проверить процесс.

### Ручное продление сертификата

```bash
# Форсировать продление
docker-compose run --rm certbot renew --force-renewal

# Перезагрузить nginx для применения
docker-compose exec nginx-proxy nginx -s reload
```

### Проверка статуса сертификата

```bash
# Список сертификатов
docker-compose run --rm certbot certificates

# Информация о конкретном сертификате
openssl x509 -in ./certbot/conf/live/e.gamio.ru/fullchain.pem -text -noout
```

## Мониторинг и отладка

### Просмотр логов

```bash
# Все логи
docker-compose logs -f

# Только ошибки
docker-compose logs -f | grep error

# Логи из файлов
tail -f logs/access.log
tail -f logs/error.log
```

### Health check

```bash
# Проверка статуса контейнера
docker-compose ps

# HTTP health check
curl http://localhost/health
```

### Типичные проблемы

#### 502 Bad Gateway
- Проверьте DNS разрешение внутри контейнера
- Убедитесь что upstream сервисы доступны

#### CORS ошибки
- Proxy уже настроен на разрешение CORS
- Проверьте что заголовки Authorization проксируются корректно

#### SSL/TLS ошибки
- Убедитесь что CA сертификаты установлены в контейнере (alpine image включает ca-certificates)

## Обновление

```bash
# Остановка текущей версии
docker-compose down

# Обновление кода (git pull или замена файлов)

# Пересборка и запуск
docker-compose up -d --build
```

## Безопасность

### Рекомендации

1. **Используйте HTTPS** в production окружении
2. **Ограничьте rate limiting** для защиты от DDoS
3. **Мониторьте логи** на подозрительную активность
4. **Обновляйте** образы nginx регулярно
5. **Не храните** API ключи в логах или конфигах

### Rate limiting (опционально)

Добавьте в `nginx.conf.template`:

```nginx
http {
    # ... существующая конфигурация

    limit_req_zone $binary_remote_addr zone=api_limit:10m rate=10r/s;

    server {
        location /o/ {
            limit_req zone=api_limit burst=20 nodelay;
            # ... остальная конфигурация
        }
    }
}
```

## Лицензия

MIT

## Поддержка

При возникновении проблем:
1. Проверьте логи: `docker-compose logs -f`
2. Проверьте конфигурацию: `docker-compose exec nginx-proxy nginx -t`
3. Создайте issue в репозитории проекта
