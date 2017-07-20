# imports a json config file into nextcloud
define nextcloud::import_config ($file_name){
  file { "/tmp/nextcloud-import-config-${title}":
    ensure  => present,
    content => $file_name,
  }
  if !defined(File['/tmp/match.py']) {
    file { '/tmp/match.py':
      ensure => present,
      path   => '/tmp/match.py',
      source => 'puppet:///modules/nextcloud/match.py',
    }
  }
  exec { "import-nc-config-${title}":
    command => "/usr/bin/php /var/www/html/nextcloud/occ config:import /tmp/nextcloud-import-config-${title}",
    user    => apache,
    group   => apache,
    # this command will return 0 if the nextcloud config file don't contain all lines in the provided config file
    unless  => "/usr/bin/php /var/www/html/nextcloud/occ config:list --private > /tmp/config.txt && /usr/bin/python /tmp/match.py /tmp/config.txt /tmp/nextcloud-import-config-${title}",
    require => [File['/tmp/match.py'], File["/tmp/nextcloud-import-config-${title}"]]
  }
}
