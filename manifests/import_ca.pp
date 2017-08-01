# imports a ca cert into nextcloud
define nextcloud::import_ca (
  $ca_cert_path,
  ){
  file { "${::nextcloud::tmp_directory}/import-ca-${title}.cert":
    ensure  => present,
    content => $ca_cert_path,
    require => Exec['install-nextcloud']
  }->
  exec { 'import-ca-file':
    command => "/usr/bin/php /var/www/html/nextcloud/occ security:certificates:import ${::nextcloud::tmp_directory}/import-ca-${title}.cert",
    unless  => "/usr/bin/php /var/www/html/nextcloud/occ security:certificates | grep -q import-ca-${title}.cert", # import-ca.cert is the filename
    user    => apache,
    group   => apache
  }
}
