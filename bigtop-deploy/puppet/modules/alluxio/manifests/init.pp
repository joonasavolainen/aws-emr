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
class alluxio {

  class deploy ($roles) {
    if ("alluxio-master" in $roles) {
      include alluxio::master
    }

    if ("alluxio-worker" in $roles) {
      include alluxio::worker
    }
  }

  class common (
    $alluxio_env_overrides = {},
    $alluxio_log4j_overrides = {},
    $alluxio_site_overrides = {},
    $master_host = $fqdn,
    $user_log_dir = undef,
    $underfs_address = undef,
  ) {

    package { "alluxio":
      ensure => latest,
    }
    
    $sticky_dir = delete_undef_values([$user_log_dir])

    file { $sticky_dir :
      ensure => "directory",
      owner  => "root",
      group  => "root",
      mode   => 1777,
      require => Package['alluxio']
    }
    
    # add alluxio-env.sh to point to alluxio master
    bigtop_file::env { '/etc/alluxio/conf/alluxio-env.sh':
      content => template('alluxio/alluxio-env.sh'),
      overrides => $alluxio_env_overrides,
      require => [Package['alluxio']],     
    }

    # add logging into /var/log/..
    bigtop_file::properties { '/etc/alluxio/conf/log4j.properties':
      content => template('alluxio/log4j.properties'),
      overrides => $alluxio_log4j_overrides,
      require => [Package['alluxio']],     
    }

    bigtop_file::properties { '/etc/alluxio/conf/alluxio-site.properties':
      content => template('alluxio/alluxio-site.properties'),
      overrides => $alluxio_site_overrides,
      require => [Package['alluxio']],
    }

  }

  class master {
    include common

    package { "alluxio-master":
      ensure => latest,
    }

    exec { "alluxio format":
      command => "/usr/lib/alluxio/bin/alluxio format",
      unless => "/usr/bin/test -f /var/run/alluxio/.format",
      before  => File['/var/run/alluxio/.format'],
      subscribe => [ Package["alluxio"], 
          Bigtop_file::Properties['/etc/alluxio/conf/log4j.properties'], 
          Bigtop_file::Env['/etc/alluxio/conf/alluxio-env.sh'] ]
    }

    if ( $fqdn == $alluxio::common::master_host ) {
      service { "alluxio-master":
        ensure => running,
        subscribe => [ Package["alluxio-master"], Exec["alluxio format"] ],
        hasrestart => true,
        hasstatus => true,
      }
    }

    file {'/var/run/alluxio/.format':
      ensure => present,
      owner => "alluxio",
      group => "alluxio",
      mode => "0644",
    }
  }

  class worker {
    include common

    package { "alluxio-worker": 
      ensure => latest,
    }

    exec { "alluxio mount":
      command => "/usr/lib/alluxio/bin/alluxio-mount.sh Mount local",
      unless => "/usr/bin/test -f /var/run/alluxio/.mount",
      before => File['/var/run/alluxio/.mount'],
      subscribe => [ Package["alluxio"], 
          Bigtop_file::Properties['/etc/alluxio/conf/log4j.properties'],
          Bigtop_file::Env['/etc/alluxio/conf/alluxio-env.sh'] ],       
      logoutput => true,
    }

    file {'/var/run/alluxio/.mount':
      ensure => present,
      owner => "alluxio",
      group => "alluxio",
      mode => "0644",
    }

    service { "alluxio-worker":
      ensure => running,
      subscribe => [ Package["alluxio-worker"], 
          Bigtop_file::Properties["/etc/alluxio/conf/log4j.properties"], 
          Bigtop_file::Env["/etc/alluxio/conf/alluxio-env.sh"], 
          Exec["alluxio mount"] ],
      hasrestart => true,
      hasstatus => true,
    }
  }
}
