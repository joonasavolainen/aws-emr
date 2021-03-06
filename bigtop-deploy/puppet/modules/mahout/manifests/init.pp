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

class mahout {

  class deploy ($roles) {
    if ("mahout-client" in $roles) {
      include mahout::client
    }
  }

  class client (
    $hadoop_lzo_codec = false,
    $use_hive = false,
    $use_emrfs = false,
    $use_spark = false,
    $mahout_env_overrides = {},
  ) {
    include hadoop::common

    package { "mahout":
      ensure => latest,
      require => Package["hadoop"],
    }

    bigtop_file::env { '/etc/mahout/conf/mahout-env.sh':
      content   => template('mahout/mahout-env.sh'),
      overrides => $mahout_env_overrides,
      require   => Package['mahout'],
    }
  }
}
