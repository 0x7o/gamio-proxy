# Quick Start Guide

## Production развертывание с SSL (5 минут)

### 1. Клонируйте или скачайте проект

```bash
cd /opt
git clone <your-repo-url> gamio-proxy
cd gamio-proxy
```

### 2. Настройте окружение

```bash
cp .env.example .env
# Отредактируйте .env если нужен EU регион PostHog
```

### 3. Убедитесь что DNS настроен

```bash
dig e.gamio.ru +short
# Должен вернуть IP вашего сервера
```

### 4. Запустите SSL инициализацию

```bash
make ssl-init
```

Введите email когда запросит и подтвердите домен.

### 5. Готово!

Проверьте работу:

```bash
curl https://e.gamio.ru/health
```

## Основные команды

```bash
# Запуск
make up

# Остановка
make down

# Логи
make logs

# Перезапуск
make restart

# Проверка здоровья
make test

# SSL команды
make ssl-init     # Первичная настройка SSL
make ssl-renew    # Форсировать продление
make ssl-check    # Проверить статус сертификата
```

## Интеграция в ваше приложение

### PostHog (JavaScript)

```javascript
posthog.init('YOUR_API_KEY', {
  api_host: 'https://e.gamio.ru/p',
  ui_host: 'https://us.posthog.com'
})
```

### OpenRouter (JavaScript)

```javascript
const response = await fetch('https://e.gamio.ru/o/v1/chat/completions', {
  method: 'POST',
  headers: {
    'Authorization': 'Bearer YOUR_API_KEY',
    'Content-Type': 'application/json'
  },
  body: JSON.stringify({
    model: 'openai/gpt-3.5-turbo',
    messages: [{ role: 'user', content: 'Hello!' }]
  })
})
```

## Troubleshooting

### Ошибка "too many certificates"

Используйте staging режим:

```bash
nano init-letsencrypt.sh
# Измените: staging=0 на staging=1
make ssl-init
```

### Nginx не запускается

```bash
# Проверка конфигурации
docker-compose exec nginx-proxy nginx -t

# Логи
make logs
```

### Порты заняты

```bash
# Проверка занятых портов
sudo lsof -i :80
sudo lsof -i :443

# Остановка конфликтующих сервисов
sudo systemctl stop apache2  # или другой веб-сервер
```

## Дополнительная документация

- [README.md](README.md) - Полная документация
- [SSL-SETUP.md](SSL-SETUP.md) - Подробная настройка SSL
