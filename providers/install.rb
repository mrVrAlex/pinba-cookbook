action :run do

    execute "create pinba temp folder" do
      command "mkdir -p #{new_resource.tmp_dir}"
    end

    download_pinba

    unless pinba_exists?
        Chef::Log.info("Installing Pinba from source")
        download_mysql
        build
        Chef::Log.info("Installing Pinba successfully")
    end

    configure

end

def get_mysql_folder
    mysql_version = Mixlib::ShellOut.new("cd #{new_resource.tmp_dir} && find -name '*mysql-5*' -type d -print0 | xargs -0 -I {} mv {} /tmp/pinba/mysql-source")
    mysql_version.run_command
    return mysql_version.stdout
end

def download_pinba

    Chef::Log.info("Downloading pinba source")

    remote_file "#{new_resource.tmp_dir}/pinba.tar.gz" do
      source new_resource.download_url
      action :create
    end

    Chef::Log.info("Unpack source")

    execute "unpack pinba source" do
      cwd new_resource.tmp_dir
      command "mkdir -p pinba-source && cd pinba-source && tar --strip-components 1 -zxf ../pinba.tar.gz"
    end
end

def download_mysql

    execute "download mysql source" do
      cwd new_resource.tmp_dir
      command "apt-get source mysql-server"
    end

    execute "rename mysql source" do
      cwd new_resource.tmp_dir
      command "find -name '*mysql-5*' -type d -print0 | xargs -0 -I {} mv {} #{new_resource.tmp_dir}/mysql-source"
    end

end

def build

    execute "run configure mysql-source" do
      command "cd #{new_resource.tmp_dir}/mysql-source && cmake ./ && cd include/ && make"
    end

    execute "run configure pinba" do
      cwd "#{new_resource.tmp_dir}/pinba-source"
      command "./configure --with-mysql=#{new_resource.tmp_dir}/mysql-source --libdir=#{new_resource.plugin_mysql_path}"
    end

    execute "run make pinba" do
      cwd "#{new_resource.tmp_dir}/pinba-source"
      command "make install"
    end
end

def configure
    Chef::Log.info("Pinba configure run")

    if install_plugin?
        Chef::Log.info("Pinba plugin already configured")
    else
        Chef::Log.info("Pinba plugin install success")
    end

    unless database_confugure?
        execute "install pinba default tables" do
          cwd "#{new_resource.tmp_dir}/pinba-source"
          command "mysql -u root -p#{node['mysql']['server_root_password']} -D pinba < default_tables.sql"
        end
    end
end

def install_plugin?
    install = Mixlib::ShellOut.new("mysql -u root -p#{node['mysql']['server_root_password']} -e \"INSTALL PLUGIN pinba SONAME 'libpinba_engine.so';\"")
    install.run_command
    install.exitstatus == 1 ? true : false
end

def pinba_exists?
    exists = Mixlib::ShellOut.new("find -name '*libpinba_engine.so*' -type f", :cwd => new_resource.plugin_mysql_path)
    exists.run_command
    exists.exitstatus == 0 ? true : false
end

def database_confugure?
    exists = Mixlib::ShellOut.new("mysql -u root -p#{node['mysql']['server_root_password']} -e \"CREATE DATABASE pinba;\"")
    exists.run_command
    exists.stdout.include? 'exists'
end