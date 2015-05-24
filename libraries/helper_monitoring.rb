def mo_application_php_monitoring_from_databag(cookbook_name)
  mo_application_from_data_bag(cookbook_name, false).tap do |data|
    mo_application_php_monitoring_fpm_pool data
  end
end

def mo_application_php_monitoring(data)
  include_recipe "mo_monitoring_client::fpm"
  mo_application_php_monitoring_fpm_pool data
end

def mo_application_php_monitoring_fpm_pool(data)
  (data['applications'] || Hash.new).each do |app, app_data|
    server_name = Array(app_data['server_name']).first

    monitoring = app_data['monitoring'] || Hash.new
    fpm = monitoring['fpm'] || Hash.new
    %w(warning critical).each do |level|
      fpm[level] ||= Hash.new
      fpm[level]['min_available_processes'] ||= -1
      fpm[level]['proc_max_reached'] ||= -1
      fpm[level]['queue_max_reached'] ||= -1
    end

    name = node['mo_monitoring_client']['fpm']['check_status_command']
    check_name = "#{data['id']}_fpm_#{node.name}"

    nrpe_check check_name do
      command "#{node["mo_monitoring_client"]["install_directory"]}/#{name}"
      warning_condition "#{fpm['warning']['min_available_processes']},#{fpm['warning']['proc_max_reached']},#{fpm['warning']['queue_max_reached']}"
      critical_condition "#{fpm['critical']['min_available_processes']},#{fpm['critical']['proc_max_reached']},#{fpm['critical']['queue_max_reached']}"
      parameters "-H localhost -u /fpm_status -s #{server_name}"
      action (data['remove'] ? :remove : :add)
      notifies :restart, "service[#{node['nrpe']['service_name']}]"
    end

  end
end
