#!/bin/sh
# Sobe o Keepalived e o Nginx no mesmo container.
# - Espera a placa da rede do cenário ter IP antes de iniciar o Keepalived
#   (no boot da VM, o Docker sobe os containers antes da rede host-only ficar pronta).
# - Se o Keepalived OU o Nginx morrer, o container encerra com erro e o Docker
#   o reinicia (restart: unless-stopped). Assim o balanceador nunca fica "meio vivo".
set -e

nginx -t

IFACE=$(awk '$1 == "interface" {print $2; exit}' /etc/keepalived/keepalived.conf)
SRC=$(awk '$1 == "unicast_src_ip" {print $2; exit}' /etc/keepalived/keepalived.conf)

i=0
until ip -4 addr show "$IFACE" 2>/dev/null | grep -q "inet $SRC/"; do
  i=$((i + 1))
  if [ "$i" -gt 60 ]; then
    echo "interface $IFACE sem o IP $SRC após 2 minutos - encerrando"
    exit 1
  fi
  echo "aguardando a interface $IFACE receber o IP $SRC..."
  sleep 2
done

keepalived --dont-fork --log-console --log-detail &
KPID=$!

nginx -g 'daemon off;' &
NPID=$!

# docker stop: encerra os dois de forma limpa (o Keepalived libera o VIP na hora)
trap 'kill -TERM $KPID $NPID 2>/dev/null; exit 0' TERM INT

while kill -0 "$KPID" 2>/dev/null && kill -0 "$NPID" 2>/dev/null; do
  sleep 2
done

echo "keepalived ou nginx parou - encerrando o container para o Docker reiniciá-lo"
kill -TERM "$KPID" "$NPID" 2>/dev/null || true
exit 1
