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

class hadoop_pig {

  class deploy ($roles) {
    if ("pig-client" in $roles) {
      include hadoop_pig::client
    }
  }

  class client(
    $pig_overrides = {},
    $pig_log4j_overrides = {},
    $pig_env_overrides = {},
    $log_folder_root = undef,
    $use_kinesis = false
  ) {
    include hadoop::common

    package { "pig":
      ensure => latest,
      require => Package["hadoop"],
    }

    if ($log_folder_root) {
      file { $log_folder_root:
        ensure => 'directory',
        owner  => 'root',
        group  => 'root',
        mode   => '1777',
        require => Package['pig']
      }
    }

    if ($use_kinesis) {
      include emr_kinesis::library
      Package["emr-kinesis"] -> Bigtop_file::Env["/etc/pig/conf/pig-env.sh"]
    }

    bigtop_file::properties { "/etc/pig/conf/pig.properties":
      content => template('hadoop_pig/pig.properties'),
      overrides => $pig_overrides,
      require => Package["pig"],
    }

    bigtop_file::properties { "/etc/pig/conf/log4j.properties":
      source => '/etc/pig/conf/log4j.properties.template',
      overrides => $pig_log4j_overrides,
      require => Package["pig"],
    }

    bigtop_file::env { "/etc/pig/conf/pig-env.sh":
      content => template('hadoop_pig/pig-env.sh'),
      overrides => $pig_env_overrides,
      require => Package["pig"],
    }
  }
}
