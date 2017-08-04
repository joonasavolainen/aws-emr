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
      $zeppelin_env_overrides = {}) {
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

    # Build matplotlib cache ahead of time and to prevent unnecessary warnings
    exec { 'Build matplotlib font cache':
      command => '/usr/bin/python -c "import matplotlib; matplotlib.use(\'agg\'); import matplotlib.pyplot"',
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
  }
}
