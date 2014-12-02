def mo_symfony_clear_cache
  ruby_block "mo_symfony_clear_cache_#{new_resource.name}" do
    block do
      cmd = Mixlib::ShellOut.new("#{php_command} symfony cache:clear",
                                 :user => new_resource.user,
                                 :env => nil,
                                 :cwd => ::File.join(new_resource.path, new_resource.relative_path, 'current'))
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
