#!/usr/bin/env bash
# (rodar na vm-controle) Uma requisição a cada 0,5 s. Deixe rodando e, em outro
# terminal, derrube o B1 (ex.: "vagrant halt vm-b1" no seu computador) para ver
# o B2 assumir ao vivo. Ctrl+C para sair.
VIP=192.168.56.100
while true; do
  headers=$(curl -s -m 1 -o /dev/null -D - "http://$VIP/")
  bal=$(echo "$headers" | grep -i '^X-Balancer-Used' | awk '{print $2}' | tr -d '\r')
  app=$(echo "$headers" | grep -i '^X-App-Server'   | awk '{print $2}' | tr -d '\r')
  printf "%s  balanceador: %-6s  aplicação: %s\n" "$(date +%T)" "${bal:-FALHOU}" "${app:--}"
  sleep 0.5
done
