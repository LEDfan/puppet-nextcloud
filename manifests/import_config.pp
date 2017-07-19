# imports a json config file into nextcloud
define nextcloud::import_config ($file_name){
  file { "/tmp/nextcloud-import-config-${title}":
    ensure  => present,
    content => $file_name,
  }->
  exec { "import-nc-config-${title}":
    command => "/usr/bin/php /var/www/html/nextcloud/occ config:import /tmp/nextcloud-import-config-${title}",
    user    => apache,
    group   => apache
  }
}
