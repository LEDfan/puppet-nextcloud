# class to configure proxies inside nextcloud
# see https://docs.nextcloud.com/server/12/admin_manual/configuration_server/reverse_proxy_configuration.html
class nextcloud::configure_proxy (
    $proxy_trusted_proxies,
    $proxy_overwritehost,
    $proxy_overwriteprotocol){

  nextcloud::import_config { 'import_proxy_config':
    file_name => template('nextcloud/nextcloud-proxy.json.erb')
  }

}
