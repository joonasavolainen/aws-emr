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

class hadoop_oozie (
  $oozie_http_hostname = 'localhost',
  $oozie_http_port = '11000',
) {

  $oozie_url = "http://$oozie_http_hostname:$oozie_http_port/oozie"

  class deploy ($roles) {
    if ('oozie-client' in $roles) {
      include hadoop_oozie::client
    }

    if ('oozie-server' in $roles) {
      include hadoop_oozie::server
    }
  }

  class client (
    $oozie_client_env_overrides = {},
    $oozie_url = inline_template("<%= scope.lookupvar('hadoop_oozie::oozie_url') %>")
  ) inherits hadoop_oozie {

    package { 'oozie-client':
      ensure => latest,
    }

    bigtop_file::env { '/etc/oozie/conf/oozie-client-env.sh':
      overrides => $oozie_client_env_overrides,
      content   => template('hadoop_oozie/oozie-client-env.sh'),
      require   => Package['oozie-client']
    }

  }

  class server (
    $kerberos_realm = '',
    $oozie_site_overrides = {},
    $oozie_log4j_overrides = {},
    $oozie_env_overrides = {},
    $hadoop_lzo_codec = false,
    $fs_uri = "hdfs://localhost:8020",
    $init_sharelib_tries = undef,
    $init_sharelib_try_sleep = undef,
    $init_sharelib_timeout = undef,
    $include_mysql_jdbc = false,
    $include_mariadb_jdbc = false,
    $oozie_http_hostname = inline_template("<%= scope.lookupvar('hadoop_oozie::oozie_http_hostname') %>"),
    $oozie_http_port = inline_template("<%= scope.lookupvar('hadoop_oozie::oozie_http_port') %>"),
    $oozie_url = inline_template("<%= scope.lookupvar('hadoop_oozie::oozie_url') %>"),
    $resource_manager_uri = "localhost:8032",
    $spark_master_url = 'local[*]',
    $hiveserver2_url = 'jdbc:hive2://localhost:10000/default',
    $symlink_hive_conf = false,
    $symlink_pig_conf = false,
    $symlink_tez_conf = false,
    $use_spark = false,
    $use_sqoop = false,
    $use_pig = false,
  ) inherits hadoop_oozie {

    include hadoop::init_hdfs

    exec { 'Oozie sharelib init':
      path      => '/bin:/usr/bin:/usr/lib/oozie/bin',
      user      => 'oozie',
      command   => "oozie-setup.sh sharelib create -concurrency 100 -fs $fs_uri",
      unless    => 'hdfs dfs -test -e /user/oozie/share',
      tries     => $init_sharelib_tries,
      try_sleep => $init_sharelib_try_sleep,
      timeout   => $init_sharelib_timeout,
      require   => [Package['oozie'], Package['hadoop-hdfs']],
      logoutput => true
    }

    Exec['init hdfs'] -> Exec['Oozie sharelib init']

    if ($kerberos_realm and $kerberos_realm != '') {
      Exec['Oozie kinit'] -> Exec['Oozie sharelib init']

      exec { 'Oozie kinit':
        command => "/usr/bin/kinit -kt /etc/oozie.keytab oozie/$fqdn",
        user    => 'oozie',
        require => Kerberos::Host_keytab['oozie'],
      }
    }

    $hdfs_rm = 'hdfs dfs -rm'
    $hdfs_put = 'hdfs dfs -put -f'
    $py4j_zip_path = "/usr/lib/spark/python/lib/py4j-*-src.zip"
    $pyspark_zip_path = "/usr/lib/spark/python/lib/pyspark.zip"
    $mariadb_connector_jar_path = "/usr/share/java/mariadb-connector-java.jar"
    $hive_site_path = "/etc/hive/conf.dist/hive-site.xml"
    $jackson_xc_jar_name = "jackson-xc-*.jar"
    $jackson_jaxrs_jar_name = "jackson-jaxrs-*.jar"
    $hadoop_yarn_lib_dir = "/usr/lib/hadoop-yarn/lib"
    $oozie_sharelib_spark_dir = "/user/oozie/share/lib/lib_*/spark"
    $oozie_sharelib_sqoop_dir = "/user/oozie/share/lib/lib_*/sqoop"
    $oozie_sharelib_pig_dir = "/user/oozie/share/lib/lib_*/pig"

    if ($use_spark) {
      exec { 'Oozie PySpark sharelib init':
        path      => '/bin:/usr/bin:/usr/lib/oozie/bin',
        user      => 'oozie',
        command   => "$hdfs_put $py4j_zip_path $pyspark_zip_path $oozie_sharelib_spark_dir",
        tries     => $init_sharelib_tries,
        try_sleep => $init_sharelib_try_sleep,
        timeout   => $init_sharelib_timeout,
        require   => [
          Package['oozie'],
          Package['spark-core'],
          Package['hadoop-hdfs'],
          Exec['Oozie sharelib init'],
        ],
        logoutput => true
      }
    }

    if ($use_sqoop) {
      exec { 'Oozie Sqoop sharelib init':
        path      => '/bin:/usr/bin:/usr/lib/oozie/bin',
        user      => 'oozie',
        command   => "$hdfs_put $mariadb_connector_jar_path $oozie_sharelib_sqoop_dir",
        tries     => $init_sharelib_tries,
        try_sleep => $init_sharelib_try_sleep,
        timeout   => $init_sharelib_timeout,
        require   => [
          Package['oozie'],
          Package['hadoop-hdfs'],
          Package['mariadb-connector-java'],
          Exec['Oozie sharelib init'],
        ],
        logoutput => true
      }
    }

    if ($use_pig) {
      exec { 'Oozie Pig sharelib init':
        path      => '/bin:/usr/bin:/usr/lib/oozie/bin',
        user      => 'oozie',
        command   => "$hdfs_rm $oozie_sharelib_pig_dir/$jackson_xc_jar_name $oozie_sharelib_pig_dir/$jackson_jaxrs_jar_name && \
                      $hdfs_put $hadoop_yarn_lib_dir/$jackson_xc_jar_name $hadoop_yarn_lib_dir/$jackson_jaxrs_jar_name $oozie_sharelib_pig_dir && \
                      $hdfs_put $hive_site_path $oozie_sharelib_pig_dir",
        tries     => $init_sharelib_tries,
        try_sleep => $init_sharelib_try_sleep,
        timeout   => $init_sharelib_timeout,
        require   => [
          Package['oozie'],
          Package['hadoop-hdfs'],
          Package["hive"],
          Package['pig'],
          Exec['Oozie sharelib init'],
        ],
        logoutput => true
      }
    }

    if ($kerberos_realm and $kerberos_realm != "") {
      require kerberos::client
      kerberos::host_keytab { 'oozie':
        spnego  => true,
        require => Package['oozie'],
      }
    }

    if ($hadoop_lzo_codec) {
      include hadoop::lzo_codec
      file { '/usr/lib/oozie/libext/hadoop-lzo.jar':
        ensure  => 'link',
        target  => '/usr/lib/hadoop-lzo/lib/hadoop-lzo.jar',
        require => [ Package['hadoop-lzo'], Package['oozie'] ]
      }
    }

    if ($include_mysql_jdbc) {
      mysql_connector::link { '/usr/lib/oozie/libext/mysql-connector-java.jar':
        require => Package['oozie']
      }
    }

    if ($include_mariadb_jdbc) {
      mariadb_connector::link {'/usr/lib/oozie/libext/mariadb-connector-java.jar':
        require => Package['oozie'],
      }
    }

    package { 'oozie':
      ensure  => latest
    }

    bigtop_file::site { '/etc/oozie/conf/oozie-site.xml':
      content   => template('hadoop_oozie/oozie-site.xml'),
      overrides => $oozie_site_overrides,
      require   => Package['oozie']
    }

    bigtop_file::properties { '/etc/oozie/conf/oozie-log4j.properties':
      overrides => $oozie_log4j_overrides,
      require   => Package['oozie']
    }

    bigtop_file::env { '/etc/oozie/conf/oozie-env.sh':
      content   => template('hadoop_oozie/oozie-env.sh'),
      overrides => $oozie_env_overrides,
      require   => Package['oozie']
    }

    file { '/etc/oozie/conf/install-oozie-examples-env.sh':
      ensure    => file,
      content   => template('hadoop_oozie/install-oozie-examples-env.sh'),
      require   => Package['oozie']
    }

    file { '/etc/oozie/conf/action-conf/hive':
      ensure  => directory,
      require => Package['oozie']
    }

    file { '/etc/oozie/conf/action-conf/pig':
      ensure  => directory,
      require => Package['oozie']
    }

    if ($symlink_tez_conf) {
      file { '/etc/oozie/conf/action-conf/hive/tez-site.xml':
        ensure  => link,
        target  => '/etc/tez/conf/tez-site.xml',
        require => File['/etc/oozie/conf/action-conf/hive'],
        notify  => Service['oozie']
      }

      file { '/etc/oozie/conf/action-conf/pig/tez-site.xml':
        ensure  => link,
        target  => '/etc/tez/conf/tez-site.xml',
        require => File['/etc/oozie/conf/action-conf/pig'],
        notify  => Service['oozie']
      }

      Bigtop_file::Site <| title == '/etc/tez/conf/tez-site.xml' |> -> File['/etc/oozie/conf/action-conf/hive/tez-site.xml']
      Bigtop_file::Site <| title == '/etc/tez/conf/tez-site.xml' |> -> File['/etc/oozie/conf/action-conf/pig/tez-site.xml']
      Bigtop_file::Site <| title == '/etc/tez/conf/tez-site.xml' |> ~> Service['oozie']
    }

    if ($symlink_hive_conf) {
      file { '/etc/oozie/conf/action-conf/hive/hive-site.xml':
        ensure  => link,
        target  => '/etc/hive/conf/hive-site.xml',
        require => File['/etc/oozie/conf/action-conf/hive'],
        notify  => Service['oozie']
      }

      file { '/etc/oozie/conf/action-conf/pig/hive-site.xml':
        ensure  => link,
        target  => '/etc/hive/conf/hive-site.xml',
        require => File['/etc/oozie/conf/action-conf/hive'],
        notify  => Service['oozie']
      }

      Bigtop_file::Site <| title == '/etc/hive/conf/hive-site.xml' |> -> File['/etc/oozie/conf/action-conf/hive/hive-site.xml']
      Bigtop_file::Site <| title == '/etc/hive/conf/hive-site.xml' |> -> File['/etc/oozie/conf/action-conf/pig/hive-site.xml']
      Bigtop_file::Site <| title == '/etc/hive/conf/hive-site.xml' |> ~> Service['oozie']
    
    }

    if ($symlink_pig_conf) {
      file { '/etc/oozie/conf/action-conf/pig/pig.properties':
        ensure  => link,
        target  => '/etc/pig/conf/pig.properties',
        require => File['/etc/oozie/conf/action-conf/pig'],
        notify  => Service['oozie']
      }

      File <| title == '/etc/pig/conf/pig.properties' |> -> File['/etc/oozie/conf/action-conf/pig/pig.properties']
      File <| title == '/etc/pig/conf/pig.properties' |> ~> Service['oozie']
    }

    exec { 'Oozie DB init':
      path        => '/bin:/usr/bin:/usr/lib/oozie/bin/',
      environment => "OOZIE_URL=$oozie_url",
      command     => 'ooziedb.sh create -run',
      user        => 'oozie',
      returns     => 0,
      unless      => 'oozie admin -status || ooziedb.sh version',
      require     => [
        Package['oozie'],
        Bigtop_file::Env['/etc/oozie/conf/oozie-env.sh'],
        Bigtop_file::Site['/etc/oozie/conf/oozie-site.xml']
      ]
    }

    service { 'oozie':
      ensure     => running,
      require    => [
        Package['oozie'],
        Exec['Oozie DB init'],
        Exec['Oozie sharelib init']
      ],
      subscribe  => [
        Bigtop_file::Env['/etc/oozie/conf/oozie-env.sh'],
        Bigtop_file::Site['/etc/oozie/conf/oozie-site.xml']
      ],
      hasrestart => true,
      hasstatus  => true
    }
    Kerberos::Host_keytab <| title == 'oozie' |> -> Service['oozie']

  }
}
