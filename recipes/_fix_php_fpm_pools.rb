#Ubutu installs default www.conf pool, so we try removing it
service "fix #{node[:php_fpm][:package]}" do
    #Bug in 14.04 for service provider. Adding until resolved.
    if (platform?('ubuntu') && node['platform_version'].to_f >= 14.04)
        provider Chef::Provider::Service::Upstart
    end
    service_name node[:php_fpm][:package]
    supports :start => true, :stop => true, :restart => true, :reload => true
end

file File.join(node["php_fpm"]["pools_path"],'www.conf') do
  action :delete
  notifies :restart, "service[fix #{node[:php_fpm][:package]}]", :immediately
end
