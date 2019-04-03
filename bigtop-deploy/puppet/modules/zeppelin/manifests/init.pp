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

class zeppelin {

  class deploy ($roles) {
    if ('zeppelin-server' in $roles) {
      include zeppelin::server
    }

    if ('zeppelin-user' in $roles) {
      include zeppelin::zeppelin_user
    }
  }

  class server(
      $spark_master_url = 'yarn-client',
      $server_port = 9080,
      $hiveserver2_url = 'jdbc:hive2://localhost:10000',
      $hiveserver2_user = 'hive',
      $hiveserver2_password = '',
      $hadoop_lzo_codec = false,
      $use_emrfs = false,
      $use_hive = false,
      $use_aws_hm_client = false,
      $use_aws_sagemaker_spark_sdk = false,
      $zeppelin_env_overrides = {},
      $enableShiro = false,
      $enableKnoxAuthenticationFilter = false,
      $shiro_ini_overrides = {},
      $knox_server_port = hiera('knox::common::server_port'),
      $knoxsso_endpoint = hiera('knox::common::knoxsso_endpoint'),
      $knoxsso_out_endpoint = hiera('knox::common::knoxsso_out_endpoint'),
      $knox_gateway_identity_pem = hiera('knox::common::gateway_identity_pem'),
      $kerberos_realm = undef,
      $livy_server_port = hiera('livy::common::server_port'),
      $use_kerberos = (hiera("hadoop::hadoop_security_authentication", undef) == 'kerberos')) {
  
    package { 'zeppelin':
      ensure => latest,
    }

    bigtop_file::env { '/etc/zeppelin/conf/zeppelin-env.sh':
      content   => template('zeppelin/zeppelin-env.sh'),
      overrides => $zeppelin_env_overrides,
      require   => Package['zeppelin'],
    }

    file { '/etc/zeppelin/conf/interpreter.json':
      content => template('zeppelin/interpreter.json'),
      require => Package['zeppelin'],
      owner   => 'zeppelin',
      group   => 'zeppelin',
    }

    if ($enableShiro) {
      bigtop_file::ini { '/etc/zeppelin/conf/shiro.ini':
        content => template('zeppelin/shiro.ini'),
        overrides => $shiro_ini_overrides,
        require => Package['zeppelin'],
      }
      File <| title == '/etc/zeppelin/conf/shiro.ini' |> ~> Service['zeppelin']
    }

    service { 'zeppelin':
      ensure     => running,
      subscribe  => [ Package['zeppelin'], Bigtop_file::Env['/etc/zeppelin/conf/zeppelin-env.sh'], File['/etc/zeppelin/conf/interpreter.json'], ],
      hasrestart => true,
      hasstatus  => true,
    }

    if ($use_hive) {
      File <| title == '/etc/hive/conf/hive-site.xml' |> ~> Service['zeppelin']
    }

    if ($use_kerberos) {
      kerberos::host_keytab { 'zeppelin': }
    }
  }

  class zeppelin_user {
    user { 'zeppelin':
      ensure     => present,
      system     => true,
      managehome => true,
      home       => '/var/lib/zeppelin',
      shell      => '/sbin/nologin',
      comment    => 'Zeppelin',
    }
  }
}
