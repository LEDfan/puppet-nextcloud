# -*- mode: ruby -*-
# vi: set ft=ruby :

# uses vagrant plugin install vagrant-puppet-install
Vagrant.configure("2") do |config|
  config.vm.box = "bento/centos-7.3"
  config.vm.network "private_network", ip: "172.16.20.20"

  config.puppet_install.puppet_version = "3.8.7"
  config.vm.provision :puppet do |puppet|
    puppet.module_path = "modules"
    puppet.manifests_path = "manifests"
    puppet.options = ['--verbose']
    puppet.manifest_file = "default.pp"
    puppet.hiera_config_path = "hiera.yaml"
  end

end
