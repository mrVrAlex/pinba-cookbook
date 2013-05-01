pkgs = ["libprotobuf-dev", "libprotobuf-lite7", "libprotobuf7", "protobuf-compiler"]
# install dev package which provides phpize
case node['platform']
when "centos", "redhat", "fedora"
  pkgs << "php-devel"
else
  pkgs << "php5-dev"
end

pkgs << "git"

pkgs.each do |pkg|
  package pkg do
    action :install
  end
end

gem_package "git" do
  action :install
end

# create folder for source code if not exists
execute "clone redis" do
    command "mkdir -p #{Chef::Config[:file_cache_path]}/pinba"
end

# clone pinba
git "#{Chef::Config[:file_cache_path]}/pinba" do
  repository "https://github.com/tony2001/pinba_extension.git"
  reference "master"
  notifies :run, "script[install_php_pinba]", :immediately
end

# make & install php extension
script "install_php_pinba" do
  interpreter "bash"
  user "root"
  cwd "#{Chef::Config[:file_cache_path]}/pinba"
  action :nothing
  code <<-EOH
  (phpize && ./configure && make install)
  EOH
end

# We can not find if we have apache installed or not easily, so we have this workaround in order not to restart apache when mod is installed
service = ""
# enable extension in php
file "#{node['php']['ext_conf_dir']}/pinba.ini" do
  content <<-EOH
extension=pinba.so
pinba.enabled=#{node['pinba']['client']['enabled']}
pinba.server=#{node['pinba']['client']['address']}:#{node['pinba']['client']['port']}
  EOH
  owner "root"
  group "root"
  mode "0644"
  action :create
    service = "apache2"
    notifies :reload, resources(:service => "#{service}")
end