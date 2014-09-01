include_recipe 'nginx::default'
include_recipe 'php5-fpm::install'

%w(git php5-cli php5-mysqlnd php5-xsl php-apc).each do |p|
  package p
end
