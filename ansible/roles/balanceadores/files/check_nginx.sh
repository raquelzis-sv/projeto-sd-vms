#!/bin/sh
# Health check usado pelo Keepalived: se o Nginx não estiver rodando,
# este nó entra em FAULT e entrega o VIP para o outro balanceador.
pidof nginx >/dev/null 2>&1
