# configures redis
class nextcloud::configure_redis (
  $redis_host,
  $redis_port) {

  nextcloud::import_config {'import_redis_config':
    file_name => template('nextcloud/redis.json.erb')
  }


}
