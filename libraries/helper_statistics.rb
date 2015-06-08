def mo_application_php_statistics_from_databag(cookbook_name)
  mo_application_from_data_bag(cookbook_name, false).tap do |data|
    mo_application_php_statistics data
  end
end

def mo_application_php_statistics(data)
  (data['applications']|| Hash.new).each do |k, v_data| 
    mo_collectd_php_fpm "#{data['id']}_#{k}", "http://localhost/fpm_status?json", Array(v_data['server_name']).first, !!!data['remove']
  end
end
