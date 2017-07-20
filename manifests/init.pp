# class nextcloud
class nextcloud (
  $servername,
  #$manage_repos       = true,
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
  $external_db_host   = undef,
  # wether to redirect non ssl traffic to ssl, or support access using non-ssl access
  $redirect_ssl       = true,
  $trusted_domains    = [],
  $install_method     = 'filesystem' # can be filesystem or repo
  ) {

  $all_trusted_domains = concat($trusted_domains, $servername)

  class { 'apache':
    manage_user => false
  }

  include ::collectd

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
  }
  if ($redirect_ssl) {
    apache::vhost {"${servername}-redirect":
      servername      => $servername,
      port            => '80',
      docroot         => '/var/www/html/nextcloud',
      redirect_status => 'permanent',
      redirect_dest   => "https://${servername}"
    }
  } else {
    apache::vhost {"${servername}-no-ssl":
      servername    => $servername,
      port          => '80',
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
    }
  }

  class { 'apache::mod::headers': }

  class { '::php::globals':
    php_version => '7.1',
    config_root => '/etc/php/7.1',
  }->
  class { '::php':
    manage_repos => false,
    fpm          => false,
    composer     => false,
    extensions   => {
      'gd'           => {},
      'mbstring'     => {},
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
  # we don't use the puppet php module to install php-mysqlnd and php-ldap
  # because the puppte module creates it's own config file (and doesn't remove
  # the one from the OS), but doesn't add the priority to the filename
  # see https://github.com/voxpupuli/puppet-php/issues/272
  package { 'php-mysqlnd':
    ensure => present,
  }->
  package { 'php-ldap':
    ensure => present,
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
  if ($install_method == 'filesystem') {
    file { '/tmp/nextcloud-12.0.0-2.el7.centos.noarch.rpm':
      ensure => present,
      source => ['puppet:///modules/nextcloud/nextcloud-12.0.0-2.el7.centos.noarch.rpm']
    }->
    package { 'nextcloud':
      ensure   => present,
      provider => 'rpm',
      source   => '/tmp/nextcloud-12.0.0-2.el7.centos.noarch.rpm',
      require  => [Class['::apache::mod::php'], Package['php-mysqlnd'], Package['php-ldap']]
    }
  } elsif ($install_method == 'repo') {
    package { 'nextcloud':
      ensure   => present,
      provider => 'yum',
      require  => [Class['::apache::mod::php'], Package['php-mysqlnd'], Package['php-ldap']]
    }
  } else {
    fail('Install_method is not source or repo') # TODO use proper validation in the header
  }

  # create datadirectory
  file { $data_dir:
    ensure => directory,
    owner  => 'apache',
    group  => 'apache'
  }

  # install/configure Nextcloud
  exec { 'install-nextcloud':
    command => "/usr/bin/php /var/www/html/nextcloud/occ maintenance:install --database=mysql --database-name=${database_name} --database-host=${database_host} --database-user=${database_user} --database-pass=${database_pass} --admin-user=${admin_username} --admin-pass=${admin_pass} --data-dir=${data_dir} && touch /var/www/html/nextcloud/puppet_installed_check",
    user    => apache,
    group   => apache,
    creates => '/var/www/html/nextcloud/puppet_installed_check',
    require => Package['nextcloud']
  }->
  nextcloud::import_config {'import_redis_trusted_domains':
    file_name => template('nextcloud/nextcloud-import.json.erb')
  }
  if ($import_ca) {
    file { '/tmp/import-ca.cert':
      ensure  => present,
      source  => $ca_cert_path,
      require => Exec['install-nextcloud']
    }->
    exec { 'import-ca-file':
      command => '/usr/bin/php /var/www/html/nextcloud/occ security:certificates:import /tmp/import-ca.cert',
      unless  => '/usr/bin/php /var/www/html/nextcloud/occ security:certificates | grep -q import-ca.cert', # import-ca.cert is the filename
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
