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

class spark_jobserver {

  class deploy ($roles) {
    if ("spark-jobserver" in $roles) {
      include hadoop::init_hdfs
      include spark_jobserver::server
      
      Class["Hadoop::Init_hdfs"] -> Class["Spark_Jobserver::Server"]
    }
  }

  class server($spark_master_url = "yarn", $server_port = 8090) {
    package { "spark-jobserver":
      ensure => latest,
    }

    file { "/etc/spark-jobserver/conf/server.conf":
      content => template("spark_jobserver/server.conf"),
      require => Package["spark-jobserver"],
    }

    service { "spark-jobserver":
      ensure => running,
      require => [ Package["spark-jobserver"], File["/etc/spark-jobserver/conf/server.conf"], ],
      subscribe => [ Package["spark-jobserver"], File["/etc/spark-jobserver/conf/server.conf"], ],
      hasrestart => true,
      hasstatus => true,
    }
  }
}
