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

class spark {

  class deploy ($roles) {
    if ('spark-client' in $roles) {
      include spark::client
    }

    if ('spark-on-yarn' in $roles) {
      include spark::yarn
    }

    if ('spark-yarn-slave' in $roles) {
      include spark::yarn_slave
    }

    if ('spark-master' in $roles) {
      include spark::master
    }

    if ('spark-worker' in $roles) {
      include spark::worker
    }

    if ('spark-history-server' in $roles) {
      include spark::history_server
    }

    if ('spark-thriftserver' in $roles) {
      include spark::thriftserver
    }
  }

  class client {
    include spark::common

    package { 'spark-python':
      ensure => latest,
      require => Package['spark-core'],
    }

    package { 'spark-R':
      ensure => latest,
      require => Package['spark-core'],
    }

    package { 'spark-external':
      ensure  => latest,
      require => Package['spark-core'],
    }
  }

  class master {
    include spark::common

    package { 'spark-master':
      ensure => latest,
    }

    service { 'spark-master':
      ensure => running,
      subscribe => [
        Package['spark-master'],
        Bigtop_file::Env['/etc/spark/conf/spark-env.sh'],
        Bigtop_file::Spark_conf['/etc/spark/conf/spark-defaults.conf'],
      ],
      hasstatus => true,
    }
  }

  class worker {
    include spark::common

    package { 'spark-worker':
      ensure => latest,
    }

    service { 'spark-worker':
      ensure => running,
      subscribe => [
        Package['spark-worker'],
        Bigtop_file::Env['/etc/spark/conf/spark-env.sh'],
        Bigtop_file::Spark_conf['/etc/spark/conf/spark-defaults.conf'],
      ],
      hasstatus => true,
    }
  }

  class history_server {
    include spark::common

    package { 'spark-history-server':
      ensure => latest,
    }

    service { 'spark-history-server':
      ensure => running,
      subscribe => [
        Package['spark-history-server'],
        Bigtop_file::Env['/etc/spark/conf/spark-env.sh'],
        Bigtop_file::Spark_conf['/etc/spark/conf/spark-defaults.conf'],
      ],
      hasstatus => true,
    }
  }

  class thriftserver {
    include spark::common

    package { 'spark-thriftserver':
      ensure => latest,
    }

    service { 'spark-thriftserver':
      ensure => running,
      subscribe => [
        Package['spark-thriftserver'],
        Bigtop_file::Env['/etc/spark/conf/spark-env.sh'],
        Bigtop_file::Spark_conf['/etc/spark/conf/spark-defaults.conf'],
      ],
      hasstatus => true,
    }
    Service<| title == 'hive-metastore' |> -> Service['spark-thriftserver']
  }

  class yarn {
    include spark::common
    include spark::datanucleus
  }

  class yarn_slave {
    include spark::yarn_shuffle
    include spark::datanucleus
  }

  class yarn_shuffle {
    package { 'spark-yarn-shuffle':
      ensure => latest,
    }
  }

  class datanucleus {
    package { 'spark-datanucleus':
      ensure => latest,
    }
  }

  class common(
      $master_url = 'yarn',
      $master_host = $fqdn,
      $master_port = 7077,
      $worker_port = 7078,
      $master_ui_port = 8080,
      $worker_ui_port = 8081,
      $history_ui_port = 18080,
      $thriftserver_bind_host = '0.0.0.0',
      $thriftserver_port = 10001,
      $spark_log4j_overrides = {},
      $spark_env_overrides = {},
      $spark_defaults_overrides = {},
      $spark_metrics_overrides = {},
      $hadoop_lzo_codec = false,
      $metastore_server_uris = [],
      $metastore_database_type = 'derby',
      $metastore_database_host = $fqdn,
      $metastore_database_port = '3306',
      $metastore_database_name = 'hive',
      $metastore_database_user = 'hive',
      $metastore_database_password = 'hive',
      $hive_site_overrides = {},
      $use_hive = false,
      $use_emrfs = false,
      $use_alluxio = false,
      $use_aws_hm_client = false,
      $use_yarn_shuffle_service = false,
      $event_log_dir =  'hdfs:///var/log/spark/apps',
      $history_log_dir = 'hdfs:///var/log/spark/apps',
  ) {

    if ($hadoop_lzo_codec) {
      include hadoop::lzo_codec
      Package['hadoop-lzo'] -> Bigtop_file::Env['/etc/spark/conf/spark-env.sh']
    }

    if ($use_emrfs) {
      include emrfs::library
      Bigtop_file::Site['/usr/share/aws/emr/emrfs/conf/emrfs-site.xml'] -> Bigtop_file::Env['/etc/spark/conf/spark-env.sh']
    }

    if ($use_hive) or ($use_aws_hm_client) {
      bigtop_file::site { '/etc/spark/conf/hive-site.xml':
        content => template('spark/hive-site.xml'),
        overrides => $hive_site_overrides,
        require => Package['spark-core'],
      }
    }

    if ($use_hive) {
      $metastore_database_url = generate_metastore_url(
        $metastore_database_type,
        $metastore_database_host,
        $metastore_database_port,
        $metastore_database_name
      )
      $metastore_database_driver_class = get_metastore_driver_class($metastore_database_type)
    }

    if ($use_aws_hm_client) {
      include aws_hm_client::library
    }

    package { 'spark-core':
      ensure => latest,
    }

    bigtop_file::env { '/etc/spark/conf/spark-env.sh':
      content => template('spark/spark-env.sh'),
      overrides => $spark_env_overrides,
      require => Package['spark-core'],
    }

    bigtop_file::spark_conf { '/etc/spark/conf/spark-defaults.conf':
      content => template('spark/spark-defaults.conf'),
      overrides => $spark_defaults_overrides,
      require => Package['spark-core'],
    }

    bigtop_file::properties { '/etc/spark/conf/log4j.properties':
      overrides => $spark_log4j_overrides,
      source => '/etc/spark/conf/log4j.properties.template',
      require => Package['spark-core'],
    }

    bigtop_file::properties { '/etc/spark/conf/metrics.properties':
      overrides => $spark_metrics_overrides,
      source => '/etc/spark/conf/metrics.properties.template',
      require => Package['spark-core'],
    }
  }
}
