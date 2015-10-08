include MoApplication::DeployProviderBase

action :install do
  install_application
end

action :remove do
  uninstall_application
end

# Additionals directories to create are:
# session directory and fpm logs
def custom_dirs
  [php_session_dir, fpm_log_dir]
end

def create_services
  fpm_pool :create
  cron_php_session :create
  fpm_service_resource :nothing
end

def remove_services
  fpm_pool :delete
  cron_php_session :delete
  fpm_service_resource :restart
end

def php_session_dir
  ::File.join(full_var_run_directory,'php')
end

def logrotate_service_logs
  Array(www_logs) + [::File.join(fpm_log_dir,'access.log')]
end

def logrotate_postrotate
  config = JSON.parse node["php_fpm"]["config"]
  php_fpm_pid = config['config']['pid']
  <<-CMD
    #{logrotate_postrotate_nginx}
    [ ! -f #{php_fpm_pid} ] || kill -USR1 `cat #{php_fpm_pid}`
  CMD
end

def fpm_service_resource(action)
  service node[:php_fpm][:package] do
      #Bug in 14.04 for service provider. Adding until resolved.
      if (platform?('ubuntu') && node['platform_version'].to_f >= 14.04)
          provider Chef::Provider::Service::Upstart
      end
      action action
  end
end

def fpm_log_dir
  ::File.join(new_resource.path,'log','fpm')
end

def fpm_socket
  ::File.join(full_var_run_directory, "app.sock")
end

def fpm_pool(template_action = :create)
  options = {
    "user"                          => new_resource.user,
    "group"                         => new_resource.group,
    "prefix"                        => application_full_path,
    "chdir"                         => "/",
    "listen"                        => fpm_socket,
    "access.log"                    => ::File.join(fpm_log_dir,"access.log"),
    "access.format"                 => "%R - %u %t \'%m %r%Q%q\' %s %f %{mili}d %{kilo}M %C%%",
    "listen.backlog"                => "-1",
    "listen.owner"                  => new_resource.user,
    "listen.group"                  => www_group,
    "listen.mode"                   => "0660",
    "pm"                            => "dynamic",
    "pm.max_children"               => "10",
    "pm.start_servers"              => "4",
    "pm.min_spare_servers"          => "2",
    "pm.max_spare_servers"          => "6",
    "pm.process_idle_timeout"       => "10s",
    "pm.max_requests"               => "500",
    "pm.status_path"                => "/fpm_status",
    "request_terminate_timeout"     => "120s",
    "ping.path"                     => "/fpm_ping",
    "ping.response"                 => "/pong",
    "security.limit_extensions"     => ".php",
    "env[TMP]"                      => "/tmp",
    "env[TMPDIR]"                   => "/tmp",
    "env[TEMP]"                     => "/tmp",
    "php_value[session.save_path]"  => php_session_dir
  }.merge(new_resource.php_fpm_config)


  template "#{node[:php_fpm][:pools_path]}/#{new_resource.name}.conf" do
    source "fpm_pool.erb"
    cookbook 'mo_application_php'
    variables(
      name: new_resource.name,
      options: options
    )
    action template_action
    notifies :restart, "service[#{node[:php_fpm][:package]}]", :delayed
  end
end

def nginx_options_for(action, name, options)
  allow_from = options && options.has_key?('allow') ? options.delete('allow') : false
  {
    "root"      => nginx_document_root(options['relative_document_root'] || 'web'),
    "site_type" => "dynamic",
    "action"    => action,
    "listen"    => "80",
    "locations" => {
      %q(/) => {
        "try_files"     => "$uri $uri/ /index.php$uri?$args"
      },
      %q(~* \.(ico|css|gif|jpe?g|png|js)(\?[0-9]+)?$) => {
        "access_log"    => "off",
        "log_not_found" => "off",
        "expires"       => "max",
        "break"         => nil,
      },
      %Q(~ ^/#{options['php_filename'] || "(index|frontend|backend)"}\\.php($|/) ) => {
        "if" => {
          "!-f $document_root$fastcgi_script_name" => { "return" => "404" }
        },
        "include" => "fastcgi_params",
        "fastcgi_split_path_info" => '^(.+?\.php)(/.*)$',
        "fastcgi_pass"  => "unix:#{fpm_socket}",
        "fastcgi_param" => [
          "SCRIPT_FILENAME $document_root$fastcgi_script_name",
          "SERVER_PORT $http_x_forwarded_port",
          "PATH_INFO $fastcgi_path_info"
        ],
      }.merge(allow_from ? {'allow' => allow_from, 'deny' => 'all'}: {}).merge(options['upstream_options'] || Hash.new),
      %q(~ ^/fpm_(status|ping)$) => {
        "access_log"    => "off",
        "allow"         => node['mo_application_php']['status']['allow'],
        "deny"          => "all",
        "include"       => "fastcgi_params",
        "fastcgi_pass"  => "unix:#{fpm_socket}"
      }
    },
    "options" => {
      "index"     => "index.php",
      "access_log"  => www_access_log(name),
      "error_log"   => www_error_log(name),
      # this rewrites all the requests to the maintenance.html
      # page if it exists in the doc root. This is for capistrano's
      # disable web task
      "if" => {
        "-f $document_root/mantenimiento.html" => {
          "rewrite" =>  "^(.*)$  /mantenimiento.html last",
          "break" => nil,
        }
     }
    }
  }
end

def cron_php_session(to_do)
  cron "php_fpm_session_#{new_resource.user}" do
    minute "09,39"
    user new_resource.user
    command "[ -x /usr/lib/php5/maxlifetime ] && [ -d #{php_session_dir} ] && find #{php_session_dir} -depth -mindepth 1 -maxdepth 1 -type f ! -execdir fuser -s {} \\; -cmin +$(/usr/lib/php5/maxlifetime) -delete"
    action to_do
  end
end

