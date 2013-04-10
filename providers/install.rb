action :run do

    Chef::Log.info("Installing Pinba from source")

    download

    unpack

    build

    Chef::Log.info("Installing Pinba successfully")

end

def get_mysql_folder
    mysql_version = Mixlib::ShellOut.new("cd #{new_resource.tmp_dir} && find -name '*mysql-5*' -type d -print0 | xargs -0 -I {} mv {} /tmp/pinba/mysql-source")
    mysql_version.run_command
    return mysql_version.stdout
end

def download
    execute "create pinba temp folder" do
      command "mkdir -p #{new_resource.tmp_dir}"
    end

    execute "download mysql source" do
      cwd new_resource.tmp_dir
      command "apt-get source mysql-server"
    end

    execute "rename mysql source" do
      cwd new_resource.tmp_dir
      command "find -name '*mysql-5*' -type d -print0 | xargs -0 -I {} mv {} #{new_resource.tmp_dir}/mysql-source"
    end

    Chef::Log.info("Downloading pinba source")

    remote_file "#{new_resource.tmp_dir}/pinba.tar.gz" do
      source new_resource.download_url
      action :create
    end
end

def unpack
    Chef::Log.info("Unpack source")
    execute "unpack pinba source" do
      cwd new_resource.tmp_dir
      command "mkdir -p pinba-source && cd pinba-source && tar --strip-components 1 -zxf ../pinba.tar.gz"
    end
end

def build
    Chef::Log.info("Folder mysql-source #{@mysql_dir_source}")
    execute "run configure mysql-source" do
      command "cd #{new_resource.tmp_dir}/mysql-source && cmake ./ && cd include/ && make"
    end

    execute "run configure pinba" do
      cwd "#{new_resource.tmp_dir}/pinba-source"
      command "./configure --with-mysql=#{new_resource.tmp_dir}/mysql-source --libdir=/usr/lib/mysql/plugin"
    end

    execute "run make pinba" do
      cwd "#{new_resource.tmp_dir}/pinba-source"
      command "make install"
    end

end