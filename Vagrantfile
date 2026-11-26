# -*- mode: ruby -*-
# Cenário 2 — dois balanceadores para quatro aplicações (Sistemas Distribuídos)
#
# Montagem por fases (ver README / roteiro):
#   Fase 1: vagrant up vm-b1 vm-b2 vm-apps   -> cria as VMs do cenário (Ubuntu puro)
#   Fase 2: vagrant up vm-controle           -> cria a VM de controle e instala o Ansible
#   Fases 3-6: dentro da vm-controle, um playbook por camada (ansible/0X-*.yml)
#   vagrant halt / vagrant destroy -f
#
# Rede host-only 192.168.56.0/24 (o seu computador é o "cliente" do desenho):
#   192.168.56.100  VIP (Keepalived)  -> abra http://192.168.56.100 no navegador
#   192.168.56.11   vm-b1    (container b1: Nginx + Keepalived, MASTER)
#   192.168.56.12   vm-b2    (container b2: Nginx + Keepalived, BACKUP)
#   192.168.56.20   vm-apps  (containers app01..app04, portas 8081..8084)
#   192.168.56.5    vm-controle (Ansible)

BOX = "bento/ubuntu-22.04"

VMS = [
  { nome: "vm-b1",   ip: "192.168.56.11", memoria: 1024 },
  { nome: "vm-b2",   ip: "192.168.56.12", memoria: 1024 },
  { nome: "vm-apps", ip: "192.168.56.20", memoria: 1024 },
]

Vagrant.configure("2") do |config|
  config.vm.box = BOX
  config.vm.box_check_update = false
  # Primeiro boot pode ser lento no Windows: espera até 10 min antes de desistir
  config.vm.boot_timeout = 600

  config.vm.provider "virtualbox" do |vb|
    # garante o "cabo" da placa NAT conectado (evita boot travado esperando rede)
    vb.customize ["modifyvm", :id, "--cableconnected1", "on"]
  end

  # VMs gerenciadas pelo Ansible (sobem primeiro)
  VMS.each do |vm|
    config.vm.define vm[:nome] do |m|
      m.vm.hostname = vm[:nome]
      m.vm.network "private_network", ip: vm[:ip]
      m.vm.synced_folder ".", "/vagrant", disabled: true
      m.vm.provider "virtualbox" do |vb|
        vb.name   = "sd-#{vm[:nome]}"
        vb.memory = vm[:memoria]
        vb.cpus   = 1
        vb.linked_clone = true
      end
    end
  end

  # VM de controle: definida por último (precisa das chaves SSH das outras VMs)
  config.vm.define "vm-controle", primary: true do |c|
    c.vm.hostname = "vm-controle"
    c.vm.network "private_network", ip: "192.168.56.5"
    # permissões fixas: o Ansible ignora ansible.cfg em pasta "world-writable"
    c.vm.synced_folder ".", "/vagrant", mount_options: ["dmode=755", "fmode=644"]
    c.vm.provider "virtualbox" do |vb|
      vb.name   = "sd-vm-controle"
      vb.memory = 1024
      vb.cpus   = 1
      vb.linked_clone = true
    end

    # Copia a chave SSH de cada VM para a vm-controle conseguir acessá-las
    VMS.each do |vm|
      c.vm.provision "file",
        source: ".vagrant/machines/#{vm[:nome]}/virtualbox/private_key",
        destination: "/home/vagrant/.ssh/#{vm[:nome]}.key"
    end

    c.vm.provision "shell", path: "scripts/preparar-controle.sh", privileged: false

  end
end
