# Cenário 2 — Dois balanceadores para quatro aplicações (com VMs)

Trabalho de Sistemas Distribuídos — Emily Vitória Xavier, Raphael Oliveira e Raquel Veloso.

Virtualizador: **VirtualBox**, com as VMs criadas pelo **Vagrant**. Dentro das VMs, tudo roda em **containers Docker** e é configurado pelo **Ansible**.

## Como o desenho do quadro vira VMs

```
  [Clientes]  seu computador (navegador / PowerShell) e a vm-controle
       │
    (INT)     rede host-only do VirtualBox 192.168.56.0/24
       │
   VIP 192.168.56.100  ── Keepalived / VRRP (só um dos dois segura o IP)
       ├──────────────────────────┐
  ┌─ vm-b1 (.11) ──────────┐  ┌─ vm-b2 (.12) ──────────┐
  │ container b1           │  │ container b2           │   CAMADA DE
  │ Nginx + Keepalived     │  │ Nginx + Keepalived     │   BALANCEAMENTO
  │ MASTER, prioridade 101 │  │ BACKUP, prioridade 100 │
  └───────────┬────────────┘  └───────────┬────────────┘
              │  Round-Robin + header X-Balancer-Used  │
              └──────────────┬────────────────────────┘
  ┌─ vm-apps (.20) ──────────┴──────────────────────────────┐
  │ app01 :8081   app02 :8082   app03 :8083   app04 :8084   │   CAMADA DE
  │ (containers Nginx servindo HTML estático)               │   APLICAÇÃO
  └─────────────────────────────────────────────────────────┘

  vm-controle (.5) — roda o Ansible e os scripts de teste
```

Assim como no quadro, **B1 e B2 se ligam às quatro aplicações**. Só quem está com o VIP recebe tráfego.

| VM | IP | RAM | Função |
|---|---|---|---|
| vm-b1 | 192.168.56.11 | 512 MB | Balanceador B1 (container `b1`) |
| vm-b2 | 192.168.56.12 | 512 MB | Balanceador B2 (container `b2`) |
| vm-apps | 192.168.56.20 | 1 GB | Containers `app01`..`app04` |
| vm-controle | 192.168.56.5 | 768 MB | Ansible + testes |

Total de **cerca de 2,8 GB de RAM**. O ideal é um computador com 8 GB ou mais.

## Pré-requisitos (no computador de vocês)

1. [VirtualBox 7](https://www.virtualbox.org/wiki/Downloads)
2. [Vagrant](https://developer.hashicorp.com/vagrant/install)
3. Internet na primeira execução: baixa a box `bento/ubuntu-22.04` (~1 GB, só uma vez), o Docker e as imagens.
4. Virtualização (VT-x/AMD-V) habilitada na BIOS. No Windows, se o VirtualBox reclamar, desative o Hyper-V/“Plataforma de Máquina Virtual”.

Não precisa instalar Ansible nem Docker no computador: os dois rodam dentro das VMs.

## Montagem por fases

O passo a passo detalhado, com verificações e o que registrar no relatório, está no roteiro de implementação. Resumo:

| Fase | Onde rodar | Comando |
|---|---|---|
| 0. Pré-requisitos | computador | `vagrant box add bento/ubuntu-22.04 --provider virtualbox` |
| 1. VMs do cenário | computador | `vagrant up vm-b1 vm-b2 vm-apps` |
| 2. Controle + Ansible | computador | `vagrant up vm-controle` e `vagrant ssh vm-controle` |
| 3. Docker | vm-controle | `ansible-playbook 01-docker.yml` |
| 4. Aplicações | vm-controle | `ansible-playbook 02-aplicacoes.yml` |
| 5. Balanceadores + VIP | vm-controle | `ansible-playbook 03-balanceadores.yml` |
| 6. Verificação | vm-controle | `ansible-playbook 04-verificacao.yml` |

Na vm-controle, os playbooks ficam em `/vagrant/ansible`, que é onde o terminal já abre. Depois de tudo montado, `ansible-playbook site.yml` roda as fases 3 a 6 de uma vez.

Mudou algo em `ansible/group_vars/all.yml`? Rode de novo o playbook da fase correspondente.

## Testes (para a apresentação)

**No navegador do computador:** abra `http://192.168.56.100` e aperte F5 várias vezes. A cor muda (APP01 → APP02 → APP03 → APP04) e a página mostra qual balanceador atendeu.

**No PowerShell (Windows):**

```powershell
.\scripts\teste-roundrobin.ps1 -N 8
```

**Na vm-controle:**

```bash
vagrant ssh vm-controle
roundrobin 8      # Round-Robin pelas 4 aplicações
failover          # para o b1, mostra o B2 com o VIP, religa o b1
continuo          # requisições sem parar (Ctrl+C para sair)
```

**Demonstração forte de failover (derrubar a VM inteira):**
1. Num terminal, rode `vagrant ssh vm-controle` e depois `continuo`.
2. Em outro terminal no computador, rode `vagrant halt vm-b1`. As requisições passam a mostrar `B2` sem parar de responder.
3. Rode `vagrant up vm-b1`. O B1 volta e retoma o VIP.

**Comandos úteis**

```bash
vagrant status                                  # estado das VMs
vagrant ssh vm-b1 -c "ip a show enp0s8"         # o VIP aparece em quem é o dono
vagrant ssh vm-b2 -c "docker logs b2 2>&1 | grep -i state"   # transições MASTER/BACKUP
vagrant ssh vm-apps -c "docker ps"              # os 4 containers de aplicação
vagrant ssh vm-b1 -c "docker exec b1 nginx -s stop"   # só o Nginx cai -> health check entrega o VIP
```

## Estrutura

| Caminho | O que é |
|---|---|
| `Vagrantfile` | Define as 4 VMs, a rede e o provisionamento |
| `scripts/preparar-controle.sh` | Instala o Ansible na vm-controle e configura o SSH para as outras VMs |
| `ansible/inventory.ini` | VMs por camada; B1 = MASTER/101, B2 = BACKUP/100 |
| `ansible/group_vars/all.yml` | VIP, interface, portas, nomes e cores das apps |
| `ansible/roles/docker` | Instala Docker + Compose nas VMs |
| `ansible/roles/aplicacoes` | Páginas HTML, config do Nginx e compose das 4 apps |
| `ansible/roles/balanceadores` | Imagem Nginx+Keepalived, `nginx.conf` (Round-Robin + header), `keepalived.conf` (VRRP) |
| `ansible/roles/verificacao` | Espera o VIP responder e mostra o resultado |
| `scripts/teste-*.sh` / `.ps1` | Testes de Round-Robin, failover e contínuo |

## Problemas comuns

- **`vagrant up` reclama do IP 192.168.56.x:** o VirtualBox só aceita a faixa 192.168.56.0/21 em redes host-only. Os IPs usados já estão nela.
- **Keepalived não sobe / VIP não aparece:** confira o nome da interface com `vagrant ssh vm-b1 -c "ip a"`. A interface com 192.168.56.11 deve ser `enp0s8`. Se for outro nome, ajuste `vip_interface` em `group_vars/all.yml` e rode de novo o `03-balanceadores.yml`.
- **Erro de `\r` / `bad interpreter` em script:** os arquivos `.sh` precisam estar com quebra de linha LF. O `.gitattributes` já garante isso pelo Git. Se copiar à mão, salve como LF no VS Code.
- **Ansible falhou no meio** (ex.: internet caiu): é só rodar o mesmo playbook de novo.
- **Começar do zero:** `vagrant destroy -f` e refazer a partir da fase 1.
