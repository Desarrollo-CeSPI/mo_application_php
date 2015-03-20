default["hostupgrade"]["update_system"] = false
default["hostupgrade"]["upgrade_system"] = false
default["hostupgrade"]["first_time_only"] = false
default["php_fpm"]["config"] = <<-JSON
{  "config":
  {
    "pid": "/var/run/php5-fpm.pid",
    "error_log": "/var/log/php5-fpm.log",
    "emergency_restart_threshold": "10",
    "emergency_restart_interval": "1m",
    "process_control_timeout": "10s"
  }
}
JSON
default['mo_application_php']['status']['allow'] = '127.0.0.1'
default['mo_application_php']['php_command'] = "php -dmemory_limit=512M"
