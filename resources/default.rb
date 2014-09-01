include ::CespiApplicationPhp::DefaultResourceBase

def initialize(name, run_context=nil)
  super
  @callbacks = {}
  @user = name
  @group = name
  @home = "/home/#{user}"
  @copy_files = lazy { php_fpm_required_files }
end


