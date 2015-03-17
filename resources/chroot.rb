actions :create, :remove
default_action :create
include MoApplication::ChrootResourceBase
include MoApplicationPhp::ChrootResourceBase

def initialize(name, run_context=nil)
  super
  @copy_files = lazy { php_fpm_required_files }
  @provider = lookup_provider_constant :mo_application_chroot
end

