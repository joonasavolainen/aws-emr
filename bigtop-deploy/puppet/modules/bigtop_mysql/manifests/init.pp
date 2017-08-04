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

class bigtop_mysql {

  class deploy ($roles) {

    if ("mysql-client" in $roles) {
      include bigtop_mysql::client
    }
    if ("mysql-server" in $roles) {
      include bigtop_mysql::server
    }
  }

  class client () {

    package { "mysql":
      ensure => latest
    }
  }

  class server (
    $users = {},
    $grants = {},
    $databases = {},
    $override_options = {},
  ) {

    file { '/var/log/mysql':
      ensure => directory,
      owner => 'mysql',
      group => 'mysql',
      mode => '0750',
      before => Class['::Mysql::Server']
    }

    class { '::mysql::server':
      override_options => $override_options,
      restart => true,
      # need to hardcode service_provider to "redhat" so that it uses
      # /etc/init.d/mysqld instead of upstart
      service_provider => "redhat",
    }
    contain ::mysql::server

    create_resources('mysql_user', $users)
    create_resources('mysql_grant', $grants)
    create_resources('mysql_database', $databases)

    Class['::Mysql::Server'] -> Mysql_user <| |> -> Mysql_grant <| |>
    Class['::Mysql::Server'] -> Mysql_database <| |>
  }
}
