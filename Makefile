.PHONY: help build up down logs test clean restart ssl-init ssl-renew ssl-check

help:
	@echo "Available commands:"
	@echo "  make build       - Build Docker image"
	@echo "  make up          - Start proxy"
	@echo "  make down        - Stop proxy"
	@echo "  make logs        - View logs"
	@echo "  make test        - Run health checks"
	@echo "  make restart     - Restart proxy"
	@echo "  make clean       - Remove containers and images"
	@echo ""
	@echo "SSL commands:"
	@echo "  make ssl-init    - Initialize SSL certificate (first time)"
	@echo "  make ssl-renew   - Force renew SSL certificate"
	@echo "  make ssl-check   - Check SSL certificate status"

build:
	docker-compose build

up:
	docker-compose up -d
	@echo "Proxy started. Check health: make test"

down:
	docker-compose down

logs:
	docker-compose logs -f

test:
	@echo "Testing health endpoint..."
	@curl -s http://localhost/health || echo "Health check failed"
	@echo "\nTesting PostHog proxy..."
	@curl -s -I http://localhost/p/decide?v=3 | head -n 1
	@echo "Testing OpenRouter proxy..."
	@curl -s -I http://localhost/o/v1/models | head -n 1

restart: down up

clean: down
	docker-compose down -v --rmi all

ssl-init:
	@chmod +x init-letsencrypt.sh
	@./init-letsencrypt.sh

ssl-renew:
	docker-compose run --rm certbot renew --force-renewal
	docker-compose exec nginx-proxy nginx -s reload

ssl-check:
	docker-compose run --rm certbot certificates
