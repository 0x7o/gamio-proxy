#!/bin/bash

# Configuration
DOMAIN="e.gamio.ru"
EMAIL="f-zv@bk.ru"  # Change this to your email
STAGING=0  # Set to 1 for testing to avoid rate limits

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

echo -e "${GREEN}Starting SSL certificate initialization for ${DOMAIN}${NC}"

# Create required directories
mkdir -p ./certbot/conf
mkdir -p ./certbot/www

# Check if certificates already exist
if [ -d "./certbot/conf/live/${DOMAIN}" ]; then
    echo -e "${GREEN}Existing certificates found for ${DOMAIN}${NC}"
    read -p "Do you want to recreate them? (y/N) " decision
    if [ "$decision" != "Y" ] && [ "$decision" != "y" ]; then
        echo "Keeping existing certificates"
        exit 0
    fi
fi

# Download recommended TLS parameters
if [ ! -e "./certbot/conf/options-ssl-nginx.conf" ] || [ ! -e "./certbot/conf/ssl-dhparams.pem" ]; then
    echo "Downloading recommended TLS parameters..."
    mkdir -p ./certbot/conf
    curl -s https://raw.githubusercontent.com/certbot/certbot/master/certbot-nginx/certbot_nginx/_internal/tls_configs/options-ssl-nginx.conf > ./certbot/conf/options-ssl-nginx.conf
    curl -s https://raw.githubusercontent.com/certbot/certbot/master/certbot/certbot/ssl-dhparams.pem > ./certbot/conf/ssl-dhparams.pem
    echo -e "${GREEN}TLS parameters downloaded${NC}"
fi

# Create dummy certificate for nginx to start
echo "Creating dummy certificate for ${DOMAIN}..."
mkdir -p ./certbot/conf/live/${DOMAIN}
docker compose run --rm --entrypoint "\
    openssl req -x509 -nodes -newkey rsa:4096 -days 1 \
    -keyout '/etc/letsencrypt/live/${DOMAIN}/privkey.pem' \
    -out '/etc/letsencrypt/live/${DOMAIN}/fullchain.pem' \
    -subj '/CN=localhost'" certbot
echo -e "${GREEN}Dummy certificate created${NC}"

# Start nginx
echo "Starting nginx..."
docker compose up -d nginx
sleep 5

# Delete dummy certificate
echo "Deleting dummy certificate..."
docker compose run --rm --entrypoint "\
    rm -rf /etc/letsencrypt/live/${DOMAIN} && \
    rm -rf /etc/letsencrypt/archive/${DOMAIN} && \
    rm -rf /etc/letsencrypt/renewal/${DOMAIN}.conf" certbot
echo -e "${GREEN}Dummy certificate deleted${NC}"

# Request real certificate
echo "Requesting Let's Encrypt certificate for ${DOMAIN}..."

# Set staging flag if needed
staging_arg=""
if [ $STAGING != "0" ]; then
    staging_arg="--staging"
    echo -e "${RED}Running in STAGING mode - certificates will NOT be valid${NC}"
fi

docker compose run --rm --entrypoint "\
    certbot certonly --webroot -w /var/www/certbot \
    ${staging_arg} \
    --email ${EMAIL} \
    --domain ${DOMAIN} \
    --rsa-key-size 4096 \
    --agree-tos \
    --no-eff-email \
    --force-renewal" certbot

if [ $? -eq 0 ]; then
    echo -e "${GREEN}Certificate obtained successfully!${NC}"
else
    echo -e "${RED}Failed to obtain certificate${NC}"
    exit 1
fi

# Reload nginx
echo "Reloading nginx..."
docker compose exec nginx nginx -s reload

echo -e "${GREEN}SSL setup complete!${NC}"
echo ""
echo "Your proxy is now available at:"
echo "  - OpenRouter: https://${DOMAIN}/o/"
echo "  - PostHog:    https://${DOMAIN}/p/"
