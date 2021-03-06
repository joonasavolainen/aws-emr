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

class livy {

  class deploy ($roles) {
    if ('livy-server' in $roles) {
      include livy::server
    }
  }

  class common(
    $server_port          = undef,
    $master_url           = 'yarn',
    $livy_conf_overrides  = {},
    $livy_env_overrides   = {},
    $livy_log4j_overrides = {},
    $kerberos_realm       = '',
    $use_jwt              = false,
    $knox_gateway_identity_pem = hiera('knox::common::gateway_identity_pem'),
  ) {

    package { 'livy':
      ensure => latest,
    }

    bigtop_file::env { '/etc/livy/conf/livy-env.sh':
      content   => template('livy/livy-env.sh'),
      overrides => $livy_env_overrides,
      require   => Package['livy']
    }

    bigtop_file::conf { '/etc/livy/conf/livy.conf':
      content => template('livy/livy.conf'),
      overrides => $livy_conf_overrides,
      require => Package['livy'],
    }

    bigtop_file::properties { '/etc/livy/conf/log4j.properties':
      content => template('livy/log4j.properties'),
      overrides => $livy_log4j_overrides,
      require => Package['livy'],
    }

    if ($kerberos_realm != '') {
      kerberos::host_keytab { 'livy':
        spnego => true,
      }
    }
  }

  class server {
    include livy::common

    Kerberos::Host_keytab <| title == 'livy' |> -> Service['livy-server']

    service { 'livy-server':
      ensure     => running,
      require    => [
        Package['livy']
      ],
      hasrestart => true,
      hasstatus  => true,
      subscribe => [
        Bigtop_file::Site["/etc/hadoop/conf/yarn-site.xml"],
        Bigtop_file::Env['/etc/livy/conf/livy-env.sh'],
        Bigtop_file::Conf['/etc/livy/conf/livy.conf']
      ]
    }
  }
}
