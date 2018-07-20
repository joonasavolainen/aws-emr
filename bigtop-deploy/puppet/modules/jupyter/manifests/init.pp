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

class jupyter {

  class deploy ($roles) {
    if ("jupyter-notebook" in $roles) {
      include jupyter::notebook
    }

    if ("jupyterhub" in $roles) {
      include jupyter::hub
    }
  }

  class common (
    $jupyter_sparkmagic_overrides = undef,
    $notebook_config_overrides = undef,
    $master_host = undef,
    $livy_server_port = undef,
    $use_s3_persistence = false,
    $s3_persistence_bucket = undef
  ) {

    package { "docker":
      ensure => latest,
    }

    package { "emr-docker-apps":
      ensure => latest,
    }
     
    service { "docker":
      ensure => running,
      subscribe => [ Package["docker"]],
      hasrestart => true,
      hasstatus => true,
    }

    user {"jupyter":
      ensure => "present",
      shell => "/sbin/nologin",
      gid => "jupyter",
    }

    group {"jupyter":
      ensure => "present",
    }

    file { [ "/etc/jupyter", "/etc/jupyter/conf" ]:
      ensure => "directory",
      owner  => "jupyter",
      group  => "jupyter",
      mode   => "1777",
      require => [ Package['emr-docker-apps'], User['jupyter'], Group['jupyter'] ],
    }

    # Add Master host name to config.json
    bigtop_file::json { "/etc/jupyter/conf/config.json":
      content => template("jupyter/config.json"),
      overrides => $jupyter_sparkmagic_overrides,
      require => [ Service['docker'], File["/etc/jupyter", "/etc/jupyter/conf" ] ],     
    }
    
    bigtop_file::python { '/etc/jupyter/jupyter_notebook_config.py':
      content => template('jupyter/jupyter_notebook_config.py'),
      overrides => $notebook_config_overrides,
      require => [ Package['emr-docker-apps'], File["/etc/jupyter", "/etc/jupyter/conf" ] ]      
    } 
    
    exec { "Load image":
      path => "/usr/bin",
      command => "docker load -i /var/lib/aws/emr/emr-docker-apps/jupyter/jupyter-notebook.tar",
      logoutput => true, 
      require => Service['docker'],
    }
  }

  class hub (
    $jupyterhub_config_overrides = undef,
  ) {
    include jupyter::common
    
    bigtop_file::python { '/etc/jupyter/conf/jupyterhub_config.py':
      content => template('jupyter/jupyterhub_config.py'),
      overrides => $jupyterhub_config_overrides,
      require => [ Package['emr-docker-apps'], File["/etc/jupyter", "/etc/jupyter/conf" ] ],
    }

    # For all execs running docker, we run as sudo. 
    
    $command = "docker run --restart on-failure:5 -it -d  \
-p 9443:9443 -e GRANT_SUDO=yes --user root \
-v /etc/jupyter:/etc/jupyter -v /var/lib/jupyter/home:/home \
-v /var/log/jupyter:/var/log/jupyter --privileged --name jupyterhub \
emr/jupyter-notebook:5.4.0"

    exec { "Start JupyterHub":
      path => "/usr/bin",
      command => $command,
      logoutput => true,
      require => [ Bigtop_file::Python["/etc/jupyter/jupyter_notebook_config.py"], 
        Bigtop_file::Python["/etc/jupyter/conf/jupyterhub_config.py"], 
        Bigtop_file::Json["/etc/jupyter/conf/config.json"] ],
    }

    # We want to fail to provision if we cannot confirm Hub is running.
    
    $curl_command = "curl -k -s https://${hostname}:9443/hub/api"
    exec {"Check JupyterHub":
      path => "/usr/bin",
      command => $curl_command,
      tries => 5,
      try_sleep => 15,
      returns => 0,
      logoutput => true,
      require => Exec["Start JupyterHub"]
    }
  }

  class notebook {
    include jupyter::common
    
    $command = "docker run --restart unless-stopped -it -d  \
-p 9443:9443 -e GRANT_SUDO=yes --user root \
-v /etc/jupyter:/etc/jupyter -v /var/lib/jupyter/home:/home \
-v /var/log/jupyter:/var/log/jupyter --privileged --name jupyterhub \
emr/jupyter-notebook:5.4.0 jupyter-notebook"

    exec { "Start Jupyter Notebook":
      path => "/usr/bin",
      command => $command,
      logoutput => true,
      require => [ Exec["Load image"], 
        Bigtop_file::Python["/etc/jupyter/jupyter_notebook_config.py"], 
        Bigtop_file::Json["/etc/jupyter/conf/config.json"] ],
    }
  }
}