# imports a json config file into nextcloud
define nextcloud::import_config ($file_name){
  file { "/tmp/nextcloud-import-config-${title}":
    ensure  => present,
    content => $file_name,
  }->
  exec { "import-nc-config-${title}":
    command => "/usr/bin/php /var/www/html/nextcloud/occ config:import /tmp/nextcloud-import-config-${title}",
    user    => apache,
    group   => apache,
    # this command will return 0 if the nextcloud config file don't contain all lines in the provided config file
    onlyif  => "/usr/bin/php /var/www/html/nextcloud/occ config:list > /tmp/config.txt && /usr/bin/grep -Fvf /tmp/config.txt /tmp/nextcloud-import-config-${title}"
  }
}
