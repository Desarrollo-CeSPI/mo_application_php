include ::CespiApplicationPhp::DefaultResourceBase

def initialize(name, run_context=nil)
  super
  @callbacks = {}
  @user = name
  @group = name
  @home = "/home/#{user}"
  @copy_files = lazy { php_fpm_required_files }
  @migrate = true
  @migration_command = <<-EOF
    #{php_command} symfony propel:build --all-classes
    #{php_command} symfony plugin:publish
    #{php_command} symfony project:permissions
    #{php_command} symfony cache:clear
  EOF
  @shared_dirs = {'log' => 'log'}
  @shared_files = {
    "config/propel.ini"                 => "config/propel.ini",
    "config/databases.yml"              => "config/databases.yml",
    "config/app.yml"                    => "config/app.yml",
  }
  @provider = lookup_provider_constant :cespi_application_php
end


