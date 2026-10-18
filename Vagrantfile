Vagrant.configure("2") do |config|

  config.vm.box = "ubuntu/focal64"
  config.vm.box_version = "20240821.0.1"

  config.vm.hostname = "terraform-demo"
  
  config.vm.network "private_network", ip: "192.168.33.30"

  config.vm.provider "virtualbox" do |vb|
    vb.memory = 2048
    vb.cpus = 2
    vb.name = "terraform-demo"
  end

  config.vm.provision "shell", path: "scripts/provision.sh", privileged: true
end
