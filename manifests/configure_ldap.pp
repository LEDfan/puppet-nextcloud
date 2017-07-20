# configures and enables the ldap user backend
class nextcloud::configure_ldap (
  $ldap_password,
  $ldap_base,
  $ldap_dn,
  $ldap_group_filter,
  $ldap_host,
  $ldap_login_filter,
  $ldap_userlist_filter) {

    $ldap_password_base64 = strip(base64('encode', $ldap_password))
    nextcloud::enable_app { 'ldap':
      app_name => 'user_ldap',
    }->
    nextcloud::import_config {'import_ldap_config':
      file_name => template('nextcloud/ldap.json.erb')
    }


}
