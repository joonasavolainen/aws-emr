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

class mxnet {

  class deploy ($roles) {
    if ('mxnet' in $roles) {

      # remove usage of custom ec2_metadata_instance_type.rb facter on completion of https://sim.amazon.com/issues/EMR-Dp-4317
      if ($ec2_metadata_instance_type =~ /^p2/ or 
          $ec2_metadata_instance_type =~ /^p3/ or 
          $ec2_metadata_instance_type =~ /^g3/) {
        include mxnet::gpu_cu92_library
      } else {
        include mxnet::cpu_library
      }
    }
  }

  class common {
    package { "python27-graphviz":
      ensure   => latest
    }
    if ! defined(Package["python27-numpy"]) {
      package { "python27-numpy":
        ensure   => latest
      }
    }
    package { "python36-graphviz":
      ensure   => latest
    }
    if ! defined(Package["python36-numpy"]) {
      package { "python36-numpy":
        ensure   => latest
      }
    }
    package { "openblas":
      ensure   => latest
    }
  }

  $python27_dependencies = [
    Package["python27-graphviz"],
    Package["python27-numpy"],
    Package["openblas"]
  ]

  $python36_dependencies = [
    Package["python36-graphviz"],
    Package["python36-numpy"],
    Package["openblas"]
  ]

  class cpu_library {
    include mxnet::common
    package { "python27-mxnet":
      ensure   => latest,
      require  => $python27_dependencies
    }
    package { "python36-mxnet":
      ensure   => latest,
      require  => $python36_dependencies
    }
  }

  class gpu_cu92_library {
    include mxnet::common
    package { "python27-mxnet_cu92":
      ensure   => latest,
      require  => $python27_dependencies
    }
    package { "python36-mxnet_cu92":
      ensure   => latest,
      require  => $python36_dependencies
    }
  }
}
