
include_recipe "mysql::server"

if platform_family?(%w{debian})

    Chef::Log.info("Installing package for pinba")

    ["cmake", "libprotobuf-dev", "libprotobuf-lite7", "libprotobuf7", "protobuf-compiler", "libjudydebian1", "libjudy-dev", "libevent-dev", "libevent-2.0-5", "libevent-core-2.0-5", "libevent-extra-2.0-5", "libevent-openssl-2.0-5", "libevent-pthreads-2.0-5", "libncurses5-dev"].each do |pkg|
      package pkg
    end

    pinba_install "pinba-server" do
      tmp_dir "/tmp/pinba"
      download_url node['pinba']['server']['src_data']
      plugin_mysql_path node['pinba']['server']['plugin_mysql_path']
    end

  else
    Chef::Log.error "There are no required pinba library packages for this platform; please use the source or binary method to install node"
    return
end