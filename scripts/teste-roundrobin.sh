#!/usr/bin/env bash
# (rodar na vm-controle) Faz N requisições ao VIP e mostra balanceador e aplicação.
# Uso: roundrobin [quantidade]   (padrão: 8)
VIP=192.168.56.100
N=${1:-8}

echo "== $N requisições para o VIP $VIP =="
for i in $(seq 1 "$N"); do
  headers=$(curl -s -m 2 -o /dev/null -D - "http://$VIP/")
  bal=$(echo "$headers" | grep -i '^X-Balancer-Used' | awk '{print $2}' | tr -d '\r')
  app=$(echo "$headers" | grep -i '^X-App-Server'   | awk '{print $2}' | tr -d '\r')
  printf "Req %2d  ->  balanceador: %-6s  aplicação: %s\n" "$i" "${bal:-FALHOU}" "${app:--}"
done
