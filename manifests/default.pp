include apache

yumrepo { 'epel':
  baseurl => '',
  descr => "EPEL",
  enabled => '1',
  gpgcheck => '1',
  gpgkey => 'https://dl.fedoraproject.org/pub/epel/RPM-GPG-KEY-EPEL-7',
  mirrorlist => 'https://mirrors.fedoraproject.org/metalink?repo=epel-7&arch=$basearch',
}

class yum::repo::remi {
  yumrepo { 'remi':
    baseurl => '',
    descr => "Remi's repository for ${osname} \$releasever - \$basearch",
    enabled => '1',
    gpgcheck => '1',
    gpgkey => 'https://rpms.remirepo.net/RPM-GPG-KEY-remi',
    mirrorlist => 'http://rpms.remirepo.net/enterprise/7/remi/mirror',
  }
}

class yum::repo::remi_php71 {
  yumrepo { 'remi_php71':
    baseurl => '',
    descr => "Remi's PHP 7.1 RPM repository for ${osname} \$releasever - \$basearch",
    enabled => '1',
    gpgcheck => '1',
    gpgkey => 'https://rpms.remirepo.net/RPM-GPG-KEY-remi',
    mirrorlist => 'http://rpms.remirepo.net/enterprise/7/php71/mirror',
  }
}

apache::vhost { 'vhost.example.com':
  port    => '80',
  docroot => '/var/www/html',
}

# ref https://github.com/voxpupuli/puppet-php/issues/344#issuecomment-307268648
class { '::php::repo::redhat':
  yum_repo => 'remi_php71',
} ->
class { '::php::globals':
  php_version => '7.1',
  config_root => '/etc/php/7.1',
}->
class { '::php':
  manage_repos => true,
  fpm          => false,
  extensions   => {
    "pecl-imagick"   => {
      "ensure" => "installed",
      "so_name" => "imagick"
    },
    "pecl-zip" => {
      "ensure" => "installed",
      "so_name" => "zip"
    },
    "pecl-redis" => {
      "ensure" => "installed",
      "so_name" => "redis"
    }
  }
} ->
class { 'apache::mod::php':
  package_name => 'php', # mod_php from remi
  php_version => 7  # the modulen is called phplib7 not phplib71
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
}


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
