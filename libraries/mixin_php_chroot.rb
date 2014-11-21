class MoApplicationPhp
  module ChrootResourceBase
    def self.included(klass)
      require 'chef/mixin/shell_out'
      klass.send(:include , Chef::Mixin::ShellOut)
      klass.attribute :copy_files, :kind_of => [Array,String], :default => []
      klass.attribute :chroot, :kind_of => [TrueClass,FalseClass], :default => false
    end
    # php requirements for php-fpm chroot are:
    #   * php-cli required files
    #   * php extensions_dir libraries
    #   * /dev/null /dev/urandom /dev/zero
    def php_fpm_required_files
      [].tap do |arr|
        php_extension_dir = shell_out!("php -r 'echo ini_get(\"extension_dir\");'").stdout
        Chef::Application.fatal! "php extension_dir cannot be empty" if php_extension_dir.empty?
        arr.concat shell_out!("find #{php_extension_dir} -type f").stdout.split
        arr << shell_out!("which php").stdout.chomp
        arr.concat %W(/dev/zero /dev/urandom /dev/null /usr/share/zoneinfo #{which 'wkhtmltopdf'}
                      /bin/sh /usr/share/fonts /etc/fonts /etc/localtime)
      end
    end
  end
end

