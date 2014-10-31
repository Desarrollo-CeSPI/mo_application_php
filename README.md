# cespi_application_php-cookbook

LWRP that extends [cespi_application](https://git.cespi.unlp.edu.ar/produccion/cespi_application) for PHP applications

## Usage

Just include this recipe as a dependency and use provided LWRPs:

### Resource `cespi_application_php`

Is the specialized version of cespi_application for PHP apps doing the following
tasks:

* Creates a chroot directory
* Creates log directories for nginx & pfp-fpm services inside chrooted
  environment
* Deploys application, but if **deploy** parameter is set to false, it creates an empty applications
  directory
* Creates link inside application's user home directory pointing to applications
  directory & logs
* Configures php-fpm pool & nginx site

#### Relevant parameters are:

* **path**: root applications chrooted directory
* **relative_path**: directory relative to **path** where application will be
  deployed. It defaults to **app**
* **nginx_config**: hash to be merged with default values. This values are defined as a hash of:
  * **key** is vhost file name, it will namespaced with cespi_application name attribute
  * **value** is a hash of nginx options. Most values can be overwritten. Custom options are:
    * **relative_document_root:** as deploy resource will create a current symlink, then specified path
      for this option must be a relative project path: by default we asume it is `web/`
* **php_fpm_config**: hash to be merged with default values shown in following
  table . Most values wont need to be overwritten

```
# PHP-fpm default values

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
```
Where:
* new_resource.user is user parameter
* new_resource.path is path parameter 
* fpm_relative_socket is `run/php5-fpm.socket`
* fpm_log is `new_resource_path/log/fpm/access.log`
* www_group is nginx group
* session_dir is `var/lib/session/php` relative to chrooted environment

### Resource `cespi_application_php_symfony`

Specific symfony deploy resource. It provides for example symfony clear_cache
helper that can be used inside resource
It also configures some predefined options

## Recipes

### Recipe `cespi_application_php::install`

Installs all requirements

## TODO
* php-fpm dependency cookbook restarts service on every chef-run. See [Reported BUG](https://github.com/stajkowski/php5-fpm/issues/2)
