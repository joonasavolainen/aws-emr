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

class hcatalog {

  class deploy ($roles) {

    if ('hcatalog-client' in $roles) {
      include hcatalog::client
    }

    if ('hcatalog-server' in $roles) {
      include hcatalog::server
    }

    if ('webhcat-server' in $roles) {
      include hcatalog::webhcat::server
    }

  }

  class common(
    $hcatalog_env_overrides = {},
    $hcatalog_jndi_overrides = {},
    $hcatalog_proto_hive_site_overrides = {},
    $metastore_port = hiera('hadoop_hive::common_config::metastore_server_port'),
  ) {
    include hadoop_hive::common_config
    package { 'hive-hcatalog':
      ensure => latest,
    }

    bigtop_file::env { '/etc/hive-hcatalog/conf/hcat-env.sh':
      content => template('hcatalog/hcat-env.sh'),
      overrides => $hcatalog_env_overrides,
      require => Package['hive-hcatalog'],
    }

    bigtop_file::properties { '/etc/hive-hcatalog/conf/jndi.properties':
      source => '/etc/hive-hcatalog/conf/jndi.properties',
      overrides => $hcatalog_jndi_overrides,
      require => Package['hive-hcatalog'],
    }

    bigtop_file::site { '/etc/hive-hcatalog/conf/proto-hive-site.xml':
      source => '/etc/hive-hcatalog/conf/proto-hive-site.xml',
      overrides => $hcatalog_proto_hive_site_overrides,
      require => Package['hive-hcatalog'],
    }
  }

  class client {
    include hcatalog::common
  }

  class server {
    include hcatalog::common

    package { 'hive-hcatalog-server':
      ensure => latest,
    }

    service { 'hive-hcatalog-server':
      ensure => running,
      require => Package['hive-hcatalog-server'],
      subscribe => [ Bigtop_file::Env['/etc/hive-hcatalog/conf/hcat-env.sh'],
                     Bigtop_file::Properties['/etc/hive-hcatalog/conf/jndi.properties'],
                     Bigtop_file::Site['/etc/hive-hcatalog/conf/proto-hive-site.xml'], ],
      hasrestart => true,
      hasstatus => true,
    }
    Exec<| title == 'init hive-metastore schema' |> -> Service['hive-hcatalog-server']
    Kerberos::Host_keytab <| title == 'hive' |> -> Service["hive-hcatalog-server"]
  }

  class webhcat {
    class common(
      $kerberos_realm = '',
      $generate_secrets = false,
      $kerberos_secret = undef,
      $webhcat_env_overrides = {},
      $webhcat_log4j2_overrides = {},
      $webhcat_site_overrides = {},
      $server_port = '50111',
    ) {

      if ($kerberos_realm != '') {
        $templeton_kerberos_secret = $generate_secrets ? {
          true => trocla('templeton_kerberos_secret', 'plain'),
          default => $kerberos_secret
        }
        if (($templeton_kerberos_secret == undef) or ($templeton_kerberos_secret == '')) {
          fail('Webhcat templeton kerberos secret must be set')
        }
      }

      package { 'hive-webhcat':
        ensure => latest,
      }

      bigtop_file::env { '/etc/hive-webhcat/conf/webhcat-env.sh':
        content => template('hcatalog/webhcat-env.sh'),
        overrides => $webhcat_env_overrides,
        require => Package['hive-webhcat'],
      }

      bigtop_file::properties { '/etc/hive-webhcat/conf/webhcat-log4j2.properties':
        source => '/etc/hive-webhcat/conf/webhcat-log4j2.properties',
        overrides => $webhcat_log4j2_overrides,
        require => Package['hive-webhcat'],
      }

      bigtop_file::site { '/etc/hive-webhcat/conf/webhcat-site.xml':
        content => template('hcatalog/webhcat.xml'),
        overrides => $webhcat_site_overrides,
        require => Package['hive-webhcat'],
      }
    }
    class server(
      $kerberos_realm = '',
    ) {
      include hcatalog::webhcat::common

      package { 'hive-webhcat-server':
        ensure => latest,
      }

      if ($kerberos_realm != '') {
        include hadoop_hive::hive_keytab
      }

      service { 'hive-webhcat-server':
        ensure => running,
        require => Package['hive-webhcat-server'],
        subscribe => [ Bigtop_file::Env['/etc/hive-webhcat/conf/webhcat-env.sh'],
                       Bigtop_file::Properties['/etc/hive-webhcat/conf/webhcat-log4j2.properties'],
                       Bigtop_file::Site['/etc/hive-webhcat/conf/webhcat-site.xml'], ],
        hasrestart => true,
        hasstatus => true,
      } 

      Kerberos::Host_keytab <| title == 'hive' |> -> Service["hive-webhcat-server"]
    }
  }
}
