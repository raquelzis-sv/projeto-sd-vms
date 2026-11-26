#!/usr/bin/env bash
# Prepara a vm-controle: chaves SSH para as outras VMs + Ansible.
set -e

chmod 600 ~/.ssh/vm-*.key

cat > ~/.ssh/config <<'EOF'
Host vm-b1
  HostName 192.168.56.11
  IdentityFile ~/.ssh/vm-b1.key
Host vm-b2
  HostName 192.168.56.12
  IdentityFile ~/.ssh/vm-b2.key
Host vm-apps
  HostName 192.168.56.20
  IdentityFile ~/.ssh/vm-apps.key
Host vm-*
  User vagrant
  StrictHostKeyChecking no
  UserKnownHostsFile /dev/null
  LogLevel ERROR
EOF
chmod 600 ~/.ssh/config

if ! command -v ansible-playbook >/dev/null; then
  sudo apt-get update -qq
  sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq software-properties-common curl
  sudo add-apt-repository -y ppa:ansible/ansible
  sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq ansible
fi
ansible --version | head -1

# atalhos para os scripts de teste
grep -q 'sd-testes' ~/.bashrc || cat >> ~/.bashrc <<'EOF'
# sd-testes
alias roundrobin='bash /vagrant/scripts/teste-roundrobin.sh'
alias failover='bash /vagrant/scripts/teste-failover.sh'
alias continuo='bash /vagrant/scripts/teste-continuo.sh'
cd /vagrant/ansible
EOF
