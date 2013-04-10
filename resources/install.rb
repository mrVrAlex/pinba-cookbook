actions :run

#Uncomment this and remove the block in initialize when ready to drop support for chef <= 0.10.8
#default_action :run

#Installation attributes
attribute :download_url, :kind_of => String
attribute :tmp_dir, :kind_of => String, :default => Chef::Config[:file_cache_path]
attribute :plugin_mysql_path, :kind_of => String

def initialize(name, run_context=nil)
  super
  @action = :run
  @mysql_dir_source = nil
end