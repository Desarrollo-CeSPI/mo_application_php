class MoApplicationPhp
  module DefaultResourceBase
    def self.included(klass)
      klass.send :include, MoApplicationPhp::ChrootResourceBase
      klass.send :include, MoApplication::DeployResourceBase

      # Chrooted environment
      klass.attribute :copy_files, :kind_of => [Array,String], :default => []

      # PHP-fpm options
      klass.attribute :php_fpm_config, :kind_of => Hash, :default => Hash.new

    end

    def php_command
      node['mo_application_php']['command']
    end

  end
end
