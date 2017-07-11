# -*- mode: ruby -*-
# vi: set ft=ruby :

# uses vagrant plugin install vagrant-puppet-install
Vagrant.configure("2") do |config|
  config.vm.box = "bento/centos-7.3"
  config.vm.network "private_network", ip: "172.16.20.20"
  config.vm.hostname = "localhost.local" # needed for percona
  config.puppet_install.puppet_version = "3.8.7"

  # config.vm.synced_folder "www", "/var/www/nextcloud", create: true, type: 'nfs'
  config.vm.provision :puppet do |puppet|
    puppet.module_path = "modules"
    puppet.manifests_path = "manifests"
    puppet.options = ['--verbose']
    puppet.manifest_file = "default.pp"
    puppet.hiera_config_path = "hiera.yaml"
  end

  if Vagrant.has_plugin?("vagrant-cachier")
    # Configure cached packages to be shared between instances of the same base box.
    # More info on http://fgrehm.viewdocs.io/vagrant-cachier/usage
    config.cache.scope = :box

    # OPTIONAL: If you are using VirtualBox, you might want to use that to enable
    # NFS for shared folders. This is also very useful for vagrant-libvirt if you
    # want bi-directional sync
    config.cache.synced_folder_opts = {
      type: :nfs,
      # The nolock option can be useful for an NFSv3 client that wants to avoid the
      # NLM sideband protocol. Without this option, apt-get might hang if it tries
      # to lock files needed for /var/cache/* operations. All of this can be avoided
      # by using NFSv4 everywhere. Please note that the tcp option is not the default.
      mount_options: ['rw', 'vers=3', 'tcp', 'nolock']
    }
    # For more information please check http://docs.vagrantup.com/v2/synced-folders/basic_usage.html
  end
end
