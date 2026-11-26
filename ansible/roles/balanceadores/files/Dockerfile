# Imagem dos balanceadores B1 e B2: Nginx (balanceamento) + Keepalived (VIP / VRRP)
FROM nginx:1.27-alpine

RUN apk add --no-cache keepalived iproute2 \
    && rm -f /etc/nginx/conf.d/default.conf

COPY check_nginx.sh /usr/local/bin/check_nginx.sh
COPY entrypoint.sh  /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/check_nginx.sh /usr/local/bin/entrypoint.sh

EXPOSE 80
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
