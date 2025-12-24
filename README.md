# Gamio Proxy

Универсальный прокси на nginx для проксирования PostHog и OpenRouter API.

## Endpoints

- `https://e.gamio.ru/o/` → OpenRouter API (`openrouter.ai`)
- `https://e.gamio.ru/p/` → PostHog API (`eu.i.posthog.com`)
- `https://e.gamio.ru/health` → Health check

## Быстрый старт

### 1. Настройка

Отредактируйте `init-letsencrypt.sh` и укажите свой email:

```bash
EMAIL="your-email@example.com"
```

### 2. Получение SSL сертификата

```bash
./init-letsencrypt.sh
```

### 3. Запуск

```bash
docker compose up -d
```

## Использование

### OpenRouter API

```bash
# Вместо:
curl https://openrouter.ai/api/v1/chat/completions

# Используйте:
curl https://e.gamio.ru/o/api/v1/chat/completions
```

### PostHog

```javascript
// В конфигурации PostHog:
posthog.init('YOUR_PROJECT_KEY', {
    api_host: 'https://e.gamio.ru/p'
})
```

## Управление

```bash
# Запуск
docker compose up -d

# Остановка
docker compose down

# Логи
docker compose logs -f nginx

# Перезагрузка nginx конфигурации
docker compose exec nginx nginx -s reload
```

## Структура файлов

```
.
├── docker-compose.yml    # Docker Compose конфигурация
├── nginx.conf            # Nginx конфигурация
├── init-letsencrypt.sh   # Скрипт инициализации SSL
├── certbot/
│   ├── conf/             # SSL сертификаты
│   └── www/              # ACME challenge директория
└── README.md
```

## Обновление сертификатов

Certbot автоматически обновляет сертификаты каждые 12 часов (если срок истекает).

Для ручного обновления:

```bash
docker compose run --rm certbot renew
docker compose exec nginx nginx -s reload
```

## Тестирование (staging)

Для тестирования без риска превысить лимиты Let's Encrypt, установите в `init-letsencrypt.sh`:

```bash
STAGING=1
```

После успешного тестирования верните `STAGING=0` и перезапустите скрипт.
