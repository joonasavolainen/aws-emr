# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the 'License'); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an 'AS IS' BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

class phoenix {

  class deploy ($roles) {
    if ('phoenix-library' in $roles) {
      include phoenix::library
    }
    if ('phoenix-query-server' in $roles) {
      include phoenix::query_server
    }
  }

  class common(
    $phoenix_hbase_metrics_overrides = {},
    $phoenix_hbase_site_overrides = {},
    $phoenix_log4j_overrides = {},
    $phoenix_metrics_overrides = {},
  ) {
    package { 'phoenix':
      ensure => latest,
    }

    bigtop_file::site { '/etc/phoenix/conf/hbase-site.xml':
      overrides => $phoenix_hbase_site_overrides,
      require => Package['phoenix'],
    }

    bigtop_file::properties { '/etc/phoenix/conf/hadoop-metrics2-hbase.properties':
      overrides => $phoenix_hbase_metrics_overrides,
      require => Package['phoenix'],
    }

    bigtop_file::properties { '/etc/phoenix/conf/log4j.properties':
      overrides => $phoenix_log4j_overrides,
      require => Package['phoenix'],
    }

    bigtop_file::properties { '/etc/phoenix/conf/hadoop-metrics2-phoenix.properties':
      overrides => $phoenix_metrics_overrides,
      require => Package['phoenix'],
    }
  }

  class library {
    include phoenix::common
  }

  class query_server(
  ) {
    include phoenix::common

    package { 'phoenix-queryserver':
      ensure => latest,
    }

    service { 'phoenix-queryserver':
      ensure => running,
      require => Package['phoenix-queryserver'],
      subscribe => Bigtop_file::Properties['/etc/phoenix/conf/log4j.properties'],
      hasrestart => true,
      hasstatus => true,
    }
  }
}
