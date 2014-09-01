include CespiApplicationPhp::ChrootResourceBase
actions :install, :remove
default_action :install

# User needs
attribute :home, :kind_of => [String, NilClass], :default => nil
attribute :shell, :kind_of => String, :default => "/bin/bash"

# Deploy needs
attribute :name, :kind_of => String, :name_attribute => true
attribute :user, :kind_of => [String, NilClass], :default => nil
attribute :group, :kind_of => [String, NilClass], :default => nil
attribute :relative_path, :kind_of => String, :default => 'app'
attribute :repo, :kind_of => String, :required => true
attribute :revision, :kind_of => [String], :default => "HEAD"
attribute :migrate, :kind_of => [TrueClass, FalseClass], :default => false
attribute :migration_command, :kind_of => [String, NilClass]
attribute :shared_dirs, :kind_of => Hash, :default => Hash.new
attribute :shared_files, :kind_of => Hash, :default => Hash.new
attribute :create_dirs_before_symlink, :kind_of => Array, :default => []
attribute :force_deploy, :kind_of => [TrueClass,FalseClass], :default => false

# Chrooted environment
attribute :path, :kind_of => String, :name_attribute => true
attribute :copy_files, :kind_of => [Array,String], :default => []

# PHP-fpm options
attribute :php_fpm_config, :kind_of => Hash, :default => Hash.new

# Nginx configurations: must define a hash of:
#   * key is vhost file name, it will namespaced with cespi_application name attribute
#   * value of nginx options. Most values can be overwritten. 
#     Custom options are:
#     + relative_document_root: as deploy resource will create a current symlink, then specified path
#       for this option must be a relative project path: by default we asume it is web/
attribute :nginx_config, :kind_of => Hash, :default => { 'frontend' => Hash.new }

attr_reader :callback_before_deploy

def before_deploy(&block)
  @callback_before_deploy= block
end


def initialize(name, run_context=nil)
  super
  @callbacks = {}
  @user = name
  @group = name
  @home = "/home/#{user}"
  @copy_files = lazy { php_fpm_required_files }
end


