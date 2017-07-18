# enables a nextcloud app
define nextcloud::enable_app ($app_name) {
  exec { "enale-nc-app-${app_name}":
    command => "/usr/bin/php /var/www/html/nextcloud/occ app:enable ${app_name}",
    user    => apache,
    group   => apache
  }
}
