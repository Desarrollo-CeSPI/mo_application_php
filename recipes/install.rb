include_recipe 'nginx::default'
include_recipe 'php5-fpm::install'
include_recipe 'wkhtmltox::default'
include_recipe 'chef-msttcorefonts::default'
include_recipe 'cespi_application_php::_fix_php_fpm_pools'

%w(git php5-cli php5-mysqlnd php5-xsl php-apc).each do |p|
  package p
end

