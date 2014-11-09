default['nginx']['default_site_enabled'] = false
default['nginx']['server_names_hash_bucket_size'] = 128
default["php_fpm"]["update_system"] = false
default["php_fpm"]["upgrade_system"] = false
default['mo_application_php']['command'] = "php -dmemory_limit=512M"
default['mo_application_php']['status']['allow'] = '127.0.0.1'
