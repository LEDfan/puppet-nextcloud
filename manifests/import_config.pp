# imports a json config file into nextcloud
define nextcloud::import_config ($file_name){
  file { "${::nextcloud::tmp_directory}/nextcloud-import-config-${title}":
    ensure  => present,
    content => $file_name,
  }
  if !defined(File["${::nextcloud::tmp_directory}/match.py"]) {
    file { "${::nextcloud::tmp_directory}/match.py":
      ensure => present,
      path   => "${::nextcloud::tmp_directory}/match.py",
      source => 'puppet:///modules/nextcloud/match.py',
    }
  }
  exec { "import-nc-config-${title}":
    command => "/usr/bin/php /var/www/html/nextcloud/occ config:import ${::nextcloud::tmp_directory}/nextcloud-import-config-${title}",
    user    => apache,
    group   => apache,
    # this command will return 0 if the nextcloud config file don't contain all lines in the provided config file
    unless  => "/usr/bin/php /var/www/html/nextcloud/occ config:list --private > ${::nextcloud::tmp_directory}/config.txt && /usr/bin/python ${::nextcloud::tmp_directory}/match.py ${::nextcloud::tmp_directory}/config.txt ${::nextcloud::tmp_directory}/nextcloud-import-config-${title}",
    require => [File["${::nextcloud::tmp_directory}/match.py"], File["${::nextcloud::tmp_directory}/nextcloud-import-config-${title}"]]
  }
}
