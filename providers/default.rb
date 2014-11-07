include CespiApplication::Logrotate

attr_accessor :www_logs

action :install do

  cespi_application_php_chroot new_resource.path do
    copy_files new_resource.copy_files
  end

  fix_chroot

  cespi_application_user new_resource.user do
    group new_resource.group
    ssh_keys new_resource.ssh_keys
  end

  directory ::File.join(new_resource.path,session_dir) do
    owner new_resource.user
    group new_resource.group
    recursive true
  end

  directory www_log_dir do
    owner www_user
    group www_group
  end

  directory fpm_log_dir do
    owner new_resource.user
    group new_resource.group
  end

  if new_resource.deploy

    cespi_application_deploy new_resource.name do
      user                        new_resource.user
      group                       new_resource.group
      path                        ::File.join(new_resource.path,new_resource.relative_path)
      repo                        new_resource.repo
      revision                    new_resource.revision
      migrate                     new_resource.migrate
      migration_command           new_resource.migration_command
      shared_dirs                 new_resource.shared_dirs
      shared_files                new_resource.shared_files
      create_dirs_before_symlink  new_resource.create_dirs_before_symlink
      force_deploy                new_resource.force_deploy
      before_deploy(&new_resource.callback_before_deploy) if new_resource.callback_before_deploy
    end

  else

    directory ::File.join(new_resource.path,new_resource.relative_path) do
      owner new_resource.user
      group new_resource.group
    end

  end

  link ::File.join('/home',new_resource.user,'application') do
    to ::File.join(new_resource.path,new_resource.relative_path)
  end

  link ::File.join('/home',new_resource.user,'log') do
    to ::File.join(new_resource.path,'log')
  end


  php_fpm_pool

  nginx_create_configuration

  logrotate

  sudo_reload :install

end

action :remove do
  sudo_reload :remove

  php_fpm_pool :delete

  nginx_create_configuration :delete

  cespi_application_php_chroot new_resource.path do
    copy_files new_resource.copy_files
    action :remove
  end

  cespi_application_user new_resource.user do
    group new_resource.group
    action :remove
  end

  logrotate false
end


def fix_chroot
  root = ::File.join(new_resource.path,new_resource.path)

  directory ::File.dirname(root) do
      recursive true
  end

  link root do
      to '/'
  end
end

def session_dir
  ::File.join('','var','lib','session','php')
end

def www_log_dir
  ::File.join(new_resource.path,'log','nginx')
end

def logrotate_service_logs
  Array(self.www_logs) + [fpm_log]
end

def logrotate_application_logs
  ::File.join(new_resource.path, new_resource.relative_path, 'shared', new_resource.log_dir, '*.log')
end

def nginx_pid
  node['nginx']['pid']
end

def php_fpm_pid
  config = JSON.parse node["php_fpm"]["config"]
  config['config']['pid']
end

def logrotate_postrotate
  <<-CMD
    [ ! -f #{nginx_pid} ] || kill -USR1 `cat #{nginx_pid}`
    [ ! -f #{php_fpm_pid} ] || kill -USR1 `cat #{php_fpm_pid}`
  CMD
end

def www_user
  node['nginx']['user']
end

def www_group
  node['nginx']['group']
end

def fpm_log_dir
  ::File.join(new_resource.path,'log','fpm')
end

def fpm_log
  ::File.join(fpm_log_dir,"access.log")
end

def fpm_relative_socket
  "run/php5-fpm.socket"
end

def fpm_socket
  ::File.join(new_resource.path,fpm_relative_socket)
end

def fpm_document_root(relative_path)
  ::File.join '', new_resource.relative_path, 'current', (relative_path || 'web')
end

def nginx_document_root(relative_path)
  ::File.join new_resource.path, fpm_document_root(relative_path)
end

def php_fpm_pool(template_action = :create)
  options = {
    "user"                          => new_resource.user,
    "group"                         => new_resource.group,
    "prefix"                        => new_resource.path,
    "chroot"                        => new_resource.path,
    "chdir"                         => "/",
    "listen"                        => fpm_relative_socket,
    "access.log"                    => fpm_log,
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
    "pm.status_path"                => "/status",
    "ping.path"                     => "/ping",
    "ping.response"                 => "/pong",
    "security.limit_extensions"     => ".php",
    "env[TMP]"                      => "/tmp",
    "env[TMPDIR]"                   => "/tmp",
    "env[TEMP]"                     => "/tmp",
    "php_value[session.save_path]"  => session_dir
  }.merge(new_resource.php_fpm_config)


  template "#{node[:php_fpm][:pools_path]}/#{new_resource.name}.conf" do
    source "fpm_pool.erb"
    cookbook 'cespi_application_php'
    variables(
      name: new_resource.name,
      options: options
    )
    action template_action
    notifies :restart, "service[#{node[:php_fpm][:package]}]", :delayed
  end
end

def nginx_create_configuration(template_action=:create)
  self.www_logs = Array(self.www_logs)
  new_resource.nginx_config.each do |app_name,options|
    name = "#{new_resource.name}_#{app_name}"
    conf = {
      "action"    => template_action,
      "listen"    => "80",
      "locations" => {
        %q(/) => {
          "try_files"     => "$uri $uri/ /index.php?$args"
        },
        %q(~* \.(jpg|jpeg|gif|html|png|css|js|ico|txt|xml)$) => {
          "access_log"    => "off",
          "log_not_found" => "off",
          "expires"       => "365d"
        },
        %q(~* \.php$) => {
          "try_files"     => "$uri /index.php",
          "fastcgi_index" => "index.php",
          "fastcgi_pass"  => "unix:#{fpm_socket}",
          "include"       => "fastcgi_params",
          "fastcgi_param" => [
            %Q(SCRIPT_FILENAME  #{fpm_document_root options['relative_document_root'] }$fastcgi_script_name),
            %Q(SCRIPT_NAME $fastcgi_script_name),
            %Q(DOCUMENT_ROOT #{fpm_document_root options['relative_document_root']})
          ]
        },
        %q(~ ^/(status|ping)$) => {
          "access_log"    => "off",
          "allow"         => "127.0.0.1",
          "deny"          => "all",
          "include"       => "fastcgi_params",
          "fastcgi_pass"  => "unix:#{fpm_socket}"
        }
      },
      "options" => {
        "index"       => "index.php index.html index.htm",
        "access_log"  => ::File.join(www_log_dir, "#{name}-access.log"),
        "error_log"   => ::File.join(www_log_dir, "#{name}-error.log"),
      },
      "root"      => nginx_document_root(options['relative_document_root']),
      "site_type" => "dynamic"
    }.merge(options)

    self.www_logs << conf["options"]["access_log"]
    self.www_logs << conf["options"]["error_log"]

    node.set['cespi_application']['server_names'] = (node['cespi_application']['server_names'] + [ conf['server_name'] ]).uniq
    node.save unless Chef::Config[:solo]
    hostsfile_entry node.ipaddress do
      hostname  node.fqdn
      aliases   node['cespi_application']['server_names']
      action    :create
    end

    nginx_conf_file name do
      action conf['action']
      block conf['block']
      cookbook conf['cookbook']
      listen conf['listen']
      locations conf['locations']
      options conf['options']
      upstream conf['upstream']
      reload conf['reload']
      root conf['root']
      server_name conf['server_name']
      conf_name conf['conf_name']
      socket conf['socket']
      template conf['template']
      auto_enable_site conf['auto_enable_site']
      ssl conf['ssl']
      precedence conf['precedence']
      site_type conf['site_type'].to_sym
    end
  end
end

def sudo_reload(to_do)
  sudo "php_fpm reload #{new_resource.user}" do
    user      new_resource.user
    commands  ["/sbin/restart #{node[:php_fpm][:package]}"]
    action to_do
  end
end
