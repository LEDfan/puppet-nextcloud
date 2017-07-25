# class nextcloud
class nextcloud (
  $servername,
  $local_mysql        = true,
  $database_name      = 'nextcloud',
  $database_user      = 'nextcloud',
  $database_pass      = undef,
  $admin_username     = undef,
  $admin_pass         = undef,
  $data_dir           = '/srv/nextcloud-data',
  $create_data_dir    = true, # data_dir parameter is still needed
  $database_host      = undef,
  $trusted_domains    = [],
  $install_method     = 'filesystem' # can be filesystem or repo
  ) {

  $all_trusted_domains = concat($trusted_domains, $servername)

  $tmp_directory = '/var/nextcloud/tmp'
  file { '/var/nextcloud':
    ensure => directory
  }->
  file { '/var/nextcloud/tmp':
    ensure => directory,
    mode   => '0777'
  }

  # install Nextcloud RPM
  if ($install_method == 'filesystem') {
    file { "${::nextcloud::tmp_directory}/nextcloud-12.0.0-2.el7.centos.noarch.rpm":
      ensure => present,
      source => ['puppet:///modules/nextcloud/nextcloud-12.0.0-2.el7.centos.noarch.rpm']
    }->
    package { 'nextcloud':
      ensure   => present,
      provider => 'rpm',
      source   => "${::nextcloud::tmp_directory}/nextcloud-12.0.0-2.el7.centos.noarch.rpm"
    }
  } elsif ($install_method == 'repo') {
    package { 'nextcloud':
      ensure   => present,
      provider => 'yum'
    }
  } else {
    fail('Install_method is not source or repo') # TODO use proper validation in the header
  }

  if ($create_data_dir) {
      # create datadirectory
    file { $data_dir:
      ensure => directory,
      owner  => 'apache',
      group  => 'apache'
    }
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

  cron { 'nextcloud':
    command => '/usr/bin/php -f /var/www/html/nextcloud/cron.php',
    user    => apache,
    minute  => '*/15'
  }

}
