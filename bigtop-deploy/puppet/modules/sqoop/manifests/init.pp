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

class sqoop {
  class deploy ($roles) {
    if ('sqoop-client' in $roles) {
      include sqoop::client                
    } 
  }
  
  class client (
    $sqoop_oraoop_site_overrides = {},
    $sqoop_site_overrides = {},
    $sqoop_env_overrides ={},
  ) {
    
    package { 'sqoop':
      ensure => latest,
    }

    bigtop_file::env { '/etc/sqoop/conf/sqoop-env.sh':
      source => '/etc/sqoop/conf/sqoop-env-template.sh',
      overrides => $sqoop_env_overrides,
      require => Package['sqoop'], 
    }    
    
    bigtop_file::site { '/etc/sqoop/conf/sqoop-site.xml':
      source => '/etc/sqoop/conf/sqoop-site-template.xml',
      overrides => $sqoop_site_overrides,
      require => Package['sqoop'],     
    }     
    
    bigtop_file::site { '/etc/sqoop/conf/oraoop-site.xml':
      source => '/etc/sqoop/conf/oraoop-site-template.xml',
      overrides => $sqoop_oraoop_site_overrides,
      require => Package['sqoop'],     
    }

    mariadb_connector::link {'/usr/lib/sqoop/lib/mariadb-connector-java.jar':
      require => Package['sqoop'],
    }
    
    postgresql_connector::link {'/usr/lib/sqoop/lib/postgresql-jdbc.jar':
      require => Package['sqoop'],
    }

    redshift_connector::link {'/usr/lib/sqoop/lib/RedshiftJDBC.jdbc':
      require => Package['sqoop'],
    }
  }
}