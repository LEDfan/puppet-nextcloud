# enables a nextcloud app
define nextcloud::enable_app ($app_name) {
  exec { "enale-nc-app-${app_name}":
    command => "/usr/bin/php /var/www/html/nextcloud/occ app:enable ${app_name}",
    user    => apache,
    group   => apache,
    # this regex will check if the app is disabled, only then the app will be enabled
    # the regix will check if the appname appears after the "Disabled" string
    # note that this will fail if Nextcloud changes the output of the occ app:list command
    onlyif  => "/usr/bin/php /var/www/html/nextcloud/occ app:list 2> /dev/null | /usr/bin/grep -Pzo \"Disabled(.|\\s)*${app_name}\""
  }
}
