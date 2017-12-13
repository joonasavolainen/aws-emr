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

class tez {
  class deploy ($roles) {
    if ("tez-on-yarn" in $roles) {
      include tez::client
      include tez::web
    }
  }

  class client (
    $tez_site_overrides = {},
    $tez_tarball_path = undef
  ) {

    $tar_tez_jars = 'tar -C /usr/lib/tez -zcvf tez.tar.gz .'
    $hdfs_mv = 'hdfs dfs -moveFromLocal'
    $hdfs_ls = 'hdfs dfs -ls'

    package { 'tez':
      ensure => latest,
    }

    bigtop_file::site { '/etc/tez/conf/tez-site.xml':
      overrides => $tez_site_overrides,
      content   => template('tez/tez-site.xml'),
      require   => Package['tez']
    }

    include hadoop::init_hdfs

    exec { 'Tar Tez jars':
      path      => '/bin:/usr/bin/',
      command   => "$tar_tez_jars",
      unless    => 'ls | grep -q tez.tar.gz',
      require   => Package['tez'],
      logoutput => true
    }

    exec { 'Copy Tez tarball to HDFS':
      path => '/bin:/usr/bin/',
      command   => "$hdfs_mv tez.tar.gz $tez_tarball_path",
      unless    => "$hdfs_ls $tez_tarball_path",
      user      => 'hdfs',
      tries     => 540,
      try_sleep => 5,
      timeout   => 2700,
      require   => [
        Exec['init hdfs'],
        Package['tez'],
        Exec['Tar Tez jars']
      ],
      logoutput => true
    }
  }

  class web {

    include tomcat::deploy

    file { '/var/lib/tomcat8/webapps/tez-ui':
      ensure  => 'directory',
      require => [
        Package['tomcat8'],
        Package['tomcat8-webapps']
      ]
    }

    exec { 'Unzip Tez-UI War to webapps':
      path      => '/bin:/usr/bin/',
      command   => "unzip -u /usr/lib/tez/tez-ui-*.war -d /var/lib/tomcat8/webapps/tez-ui",
      require   => [
        Package['tez'],
        File['/var/lib/tomcat8/webapps/tez-ui']
      ],
      tag       => "tomcat-war",
      logoutput => true
    }
  }
}
