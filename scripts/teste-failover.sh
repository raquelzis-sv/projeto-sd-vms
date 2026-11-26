#!/usr/bin/env bash
# (rodar na vm-controle) Derruba o container b1, mostra o B2 assumindo o VIP e religa o b1.
VIP=192.168.56.100
IFACE=enp0s8
DIR="$(cd "$(dirname "$0")" && pwd)"

dono_do_vip() {
  for vm in vm-b1 vm-b2; do
    if ssh "$vm" ip -4 addr show "$IFACE" 2>/dev/null | grep -q "$VIP"; then
      echo "$vm"; return
    fi
  done
  echo "ninguém"
}

echo "### 1) Situação normal"
echo "VIP $VIP está em: $(dono_do_vip)"
bash "$DIR/teste-roundrobin.sh" 4

echo
echo "### 2) Simulando falha: parando o container b1 na vm-b1"
ssh vm-b1 sudo docker stop b1 >/dev/null
sleep 3
echo "VIP $VIP está em: $(dono_do_vip)"
bash "$DIR/teste-roundrobin.sh" 4

echo
echo "### 3) Religando o b1 (prioridade maior, retoma o VIP)"
ssh vm-b1 sudo docker start b1 >/dev/null
sleep 5
echo "VIP $VIP está em: $(dono_do_vip)"
bash "$DIR/teste-roundrobin.sh" 4
