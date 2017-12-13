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
      if ($ec2_instance_type =~ /^p2/ or $ec2_instance_type =~ /^p3/) {
        include mxnet::gpu_cu90_library
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
    package { "python34-graphviz":
      ensure   => latest
    }
    if ! defined(Package["python34-numpy"]) {
      package { "python34-numpy":
        ensure   => latest
      }
    }
    package { "openblas":
      ensure   => latest
    }
  }

  class cpu_library {
    include mxnet::common
    package { "python27-mxnet":
      ensure   => latest,
      require  => [
        Package["python27-graphviz"],
        Package["python27-numpy"],
        Package["openblas"]
      ]
    }
    package { "python34-mxnet":
      ensure   => latest,
      require  => [
        Package["python34-graphviz"],
        Package["python34-numpy"],
        Package["openblas"]
      ]
    }
  }

  class gpu_cu90_library {
    include mxnet::common
    package { "python27-mxnet_cu90":
      ensure   => latest,
      require  => [
        Package["python27-graphviz"],
        Package["python27-numpy"],
        Package["openblas"]
      ]
    }
    package { "python34-mxnet_cu90":
      ensure   => latest,
      require  => [
        Package["python34-graphviz"],
        Package["python34-numpy"],
        Package["openblas"]
      ]
    }
  }
}