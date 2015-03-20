class MoApplicationPhp
  module DefaultResourceBase
    def self.included(klass)
      klass.send :include, MoApplication::DeployResourceBase

      # PHP-fpm options
      klass.attribute :php_fpm_config, :kind_of => Hash, :default => Hash.new

    end

    def initialize(name, run_context=nil)
      super
      @provider = lookup_provider_constant :mo_application_php
      @restart_command = "sudo service #{node[:php_fpm][:package]} restart"
      @services = [ node[:php_fpm][:package] ]
    end
  end
end
