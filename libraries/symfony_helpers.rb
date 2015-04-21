def mo_symfony_clear_cache
  cc_resource = "mo_symfony_clear_cache_#{new_resource.name}"
  run_context.resource_collection.find("ruby_block[#{cc_resource}]")
  rescue Chef::Exceptions::ResourceNotFound
    # resource_collection#find raises an exception. In that case we define this resource for the first time
    ruby_block cc_resource do
      block do
        cmd = Mixlib::ShellOut.new("#{php_command} symfony cc",
                                   :user => new_resource.user,
                                   :env => nil,
                                   :cwd => ::File.join(application_current_path))
        cmd.run_command
        cmd.error!
      end
      action :nothing
    end
end

def php_command
  node['mo_application_php']['php_command']
end

def symfony_application_template(name, &block)
  mo_symfony_clear_cache
  application_shared_template(name, &block).tap do |t|
    t.notifies :run, "ruby_block[mo_symfony_clear_cache_#{new_resource.name}]"
  end
end

def symfony_application(data, &before_deploy_block)
  mo_application_deploy(data, :mo_application_php_symfony, &before_deploy_block)
end
