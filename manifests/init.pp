# we disable the linter here because we can't change the names of these two
# classes since the PHP module epxect them in this way
# lint:ignore:autoloader_layout
# class yum::repo::remi
class yum::repo::remi {
  yumrepo { 'remi':
    baseurl    => '',
    descr      => 'Remi\'s repository for Centos 7 - x86_65',
    enabled    => '1',
    gpgcheck   => '1',
    gpgkey     => 'https://rpms.remirepo.net/RPM-GPG-KEY-remi',
    mirrorlist => 'http://rpms.remirepo.net/enterprise/7/remi/mirror',
  }
}
# class yum::repo::remi_php71
class yum::repo::remi_php71 {
  yumrepo { 'remi_php71':
    baseurl    => '',
    descr      => 'Remi\'s PHP 7.1 RPM repository for Centos 7 - x86_65',
    enabled    => '1',
    gpgcheck   => '1',
    gpgkey     => 'https://rpms.remirepo.net/RPM-GPG-KEY-remi',
    mirrorlist => 'http://rpms.remirepo.net/enterprise/7/php71/mirror',
  }
}
# lint:endignore
# class nextcloud
class nextcloud (
  $servername,
  $manage_repos       = true,
  $local_mysql        = true,
  $import_ca          = false,
  $ca_cert_path       = undef,
  $database_name      = 'nextcloud',
  $database_user      = 'nextcloud',
  $database_pass      = undef,
  $admin_username     = undef,
  $admin_pass         = undef,
  $data_dir           = '/srv/nextcloud-data',
  $database_root_pass = undef,
  $external_db_host   = undef
  ) {
  class { 'apache':
    manage_user => false
  }

  include ::collectd

  if ($manage_repos) {
    yumrepo { 'epel':
      baseurl    => '',
      descr      => 'EPEL',
      enabled    => '1',
      gpgcheck   => '1',
      gpgkey     => 'https://dl.fedoraproject.org/pub/epel/RPM-GPG-KEY-EPEL-7',
      mirrorlist => 'https://mirrors.fedoraproject.org/metalink?repo=epel-7&arch=$basearch',
    }
  }



  file { ['/etc/httpd', '/etc/httpd/certs']:
    ensure  => directory,
  }->
  profile_openssl::self_signed_certificate { 'nextcloud':
    key_owner         => 'root',
    key_group         => 'root',
    key_mode          => '0600',
    cert_country      => 'BE',
    cert_state        => 'BE',
    cert_common_names => [$servername],
    key_path          => '/etc/httpd/certs/nextcloud.key',
    cert_path         => '/etc/httpd/certs/nextcloud.cert',
    notify            => Service['httpd'],
  }->
  apache::vhost {"${servername}-ssl":
    servername    => $servername,
    port          => '443',
    docroot       => '/var/www/html/nextcloud',
    directories   => [
      { 'path'           => '/var/www/html/nextcloud',
        'deny'           => 'from all',
        'allow_override' => ['All'],
        'options'        => ['FollowSymLinks'],
        'setenv'         => ['HOME /var/www/html/nextcloud', 'HTTP_HOME /var/www/html/nextcloud'],
        'Dav'            => 'Off',
      },
    ],
    docroot_owner => 'apache',
    docroot_group => 'apache',
    ssl           => true,
    ssl_cert      => '/etc/httpd/certs/nextcloud.cert',
    ssl_key       => '/etc/httpd/certs/nextcloud.key',
  }->
  apache::vhost {"${servername}-redirect":
    servername      => $servername,
    port            => '80',
    docroot         => '/var/www/html/nextcloud',
    redirect_status => 'permanent',
    redirect_dest   => "https://${servername}"
  }

  class { 'apache::mod::headers': }

  if ($manage_repos) {
    # ref https://github.com/voxpupuli/puppet-php/issues/344#issuecomment-307268648
    class { '::php::repo::redhat':
      yum_repo => 'remi_php71',
    }

    Class['::php::repo::redhat']->Class['::php::globals']
  }
  class { '::php::globals':
    php_version => '7.1',
    config_root => '/etc/php/7.1',
  }->
  class { '::php':
    manage_repos => $manage_repos,
    fpm          => false,
    composer     => false,
    extensions   => {
      'gd'           => {},
      'mbstring'     => {},
      'mysql'        => {},
      'pecl-imagick' => {
        'ensure'  => 'installed',
        'so_name' => 'imagick'
      },
      'pecl-zip'     => {
        'ensure'  => 'installed',
        'so_name' => 'zip'
      },
      'pecl-redis'   => {
        'ensure'  => 'installed',
        'so_name' => 'redis'
      },
      'opcache'      => {
        'ensure'   => 'installed',
        'settings' => {
          # recommended options by Nextcloud https://docs.nextcloud.com/server/12/admin_manual/configuration_server/server_tuning.html?highlight=opcache#enable-php-opcache
          'opcache.enable'                  => 1,
          'opcache.enable_cli'              => 1,
          'opcache.interned_strings_buffer' => 8,
          'opcache.max_accelerated_files'   => 10000,
          'opcache.memory_consumption'      => 128,
          'opcache.save_comments'           => 1,
          'opcache.revalidate_freq'         => 1
        },
        'zend'     => true
      },
      'ldap'         => {}
    }
  } ->
  class { 'apache::mod::php':
    package_name => 'php', # mod_php from remi
    php_version  => '7'  # the modulen is called phplib7 not phplib71
  }->
  # remove the default configuration files, since puppet provides files for the modules
  file { '/etc/php.d/40-imagick.ini':
    ensure => absent,
  }->
  file { '/etc/php.d/40-zip.ini':
    ensure => absent,
  }->
  file { '/etc/php.d/50-redis.ini':
    ensure => absent,
  }->
  file { '/etc/php.d/10-opcache.ini':
    ensure => absent,
  }->
  file { '/etc/php.d/20-pdo.ini':
    ensure  => present,
    content => 'extension=pdo.so',
    notify  => Service['httpd']
  }->
  file { '/etc/php.d/pdo.ini':
    ensure => absent,
  }->
  file { '/etc/php.d/20-gd.ini':
    ensure => absent,
  }->
  file { '/etc/php.d/20-mbstring.ini':
    ensure => absent,
  }->
  file { '/etc/php.d/mysql.ini':
    ensure => absent,
  }->
  file { '/etc/php.d/ldap.ini':
    ensure => absent,
  }

  if ($local_mysql) {
    class { '::mysql::server':
      root_password           => $database_root_pass,
      remove_default_accounts => true
    }

    mysql::db { $database_name:
      user     => $database_user,
      password => $database_pass,
      host     => 'localhost',
      grant    => ['ALL'],
    }
    $database_host = 'localhost'
    Mysql::Db[$database_name]->Exec['install-nextcloud']
  } else {
    @@::mysql::db { "${::environment}_nextcloud_${::fqdn}":
      user     => $database_user,
      password => $database_pass,
      dbname   => $database_name,
      host     => $::fqdn,
      grant    => ['ALL'],
      tag      => "${::datacenter}_${::environment}",
    }
    $database_host = $external_db_host
  }


  # add a directory for the redis unixsocket
  # create a directory
  file { '/var/run/redis':
    ensure => 'directory',
  }->
  class { '::profile_redis::standalone':
    save_db_to_disk    => false,
    status_page_path   => false,
    php_redis_pkg_name => false,
    unixsocket_path    => '/var/run/redis/redis.sock',
    unixsocket_perm    => 770
  }->
  user { 'apache':
    ensure  => present,
    groups  => [redis],
    require => Class['::apache'],
    notify  => Service['httpd']
  }

  # install Nextcloud RPM
  if ($manage_repos) {
    file { '/tmp/nextcloud-12.0.0-2.el7.centos.noarch.rpm':
      ensure => present,
      source => ['puppet:///modules/nextcloud/nextcloud-12.0.0-2.el7.centos.noarch.rpm']
    }->
    package { 'nextcloud':
      ensure   => present,
      provider => 'rpm',
      source   => '/tmp/nextcloud-12.0.0-2.el7.centos.noarch.rpm',
      require  => Class['::apache::mod::php']
    }
  } else {
    package { 'nextcloud':
      ensure   => present,
      provider => 'yum',
      require  => Class['::apache::mod::php']
    }
  }

  # create datadirectory
  file { $data_dir:
    ensure => directory,
    owner  => 'apache',
    group  => 'apache'
  }

  # install/configure Nexxtcloud
  exec { 'install-nextcloud':
    command => "/usr/bin/php /var/www/html/nextcloud/occ maintenance:install --database=mysql --database-name=${database_name} --database-host=${database_host} --database-user=${database_user} --database-pass=${database_pass} --admin-user=${admin_username} --admin-pass=${admin_pass} --data-dir=${data_dir} && touch /var/www/html/nextcloud/puppet_installed_check",
    user    => apache,
    group   => apache,
    creates => '/var/www/html/nextcloud/puppet_installed_check'
  }->
  file { '/tmp/nextcloud-import-config':
    ensure  => present,
    content => template('nextcloud/nextcloud-import.json.erb'),
  }->
  exec { 'import-nc-config':
    command => '/usr/bin/php /var/www/html/nextcloud/occ config:import /tmp/nextcloud-import-config',
    user    => apache,
    group   => apache
  }
  if ($import_ca) {
    file { '/tmp/import-ca.cert':
      ensure  => present,
      source  => $ca_cert_path,
      require => Exec['install-nextcloud']
    }->
    exec { 'import-ca-file':
      command => '/usr/bin/php /var/www/html/nextcloud/occ security:certificates:import /tmp/import-ca.cert',
      user    => apache,
      group   => apache
    }
  }

  cron { 'nextcloud':
    command => '/usr/bin/php -f /var/www/html/nextcloud/cron.php',
    user    => apache,
    minute  => '*/15'
  }

  if !defined(Class['firewall']) {
    class { 'firewall':
    }
    Class['firewall']->Firewall['443-httpd']
    Class['firewall']->Firewall['80-httpd']
  }
  firewall { '443-httpd':
    dport  => '443',
    action => 'accept',
  }
  firewall { '80-httpd':
    dport  => '80',
    action => 'accept',
  }


}
