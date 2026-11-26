# (rodar no seu computador Windows, PowerShell) Requisições ao VIP direto do host.
# Uso: .\scripts\teste-roundrobin.ps1 [-N 8]
param([int]$N = 8)
$VIP = "192.168.56.100"

Write-Host "== $N requisicoes para o VIP $VIP =="
for ($i = 1; $i -le $N; $i++) {
    try {
        $r = Invoke-WebRequest -Uri "http://$VIP/" -UseBasicParsing -TimeoutSec 2
        $bal = $r.Headers["X-Balancer-Used"]
        $app = $r.Headers["X-App-Server"]
        Write-Host ("Req {0,2}  ->  balanceador: {1,-6}  aplicacao: {2}" -f $i, $bal, $app)
    } catch {
        Write-Host ("Req {0,2}  ->  FALHOU" -f $i)
    }
}
