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
  $manage_repos = true,
  $setup_mysql =  true
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

  apache::vhost {$servername:
    port        => '80',
    docroot     => '/var/www/html/nextcloud',
    directories => [
      { 'path'           => '/var/www/html/nextcloud',
        'deny'           => 'from all',
        'allow_override' => ['All'],
        'options'        => ['FollowSymLinks'],
        'setenv'         => ['HOME /var/www/html/nextcloud', 'HTTP_HOME /var/www/html/nextcloud'],
        'Dav'            => 'Off'
      },
    ],
    docroot_owner => 'apache',
    docroot_group => 'apache',
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
      'gd'             => {},
      'mbstring'       => {},
      'mysql'          => {},
      'pecl-imagick'   => {
        'ensure'  => 'installed',
        'so_name' => 'imagick'
      },
      'pecl-zip'       => {
        'ensure'  => 'installed',
        'so_name' => 'zip'
      },
      'pecl-redis'     => {
        'ensure'  => 'installed',
        'so_name' => 'redis'
      },
      'opcache'   => {
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
      'ldap' => {}
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
  file { '/etc/php.d/ldap .ini':
    ensure => absent,
  }

  if ($setup_mysql) {
    class { '::mysql::server':
      root_password           => 'random',
      remove_default_accounts => true
    }

    mysql::db { 'nextcloud':
      user     => 'nextcloud',
      password => 'random',
      host     => 'localhost',
      grant    => ['ALL'],
    }
  }


  # add a directory for the redis unixsocket
  # create a directory
  file { '/etc/site-conf':
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
    ensure   => present,
    groups   => [redis],
    require  => Class['::apache'],
    notify  => Service['httpd']
}

  # icinga breaks the sudoers file for vagrant
  # TODO add check for this
  #sudo::conf { 'vagrant':
  #    priority => 10,
  #  content  => 'vagrant ALL=(ALL) NOPASSWD: ALL',
  #}

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
  cron { 'nextcloud':
    command => '/usr/bin/php -f /var/www/html/nextcloud/cron.php',
    user    => apache,
    minute  => '*/15'
  }


}
