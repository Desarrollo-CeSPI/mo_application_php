include_recipe 'mo_application::install'
include_recipe 'php5-fpm::install'
include_recipe 'wkhtmltox::default'
include_recipe 'mo_application_php::_fix_php_fpm_pools'

%w(git php5-cli php5-mysqlnd php5-xsl php5-imagick php-apc).each { |p| package p }

