include apache

# include yum

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
}
