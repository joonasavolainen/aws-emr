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
class flink {

  class deploy ($roles) {
    if ("flink-client" in $roles) {
      include flink::client
    }
  }

  class client (
    $flink_conf_overrides = {},
    $flink_log4j_overrides = {},
    $flink_log4j_yarn_session_overrides = {},
    $flink_log4j_cli_overrides = {},
    $storage_dirs = undef,
    $yarn_conf_dir = undef,
    $hadoop_conf_dir = undef,
  ) {
    include hadoop::common

    package { "flink":
      ensure => latest,
      require => Package["hadoop"],
    }

    bigtop_file::properties { '/etc/flink/conf/log4j.properties':
      content => template('flink/log4j.properties'),
      overrides => $flink_log4j_overrides,
      require => Package['flink'], 
    } 

    bigtop_file::properties { '/etc/flink/conf/log4j-yarn-session.properties':
      content => template('flink/log4j-yarn-session.properties'),
      overrides => $flink_log4j_yarn_session_overrides,
      require => Package['flink'], 
    } 

    bigtop_file::properties { '/etc/flink/conf/log4j-cli.properties':
      content => template('flink/log4j-cli.properties'),
      overrides => $flink_log4j_cli_overrides,
      require => Package['flink'], 
    }

    bigtop_file::yaml { '/etc/flink/conf/flink-conf.yaml':
      content => template('flink/flink-conf.yaml'),
      overrides => $flink_conf_overrides,
      require => Package['flink'], 
    }
  }
}
