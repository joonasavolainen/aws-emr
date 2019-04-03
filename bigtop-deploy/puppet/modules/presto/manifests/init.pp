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

class presto {

  class deploy ($roles) {
    if ('presto-coordinator' in $roles) and ('presto-worker' in $roles) {
      include presto::single_mode
    } elsif ('presto-coordinator' in $roles) {
      include presto::coordinator
    } elsif ('presto-worker' in $roles) {
      include presto::worker
    }
  }

  class common (
    $jvm_max_memory                  = ceiling(to_bytes($memorysize)*0.80),
    $query_max_memory                = '30GB',
    $jvm_nursery_memory              = '512M',
    $java8_home                      = '/usr/lib/jvm/java-1.8.0',
    $discovery_host                  = hiera('bigtop::hadoop_head_node'),
    $http_port                       = hiera('presto::common::http_port'),
    $hive_s3_staging_dir             = '/tmp/',
    $coordinator                     = false,
    $include_coordinator_in_schedule = false,
    $node_id                         = generate_node_id(),
    $presto_config_overrides         = {},
    $presto_password_auth_overrides  = {},
    $presto_hive_overrides           = {},
    $presto_log_overrides            = {},
    $presto_env_overrides            = {},
    $presto_node_overrides           = {},
    $discovery_server_enabled        = undef,
    $presto_mysql_overrides          = undef,
    $presto_ldap_user                = undef,
    $presto_ldap_password            = undef,
    $presto_postgresql_overrides     = undef,
    $presto_blackhole_overrides      = undef,
    $presto_cassandra_overrides      = undef,
    $presto_jmx_overrides            = undef,
    $presto_localfile_overrides      = undef,
    $presto_kafka_overrides          = undef,
    $presto_memory_overrides         = undef,
    $presto_mongodb_overrides        = undef,
    $presto_raptor_overrides         = undef,
    $presto_redis_overrides          = undef,
    $presto_redshift_overrides       = undef,
    $presto_tpch_overrides           = undef,
    $presto_tpcds_overrides          = undef
  ) {

    # Log final memory calculations
    notice("JVM Memory Values: Max = ${jvm_max_memory} : Nursery = ${jvm_nursery_memory}")

    # Setting max query memory to 50% of JVM Max Memory
    $query_max_mem_per_node_calc = ceiling(to_bytes($jvm_max_memory)*0.50)
    $query_max_memory_per_node = "${query_max_mem_per_node_calc}B"

    # Setting max query total memory to 60% of JVM Max Memory
    $query_max_total_mem_per_node_calc = ceiling(to_bytes($jvm_max_memory)*0.60)
    $query_max_total_memory_per_node = "${query_max_total_mem_per_node_calc}B"

    package { 'presto':
      ensure => latest,
    }

    $discovery_uri = "http://${discovery_host}:${http_port}"

    file { '/etc/presto/conf/jvm.config':
      content => template('presto/jvm.config'),
      require => Package['presto']
    }

    bigtop_file::env { '/etc/presto/conf/presto-env.sh':
      content   => template('presto/presto-env.sh'),
      require   => Package['presto'],
      overrides => $presto_env_overrides
    }

    bigtop_file::properties { '/usr/lib/presto/etc/password-authenticator.properties':
      source    => '/usr/lib/presto/etc/password-authenticator.properties.default',
      require   => Package['presto'],
      overrides => $presto_password_auth_overrides
    }

    bigtop_file::properties { '/etc/presto/conf/config.properties':
      content   => template('presto/config.properties'),
      require   => Package['presto'],
      overrides => $presto_config_overrides
    }

    bigtop_file::properties { '/etc/presto/conf/node.properties':
      content   => template('presto/node.properties'),
      require   => Package['presto'],
      overrides => $presto_node_overrides
    }

    bigtop_file::properties { '/etc/presto/conf/log.properties':
      source    => '/etc/presto/conf.dist/log.properties.default',
      require   => Package['presto'],
      overrides => $presto_log_overrides
    }

    bigtop_file::properties { '/etc/presto/conf/catalog/hive.properties':
      content   => template('presto/hive.properties'),
      require   => Package['presto'],
      overrides => $presto_hive_overrides
    }

    if ($presto_mysql_overrides != undef) {
      bigtop_file::properties { '/etc/presto/conf/catalog/mysql.properties':
        content   => 'connector.name=mysql',
        require   => Package['presto'],
        overrides => $presto_mysql_overrides,
        tag       => 'presto-catalog-properties'
      }
    }

    if ($presto_postgresql_overrides != undef) {
      bigtop_file::properties { '/etc/presto/conf/catalog/postgresql.properties':
        content   => 'connector.name=postgresql',
        require   => Package['presto'],
        overrides => $presto_postgresql_overrides,
        tag       => 'presto-catalog-properties'
      }
    }

    if ($presto_cassandra_overrides != undef) {
      bigtop_file::properties { '/etc/presto/conf/catalog/cassandra.properties':
        content   => 'connector.name=cassandra',
        require   => Package['presto'],
        overrides => $presto_cassandra_overrides,
        tag       => 'presto-catalog-properties'
      }
    }

    if ($presto_blackhole_overrides != undef) {
      bigtop_file::properties { '/etc/presto/conf/catalog/blackhole.properties':
        content   => 'connector.name=blackhole',
        require   => Package['presto'],
        overrides => $presto_blackhole_overrides,
        tag       => 'presto-catalog-properties'
      }
    }

    if ($presto_jmx_overrides != undef) {
      bigtop_file::properties { '/etc/presto/conf/catalog/jmx.properties':
        content   => 'connector.name=jmx',
        require   => Package['presto'],
        overrides => $presto_jmx_overrides,
        tag       => 'presto-catalog-properties'
      }
    }

    if ($presto_kafka_overrides != undef) {
      bigtop_file::properties { '/etc/presto/conf/catalog/kafka.properties':
        content   => 'connector.name=kafka',
        require   => Package['presto'],
        overrides => $presto_kafka_overrides,
        tag       => 'presto-catalog-properties'
      }
    }

    if ($presto_localfile_overrides != undef) {
      bigtop_file::properties { '/etc/presto/conf/catalog/localfile.properties':
        content   => 'connector.name=localfile',
        require   => Package['presto'],
        overrides => $presto_localfile_overrides,
        tag       => 'presto-catalog-properties'
      }
    }

    if ($presto_mongodb_overrides != undef) {
      bigtop_file::properties { '/etc/presto/conf/catalog/mongodb.properties':
        content   => 'connector.name=mongodb',
        require   => Package['presto'],
        overrides => $presto_mongodb_overrides,
        tag       => 'presto-catalog-properties'
      }
    }

    if ($presto_raptor_overrides != undef) {
      bigtop_file::properties { '/etc/presto/conf/catalog/raptor.properties':
        content   => template('presto/raptor.properties'),
        require   => Package['presto'],
        overrides => $presto_raptor_overrides,
        tag       => 'presto-catalog-properties'
      }
    }

    if ($presto_redis_overrides != undef) {
      bigtop_file::properties { '/etc/presto/conf/catalog/redis.properties':
        content   => 'connector.name=redis',
        require   => Package['presto'],
        overrides => $presto_redis_overrides,
        tag       => 'presto-catalog-properties'
      }
    }

    if ($presto_redshift_overrides != undef) {
      bigtop_file::properties { '/etc/presto/conf/catalog/redshift.properties':
        content   => 'connector.name=redshift',
        require   => Package['presto'],
        overrides => $presto_redshift_overrides,
        tag       => 'presto-catalog-properties'
      }
    }

    if ($presto_tpch_overrides != undef) {
      bigtop_file::properties { '/etc/presto/conf/catalog/tpch.properties':
        content   => 'connector.name=tpch',
        require   => Package['presto'],
        overrides => $presto_tpch_overrides,
        tag       => 'presto-catalog-properties'
      }
    }

    if ($presto_tpcds_overrides != undef) {
      bigtop_file::properties { '/etc/presto/conf/catalog/tpcds.properties':
        content   => 'connector.name=tpcds',
        require   => Package['presto'],
        overrides => $presto_tpcds_overrides,
        tag       => 'presto-catalog-properties'
      }
    }

    if ($presto_memory_overrides != undef) {
      bigtop_file::properties { '/etc/presto/conf/catalog/memory.properties':
        content   => 'connector.name=memory',
        require   => Package['presto'],
        overrides => $presto_memory_overrides,
        tag       => 'presto-catalog-properties'
      }
    }

    # In order for Presto to pick up emrfs-site.xml, it needs to be in a directory
    file { '/usr/lib/presto/plugin/hive-hadoop2/emrfs':
      ensure  => 'directory',
      require => Package['presto']
    }

    exec { 'symlink emrfs-site.xml':
      path => '/bin',
      command => 'ln -sf /usr/share/aws/emr/emrfs/conf/emrfs-site.xml /usr/lib/presto/plugin/hive-hadoop2/emrfs/emrfs-site.xml',
      require => [
        Package['presto'],
        File['/usr/lib/presto/plugin/hive-hadoop2/emrfs']
      ]
    }

    emrfs::link { 'link EMRFS jars':
      path => '/usr/lib/presto/plugin/hive-hadoop2/',
      require => Package["presto"]
    }
  }

  class server {
    Bigtop_file::Properties <| tag == 'presto-catalog-properties' |> ~> Service['presto-server']
    service { 'presto-server':
      ensure     => running,
      require    => [
        Package['presto'],
        Bigtop_file::Properties['/etc/presto/conf/config.properties'],
        Bigtop_file::Properties['/etc/presto/conf/catalog/hive.properties']
      ],
      hasrestart => true,
      hasstatus  => true,
      subscribe  => [
        Bigtop_file::Env['/etc/presto/conf/presto-env.sh'],
        Bigtop_file::Properties['/etc/presto/conf/catalog/hive.properties'],
        Bigtop_file::Properties['/etc/presto/conf/config.properties'],
        Bigtop_file::Properties['/etc/presto/conf/log.properties'],
        File['/etc/presto/conf/jvm.config']
      ]
    }
  }

  class single_mode {
    class { 'common':
      coordinator                     => true,
      discovery_server_enabled        => true,
      include_coordinator_in_schedule => true,
      query_max_memory                => '5GB'
    }
    include presto::server
  }

  class coordinator {
    class { 'common':
      coordinator              => true,
      discovery_server_enabled => true
    }
    include presto::server
  }

  class worker {
    class { 'common':
      coordinator              => false
    }
    include presto::server
  }
}
