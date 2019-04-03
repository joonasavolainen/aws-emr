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

class ganglia (
  $grid_name = 'unspecified',
  $cluster_name = 'unspecified',
  $cluster_owner = 'unspecified',
  $cluster_latlong = 'unspecified',
  $cluster_url = 'unspecified',
  $host_location = 'unspecified',
  $aggregator_hosts = ["%{hiera('bigtop::hadoop_head_node')}"],
  $gmond_port = hiera('ganglia::gmond_port'),
  $gmetad_xml_port = hiera('ganglia::gmetad_xml_port'),
  $gmetad_interactive_port = hiera('ganglia::gmetad_interactive_port'),
) {

  class deploy ($roles) {

    if ('ganglia-monitor' in $roles) {
      include ganglia::monitor
    }
    if ('ganglia-metadata-collector' in $roles) {
      include ganglia::metadata_collector
      include ganglia::rrdcached
    }
    if ('ganglia-web' in $roles) {
      include ganglia::web
    }

  }

  class monitor (
    $cluster_name = $ganglia::cluster_name,
    $cluster_owner = $ganglia::cluster_owner,
    $cluster_latlong = $ganglia::cluster_latlong,
    $cluster_url = $ganglia::cluster_url,
    $host_location = $ganglia::host_location,
    $host_dmax = '86400',
    $host_tmax = '20',
    $cleanup_threshold = '300',
    $is_deaf = false,
    $override_hostname = undef,
    $send_metadata_interval = '60',
    $gmond_port = $ganglia::gmond_port,
    $aggregator_hosts = $ganglia::aggregator_hosts,
    $udp_recv_channel_buffer_size = undef,
  ) inherits ganglia {

    package { 'ganglia-gmond':
      ensure => latest,
    }

    file { '/etc/ganglia/gmond.conf':
      content => template('ganglia/gmond.conf'),
      require => Package['ganglia-gmond'],
    }

    service { 'gmond':
      ensure     => running,
      subscribe  => File['/etc/ganglia/gmond.conf'],
      require    => Package['ganglia-gmond'],
      enable     => true,
      hasrestart => true,
      hasstatus  => true,
    }

    file { '/etc/init/gmond.conf':
      content => template('ganglia/gmond-upstart.conf')
    } ~> Service['gmond']

  }

  class rrdcached {

    package { 'rrdtool':
      ensure => latest,
    }

    service { 'ganglia-rrdcached':
      ensure     => running,
      require    => Package['rrdtool'],
      enable     => true,
      hasstatus  => true,
    }
    Service['ganglia-rrdcached'] -> Service<| title == 'gmetad' |>

    file { '/etc/init/ganglia-rrdcached.conf':
      content => template('ganglia/rrdcached-upstart.conf')
    } ~> Service['ganglia-rrdcached']

  }

  class metadata_collector (
    $grid_name = $ganglia::grid_name,
    $gmond_port = $ganglia::gmond_port,
    $gmetad_xml_port = $ganglia::gmetad_xml_port,
    $gmetad_interactive_port = $ganglia::gmetad_interactive_port,
    $aggregator_hosts = $ganglia::aggregator_hosts,
    $use_old_default_rra = false,
  ) inherits ganglia {

    package { 'ganglia-gmetad':
      ensure => latest,
    }

    file { '/etc/ganglia/gmetad.conf':
      content => template('ganglia/gmetad.conf'),
      require => Package['ganglia-gmetad'],
    }

    service { 'gmetad':
      ensure     => running,
      subscribe  => File['/etc/ganglia/gmetad.conf'],
      require    => Package['ganglia-gmetad'],
      enable     => true,
      hasrestart => true,
      hasstatus  => true,
    }
    Service['gmetad'] -> Service<| title == 'gmond' |>

    file { '/etc/init/gmetad.conf':
      content => template('ganglia/gmetad-upstart.conf')
    } ~> Service['gmetad']

  }

  class web (
    $cluster_name = $ganglia::cluster_name,
    $gmetad_interactive_port = $ganglia::gmetad_interactive_port,
    $auth_system = undef,
    $default_optional_graph_size = undef,
  ) inherits ganglia {

    package { 'ganglia-web':
      ensure => latest,
    }

    file { "/var/lib/ganglia/conf/default.json":
      content => template('ganglia/default.json'),
      require => Package['ganglia-web'],
      owner   => 'apache',
      group   => 'apache',
    }

    file { '/etc/ganglia/conf.php':
      content => template('ganglia/conf.php'),
      require => Package['ganglia-web'],
    }

    file { '/etc/httpd/conf.d/ganglia.conf':
      content => template('ganglia/ganglia.conf'),
      require => Package['ganglia-web'],
    }

  }

}

