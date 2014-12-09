def mo_symfony_clear_cache
  cc_resource = "mo_symfony_clear_cache_#{new_resource.name}"
  run_context.resource_collection.find("ruby_block[#{cc_resource}]")
  rescue Chef::Exceptions::ResourceNotFound
    # resource_collection#find raises an exception. In that case we define this resource for the first time
    ruby_block cc_resource do
      block do
        cmd = Mixlib::ShellOut.new("#{php_command} symfony cache:clear",
                                   :user => new_resource.user,
                                   :env => nil,
                                   :cwd => ::File.join(new_resource.path, 'current'))
        cmd.run_command
      end
      action :nothing
    end
end

def symfony_application_template(name, &block)

  mo_symfony_clear_cache

  mo_application_shared_template(name, &block).tap do |t|
    t.notifies :run, "ruby_block[mo_symfony_clear_cache_#{new_resource.name}]"
  end
end

def symfony_application(data, &before_deploy_block)
  mo_application_php_symfony data['id'] do
    action data['action']
    path data['path']
    repo data['repo']
    revision data['revision']
    force_deploy data['force_deploy']
    ssh_private_key data['ssh_private_key']
    shared_files data['shared_files']
    nginx_config data['applications']
    php_fpm_config data['php_fpm_config'] || Hash.new
    before_deploy(&before_deploy_block)
  end
  setup_dotenv data unless data['action'] == 'remove'
end
