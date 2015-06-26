include_recipe 'mo_application::install'
include_recipe 'php5-fpm::install'
include_recipe 'wkhtmltox::default'
include_recipe 'mo_application_php::_fix_php_fpm_pools'
include_recipe 'mo_monitoring_client::fpm'
include_recipe 'mo_collectd::plugin_php_fpm'

%w(git php5-cli php5-mysqlnd php5-xsl php5-imagick php5-gd php-apc php5-curl php5-ldap php-net-ldap).each { |p| package p }

