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

class nginx {

  class deploy ($roles) {
    if ('nginx' in $roles) {
      include nginx::server
    }
  }

  class common (
    $proxy_url = undef,
  ) {

    package { 'nginx':
      ensure => latest,
    }

    user { 'nginx':
      ensure => 'present',
    }

    group { 'nginx':
      ensure => 'present',
    }

    file { '/etc/nginx/nginx.conf':
      content => template('nginx/nginx.conf'),
      require => Package['nginx'],
    }

    file { '/etc/nginx/create_self_signed_cert_nginx.sh':
      content => template('nginx/create_self_signed_cert_nginx.sh'),
      owner => 'nginx',
      group => 'nginx',
      mode => 0755,
    }

    file { '/etc/nginx/self_signed_cert_nginx.conf':
      content => template('nginx/self_signed_cert_nginx.conf'),
      owner => 'nginx',
      group => 'nginx',
      mode => 0755,
    }

    exec { "create self signed certs":
      command => "/bin/bash -c '/etc/nginx/create_self_signed_cert_nginx.sh'",
      user    => 'root',
      require => [ Package["nginx"], File["/etc/nginx/nginx.conf"], File["/etc/nginx/create_self_signed_cert_nginx.sh"], File["/etc/nginx/self_signed_cert_nginx.conf"] ],
      logoutput => true,
    }

  }

  class server {
    include nginx::common

    service { 'nginx':
      ensure     => running,
      require    => [
        Package['nginx'],
        Exec["create self signed certs"]
      ],
      hasrestart => true,
      hasstatus  => true,
      subscribe => [
        File['/etc/nginx/nginx.conf']
      ]
    }
  }
}
