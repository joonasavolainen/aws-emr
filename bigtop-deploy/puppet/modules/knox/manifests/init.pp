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

class knox {

  class deploy ($roles) {
    if ('knox-server' in $roles) {
      include knox::server
    }
  }

  class common(
    $server_port             = undef,
    $knoxsso_endpoint        = undef,
    $knoxsso_out_endpoint    = undef,
    $gateway_site_overrides  = {},
    $gateway_log4j_overrides = {},
    $knoxcli_log4j_overrides = {},
    $knoxsso_overrides       = {},
    $enablePac4jProvider     = false,
    $idpMetadataS3Path       = undef,
    $idpMetadataFolderPath   = undef,
    $idpMetadataFileName     = undef,
    $sandbox_overrides       = {},
    $enableSSOCookieProvider = false,
    $enableTokenService      = false,
    $livy_port               = hiera('livy::common::server_port'),
    $zeppelin_port           = hiera('zeppelin::server::server_port'),
    $gateway_identity_pem    = undef,
  ) {

    package { 'knox':
      ensure => latest,
    }

    bigtop_file::site { '/etc/knox/conf/gateway-site.xml':
      content => template('knox/gateway-site.xml'),
      overrides => $gateway_site_overrides,
      require => Package['knox'],
    }

    bigtop_file::properties { '/etc/knox/conf/gateway-log4j.properties':
      overrides => $gateway_log4j_overrides,
      require => Package['knox'],
    }

    bigtop_file::properties { '/etc/knox/conf/knoxcli-log4j.properties':
      overrides => $knoxcli_log4j_overrides,
      require => Package['knox'],
    }

    exec { 'copy s3 identity provider metadata file to local':
      command => "/bin/mkdir -m 700 $idpMetadataFolderPath ; /usr/bin/aws s3 cp $idpMetadataS3Path $idpMetadataFolderPath$idpMetadataFileName",
      user    => 'knox',
      require => [
        Package['knox'],
      ],
      logoutput => true,
      returns => 0,
    }

    exec { 'create knox master':
      command => '/usr/lib/knox/bin/create_knox_master.sh',
      user    => 'knox',
      require => [
        Package['knox'],
        Bigtop_file::Properties['/etc/knox/conf/knoxcli-log4j.properties'],
        Bigtop_file::Site['/etc/knox/conf/gateway-site.xml'],
      ],
      logoutput => true,
    }

    file { '/etc/knox/conf/topologies':
      ensure => directory,
      owner => knox,
      group => knox,
      mode => '0744',
      require => [Package["hadoop"]],
    }

    bigtop_file::xml { '/etc/knox/conf/topologies/knoxsso.xml':
      content => template('knox/topologies/knoxsso.xml'),
      overrides => $knoxsso_overrides,
      require => Package['knox'],
    }

    bigtop_file::xml { '/etc/knox/conf/topologies/default.xml':
      content => template('knox/topologies/default.xml'),
      overrides => $sandbox_overrides,
      require => Package['knox'],
    }
  }

  class server {
    include knox::common

    service { 'knox-server':
      ensure     => running,
      require    => [
        Package['knox']
      ],
      hasrestart => false,
      hasstatus  => true,
      subscribe => [
        Bigtop_file::Site['/etc/knox/conf/gateway-site.xml'],
        Exec['copy s3 identity provider metadata file to local'],
        Exec['create knox master'],
      ]
    }
  }
}
