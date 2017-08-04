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

class hadoop_hbase {

  class deploy ($roles) {
    if ("hbase-server" in $roles) {
      include hadoop_hbase::server
    }

    if ("hbase-master" in $roles) {
      include hadoop_hbase::master
      Exec <| title == 'init hdfs' |> -> Service['hbase-master']
    }

    if ("hbase-client" in $roles) {
      include hadoop_hbase::client
    }

    if ("hbase-thrift-server" in $roles) {
      include hadoop_hbase::thrift_server
    }

    if ("hbase-rest-server" in $roles) {
      include hadoop_hbase::rest_server
    }

  }

  class client_package  {
    package { "hbase":
      ensure => latest,
    } 
  }

  class common_config (
    $hdfsdir = hiera('bigtop::hadoop_namenode_uri'),
    $rootdir,
    $zookeeper_quorum,
    $kerberos_realm = "",
    $heap_size="1024",
    $hbase_site_overrides = {},
    $hbase_env_overrides = {},
    $hbase_log4j_overrides = {},
    $hbase_metrics_overrides = {},
    $hbase_policy_overrides = {},
    $on_s3 = false,
    $hbase_data_dirs = suffix(hiera('emr::apps_mounted_dirs'), "/hbase")
  ) {
    include client_package
    if ($kerberos_realm) {
      require kerberos::client
      kerberos::host_keytab { "hbase": 
        spnego => true,
        require => Package["hbase"],
      }

      file { "/etc/hbase/conf/jaas.conf":
        content => template("hadoop_hbase/jaas.conf"),
        require => Package["hbase"],
      }
    }

    bigtop_file::site { "/etc/hbase/conf/hbase-site.xml":
      content => template("hadoop_hbase/hbase-site.xml"),
      overrides => $hbase_site_overrides,
      require => Package["hbase"],
    }

    bigtop_file::env { "/etc/hbase/conf/hbase-env.sh":
      content => template("hadoop_hbase/hbase-env.sh"),
      overrides => $hbase_env_overrides,
      require => Package["hbase"],
    }

    bigtop_file::properties { "/etc/hbase/conf/log4j.properties":
      overrides => $hbase_log4j_overrides,
      require => Package["hbase"],
    }

    bigtop_file::properties { "/etc/hbase/conf/hadoop-metrics2-hbase.properties":
      source => '/etc/hbase/conf/hadoop-metrics2-hbase.properties',
      overrides => $hbase_metrics_overrides,
      require => Package["hbase"],
    }

    bigtop_file::site { "/etc/hbase/conf/hbase-policy.xml":
      source => '/etc/hbase/conf/hbase-policy.xml',
      overrides => $hbase_policy_overrides,
      require => Package["hbase"],
    }

    hadoop::create_storage_dir { $hadoop_hbase::common_config::hbase_data_dirs: } ->
    file { $hadoop_hbase::common_config::hbase_data_dirs:
      ensure => directory,
      owner => hbase,
      group => hbase,
      mode => "0644",
      require => [Package["hbase"]],
    }
  }

  class client {
    include common_config
  }

  class server {
    include common_config

    unless !$hadoop_hbase::common_config::on_s3 and hiera('emr::node_type') == "task" {
      package { "hbase-regionserver":
        ensure => latest,
      }

      service { "hbase-regionserver":
        ensure => running,
        require => Package["hbase-regionserver"],
        subscribe => [Bigtop_file::Site["/etc/hbase/conf/hbase-site.xml"], Bigtop_file::Env["/etc/hbase/conf/hbase-env.sh"]],
        hasrestart => true,
        hasstatus => true,
      }
      Kerberos::Host_keytab <| title == "hbase" |> -> Service["hbase-regionserver"]
    }
  }

  class master {
    include common_config

    package { "hbase-master":
      ensure => latest,
    }

    service { "hbase-master":
      ensure => running,
      require => Package["hbase-master"],
      subscribe => [Bigtop_file::Site["/etc/hbase/conf/hbase-site.xml"], Bigtop_file::Env["/etc/hbase/conf/hbase-env.sh"]],
      hasrestart => true,
      hasstatus => true,
    } 
    Kerberos::Host_keytab <| title == "hbase" |> -> Service["hbase-master"]
  }

  class thrift_server {
    include common_config

    package { "hbase-thrift":
      ensure => latest,
    }

    service { "hbase-thrift":
        ensure => running,
        require => Package["hbase-thrift"],
        subscribe => [Bigtop_file::Site["/etc/hbase/conf/hbase-site.xml"], Bigtop_file::Env["/etc/hbase/conf/hbase-env.sh"]],
        hasrestart => true,
        hasstatus => true,
    }
    Kerberos::Host_keytab <| title == "hbase" |> -> Service["hbase-thrift"]
  }

  class rest_server {
    include common_config

    package { "hbase-rest":
      ensure => latest,
    }

    service { "hbase-rest":
        ensure => running,
        require => Package["hbase-rest"],
        subscribe => [Bigtop_file::Site["/etc/hbase/conf/hbase-site.xml"], Bigtop_file::Env["/etc/hbase/conf/hbase-env.sh"]],
        hasrestart => true,
        hasstatus => true,
    }
    Kerberos::Host_keytab <| title == "hbase" |> -> Service["hbase-rest"]
  }
}
