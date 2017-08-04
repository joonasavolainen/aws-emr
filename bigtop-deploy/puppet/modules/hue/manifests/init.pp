# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

class hue {
  class deploy ($roles) {
    if ("hue-server" in $roles) {
      include hue::server
      if ("httpfs-server" in $roles) {
        Class['Hadoop::Httpfs'] -> Class['Hue::Server']
      }
      if ("hbase-client" in $roles) {
        Class['Hadoop_hbase::Client'] -> Class['Hue::Server']
      }
    }
  }

  class server($sqoop2_url = "http://localhost:12000/sqoop", $solr_url = "http://localhost:8983/solr/", $hbase_thrift_url = "",
               $webhdfs_url, $rm_host, $rm_port, $oozie_url, $rm_proxy_url, $history_server_url,
               $hive_host = "", $hive_port = "10000",
		$zookeeper_host_port = "localhost:2181",
               $force_username_lowercase = "false",
               $group_filter_value = "objectclass=groupOfEntries",
               $nt_domain = undef,
               $use_ldap_username_pattern = false,
               $ldap_username_pattern = undef,
               $remote_deployement_dir = "/user/hue/oozie/deployments",
               $rm_logical_name = undef, $rm_api_port = "8088", $app_blacklist = "impala, security",
               $hue_host = "0.0.0.0", $hue_port = "8888", $hue_timezone = "America/Los_Angeles",
               $default_fs = "hdfs://localhost:8020",
               $kerberos_realm = "", $kerberos_principal = "", $huecert = undef, $huekey = undef,
               $auth_backend = "desktop.auth.backend.AllowFirstUserDjangoBackend",
               $ldap_url = undef, $ldap_cert = undef, $use_start_tls = "true",
               $base_dn = undef , $bind_dn = undef, $bind_password = undef,
               $user_name_attr = undef, $user_filter = undef,
               $group_member_attr = undef, $group_filter = undef,
               $generate_secrets = false,
               $generate_secret_key_options = { length => 50, charset => 'alphanumeric' },
               $secret_key = 'Geheim!',
               $hue_apps = "all", $hue_ini_overrides = {}, $default_hdfs_superuser = "hdfs" ) {

    $hue_packages = $hue_apps ? {
      "all"     => [ "hue", "hue-server" ], # The hue metapackage requires all apps
      "none"    => [ "hue-server" ],
      default   => concat(prefix($hue_apps, "hue-"), [ "hue-server" ])
    }

    if ($generate_secrets) {
      $desktop_secret_key = trocla('hue_secret_key', 'plain', $generate_secret_key_options)
    } else {
      $desktop_secret_key = $secret_key
    }

    if ($kerberos_realm) {
      require kerberos::client
      kerberos::host_keytab { "hue":
        spnego => false,
        require => Package["hue-server"],
      }
    }

    package { $hue_packages:
      ensure => latest,
    }

    file { "/etc/hue/conf/hue.ini":
      content => template("hue/hue.ini"),
      require => Package[$hue_packages],
    }

    $json_overrides = to_json($hue_ini_overrides)
    exec { 'hue_config_override':
      path        => ['/bin', '/usr/bin', '/usr/lib/hue/build/env/bin'],
      environment => "CONFIG_OVERRIDE=$json_overrides",
      command     => 'hue config_override -i "$CONFIG_OVERRIDE"',
      subscribe   => File['/etc/hue/conf/hue.ini'],
      refreshonly => true,
    }

    exec { 'hue_syncdb':
      path        => ['/bin', '/usr/bin', '/usr/lib/hue/build/env/bin'],
      user        => 'hue',
      environment => 'DESKTOP_LOG_DIR=/var/log/hue',
      command     => 'hue syncdb --noinput -v 3',
      subscribe   => Exec['hue_config_override'],
      refreshonly => true,
      logoutput   => true,
    }

    exec { 'hue_migrate':
      path        => ['/bin', '/usr/bin', '/usr/lib/hue/build/env/bin'],
      user        => 'hue',
      environment => 'DESKTOP_LOG_DIR=/var/log/hue',
      command     => 'hue migrate --all -v 3',
      subscribe   => Exec['hue_config_override'],
      refreshonly => true,
      logoutput   => true,
    }
    Exec['hue_syncdb'] -> Exec['hue_migrate']

    service { "hue":
      ensure => running,
      require => [ Exec['hue_syncdb'], Exec['hue_migrate'] ],
      subscribe => [ Package[$hue_packages], File["/etc/hue/conf/hue.ini"], Exec["hue_config_override"] ],
      hasrestart => true,
      hasstatus => true,
    }
    Kerberos::Host_keytab <| title == "hue" |> -> Service["hue"]

  }
}
