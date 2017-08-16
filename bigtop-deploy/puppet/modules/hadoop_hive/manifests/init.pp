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

class hadoop_hive {

  class deploy ($roles) {

    if ('hive-client' in $roles) {
      include hadoop_hive::client
    }

    if ('hive-metastore-server' in $roles) {
      include hadoop_hive::metastore
    }

    if ('hive-server2' in $roles) {
      include hadoop_hive::server2
      if ('hive-metastore-server' in $roles) {
        Class['Hadoop_hive::Metastore_server'] -> Class['Hadoop_hive::Server']
      }
    }

    if ('hive-hbase' in $roles) {
      include hadoop_hive::hbase
    }

    # Need to make sure local mysql server is setup correctly (in case hive is
    # using it) before initializing the schema
    if ('hive-client' or 'hive-metastore-server' or 'hive-server2' in $roles) {
      if ('mysql-server' in $roles) {
        Class['Bigtop_mysql::Server'] -> Exec<| title == 'init hive-metastore schema' |>
      }
    }
  }

  class client_package {
    package { "hive":
      ensure => latest,
    }
  }

  class common_config ($hbase_master = "",
                       $hbase_zookeeper_quorum = "",
                       $kerberos_realm = "",
                       $metastore_uris = "",
                       $server2_thrift_port = "10000",
                       $server2_thrift_http_port = "10001",
                       $hive_execution_engine = "mr",
                       $metastore_server_uris = [],
                       $metastore_database_type = 'derby',
                       $metastore_database_host = $fqdn,
                       $metastore_database_port = '3306',
                       $metastore_database_name = 'hive',
                       $metastore_database_user = 'hive',
                       $metastore_database_password = 'hive',
                       $hdfs_uri = undef,
                       $hive_env_overrides = {},
                       $hive_site_overrides = {},
                       $hive_log4j2_overrides = {},
                       $hive_exec_log4j2_overrides = {},
                       $hive_beeline_log4j2_overrides = {},
                       $hive_parquet_logging_overrides = {},
                       $hiveserver2_site_overrides = {},
                       $hive_llap_daemon_log4j2_overrides = {},
                       $user_log_dir = undef,
                       $java_tmp_dir = undef,
                       $use_dynamodb = false,
                       $use_aws_hm_client = false,
                       $use_emr_goodies = false,
                       $use_kinesis = false) {
    include hadoop_hive::client_package
    if ($kerberos_realm and $kerberos_realm != "") {
      require kerberos::client
      kerberos::host_keytab { "hive":
        spnego => true,
        require => Package["hive"],
      }
    }

    $sticky_dirs = delete_undef_values([$java_tmp_dir, $user_log_dir])

    file { $sticky_dirs :
      ensure => "directory",
      owner  => "root",
      group  => "root",
      mode   => "1777",
      require => Package['hive']
    }

    if ($use_dynamodb) {
      include emr_ddb::library

      file { '/usr/lib/hive/auxlib/emr-ddb-hive.jar':
        ensure  => link,
        target  => '/usr/share/aws/emr/ddb/lib/emr-ddb-hive.jar',
        tag     => 'hive-aux-jar',
        require => [Package['emr-ddb'], Package['hive']]
      }
    }

    if ($use_aws_hm_client) {
      include aws_hm_client::library

      file { '/usr/lib/hive/auxlib/aws-glue-datacatalog-hive2-client.jar':
        ensure  => link,
        target  => '/usr/share/aws/hmclient/lib/aws-glue-datacatalog-hive2-client.jar',
        tag     => 'hive-aux-jar',
        require => [Package['aws-hm-client'], Package['hive']]
      }
    }

    if ($use_emr_goodies) {
      include emr_goodies::library

      file { '/usr/lib/hive/auxlib/emr-hive-goodies.jar':
        ensure  => link,
        target  => '/usr/share/aws/emr/goodies/lib/emr-hive-goodies.jar',
        tag     => 'hive-aux-jar',
        require => [Package['emr-goodies'], Package['hive']]
      }
    }

    if ($use_kinesis) {
      include emr_kinesis::library

      file { '/usr/lib/hive/auxlib/emr-kinesis-hive.jar':
        ensure  => link,
        target  => '/usr/share/aws/emr/kinesis/lib/emr-kinesis-hive.jar',
        tag     => 'hive-aux-jar',
        require => [Package['emr-kinesis'], Package['hive']]
      }
    }

    $metastore_database_url = generate_metastore_url(
      $metastore_database_type,
      $metastore_database_host,
      $metastore_database_port,
      $metastore_database_name
    )
    $metastore_database_driver_class = get_metastore_driver_class($metastore_database_type)
    $metastore_database_schema_type = get_metastore_schema_type($metastore_database_type)

    bigtop_file::site { '/etc/hive/conf/hive-site.xml':
      content => template('hadoop_hive/hive-site.xml'),
      overrides => $hive_site_overrides,
      require => Package['hive'],
    }

    bigtop_file::site { '/etc/hive/conf/hiveserver2-site.xml':
      content => template('hadoop_hive/hiveserver2-site.xml'),
      overrides => $hiveserver2_site_overrides,
      require => Package['hive'],
    }

    bigtop_file::properties { '/etc/hive/conf/hive-log4j2.properties':
      content => template('hadoop_hive/hive-log4j2.properties'),
      overrides => $hive_log4j2_overrides,
      require => Package['hive'],
    }

    bigtop_file::properties { '/etc/hive/conf/hive-exec-log4j2.properties':
      overrides => $hive_exec_log4j2_overrides,
      require => Package['hive'],
    }

    bigtop_file::properties { '/etc/hive/conf/beeline-log4j2.properties':
      overrides => $hive_beeline_log4j2_overrides,
      require => Package['hive'],
    }

    bigtop_file::properties { '/etc/hive/conf/parquet-logging.properties':
      overrides => $hive_parquet_logging_overrides,
      require => Package['hive'],
    }

    bigtop_file::properties { '/etc/hive/conf/llap-daemon-log4j2.properties':
      overrides => $hive_llap_daemon_log4j2_overrides,
      require => Package['hive'],
    }

    bigtop_file::env { '/etc/hive/conf/hive-env.sh':
      overrides => $hive_env_overrides,
      content => template('hadoop_hive/hive-env.sh'),
      require => Package['hive'],
    }

    include hadoop_hive::init_metastore_schema
  }

  class client($hbase_master = "",
      $hbase_zookeeper_quorum = "",
      $hive_execution_engine = "mr") {

      include hadoop_hive::common_config
  }

  class server2 {
    include hadoop_hive::common_config

    package { 'hive-server2':
      ensure => latest,
    }

    service { 'hive-server2':
      ensure    => running,
      require   => [Package['hive'], Package['hive-server2'], Class['Hadoop_hive::Init_metastore_schema']],
      subscribe => [Bigtop_file::Site['/etc/hive/conf/hive-site.xml'], Bigtop_file::Env['/etc/hive/conf/hive-env.sh']],
      hasrestart => true,
      hasstatus => true,
    }
    Kerberos::Host_keytab <| title == "hive" |> -> Service["hive-server2"]
    Service <| title == "hive-metastore" |> -> Service["hive-server2"]
    File <| tag == 'hive-aux-jar' |> -> Service['hive-server2']
    Bigtop_file::Env <| title == '/etc/hadoop/conf/hadoop-env.sh' |> ~> Service['hive-server2']
    Bigtop_file::Site <| tag == 'hadoop-plugin' or title == '/etc/hadoop/conf/core-site.xml' |> ~> Service['hive-server2']
  }

  class metastore {
    include hadoop_hive::common_config

    package { 'hive-metastore':
      ensure => latest,
    }

    service { 'hive-metastore':
      ensure    => running,
      require   => [Package['hive'], Package['hive-metastore'], Class['Hadoop_hive::Init_metastore_schema']],
      subscribe => [Bigtop_file::Site['/etc/hive/conf/hive-site.xml'], Bigtop_file::Env['/etc/hive/conf/hive-env.sh']],
      hasrestart => true,
      hasstatus => true,
    }
    Kerberos::Host_keytab <| title == "hive" |> -> Service["hive-metastore"]
    File <| title == "/etc/hadoop/conf/core-site.xml" |> -> Service["hive-metastore"]
    File <| tag == 'hive-aux-jar' |> -> Service['hive-metastore']
    Bigtop_file::Env <| title == '/etc/hadoop/conf/hadoop-env.sh' |> ~> Service['hive-metastore']
    Bigtop_file::Site <| tag == 'hadoop-plugin' or title == '/etc/hadoop/conf/core-site.xml' |> ~> Service['hive-metastore']
  }

  class database_connector {
    include hadoop_hive::common_config

    case $common_config::metastore_database_type {
      'mysql': {
        mysql_connector::link {'/usr/lib/hive/lib/mysql-connector-java.jar':
          require => Package['hive'],
         }
      }
      'mariadb': {
         mariadb_connector::link {'/usr/lib/hive/lib/mariadb-connector-java.jar':
          require => Package['hive']
         }
      }
      'derby': {
        # do nothing
      }
      default: {
        fail("$common_config::metastore_database_type is not supported. Supported database types are ", $common_config::supported_database_types)
      }
    }
  }

  class init_metastore_schema {

    include hadoop_hive::common_config
    include hadoop_hive::database_connector

    exec { 'init hive-metastore schema':
      command   => "/usr/lib/hive/bin/schematool -dbType $common_config::metastore_database_schema_type -initSchema -verbose",
      require   => [Package['hive'], Class['Hadoop_hive::Database_connector']],
      subscribe => [Bigtop_file::Site['/etc/hive/conf/hive-site.xml'], Bigtop_file::Env['/etc/hive/conf/hive-env.sh']],
      logoutput => true,
      unless    => "/usr/lib/hive/bin/schematool -dbType $common_config::metastore_database_schema_type -info"
    }
  }

  class hbase {
    package { 'hive-hbase':
      ensure => latest,
    }
  }
}
