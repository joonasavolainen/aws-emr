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

class tensorflow {

  class deploy ($roles) {
    if ('tensorflow' in $roles) {

      # remove custom ec2_metadata_instance_type.rb facter on completion of https://sim.amazon.com/issues/EMR-Dp-4317
      $instance_family = split($ec2_metadata_instance_type,'[.]')[0]

      if ($instance_family == 'p2') {
        include tensorflow::gpu_library
      } elsif ($instance_family in ['p3','g3','g3s']) {
        include tensorflow::gpu_nccl_library
      } elsif ($instance_family in ['m5','c5']) {
        include tensorflow::cpu_mkl_library
      } else {
        include tensorflow::cpu_library
      }
    }
  }

  class common {

    # EMR-Dp-4205, TF expects SSL CA bundle to be at /etc/ssl/certs/ca-certificates.crt
    file { '/etc/ssl/certs/ca-certificates.crt':
      ensure => 'link',
      target => '/etc/ssl/certs/ca-bundle.crt'
    }

    if ! defined(Package["python27-numpy"]) {
      package { "python27-numpy":
        ensure   => latest
      }
    }
    if ! defined(Package["python36-numpy"]) {
      package { "python36-numpy":
        ensure   => latest
      }
    }

    package { "python27-six":
      ensure   => latest
    }
    package { "python36-six":
      ensure   => latest
    }

    package { "python27-enum34":
      ensure   => latest
    }

    package { "python27-protobuf":
      ensure   => latest,
      require  => [
        Package["python27-six"]
      ]
    }

    package { "python36-protobuf":
      ensure   => latest,
      require  => [
        Package["python36-six"]
      ]
    }

    package { "python27-backports.weakref":
      ensure   => latest
    }

    package { "python27-werkzeug":
      ensure   => latest
    }
    package { "python36-werkzeug":
      ensure   => latest
    }

   package { "python27-futures":
      ensure   => latest
    }
    package { "python36-futures":
      ensure   => latest
    }

   package { "python27-tensorboard":
      ensure   => latest
   }
   
   package { "python36-tensorboard":
      ensure   => latest
   }

   package { "python27-html5lib":
      ensure   => latest
   }
   
   package { "python36-html5lib":
      ensure   => latest
   }

   package { "python27-bleach":
      ensure   => latest
   }   

   package { "python36-bleach":
      ensure   => latest
   }

   package { "python27-funcsigs":
      ensure   => latest
    }
   
   package { "python36-funcsigs":
      ensure   => latest
   }

   # 1. Because of a conflict, we currently can only install markdown for Python3. 
   # 2. We only need to install mock and pbr for Python 2.7. See:
   #    https://tiny.amazon.com/1j570t2w1/githtenstensf722

   package { "python36-markdown":
      ensure   => latest
   }
    
   package { "python27-mock":
      ensure   => latest
   }

   package { "python27-pbr":
      ensure   => latest
   }

    package { "python27-absl-py":
      ensure   => latest
    }

    package { "python36-absl-py":
      ensure   => latest
    }

    package { "python27-astor":
      ensure   => latest
    }

    package { "python36-astor":
      ensure   => latest
    }

    package { "python27-gast":
      ensure   => latest
    }

    package { "python36-gast":
      ensure   => latest
    }

    package { "python27-grpcio":
      ensure   => latest
    }

    package { "python36-grpcio":
      ensure   => latest
    }

    package { "python27-termcolor":
      ensure   => latest
    }

    package { "python36-termcolor":
      ensure   => latest
    }

    package { "python27-keras_applications":
      ensure   => latest
    }

    package { "python36-keras_applications":
      ensure   => latest
    }

    package { "python27-keras_preprocessing":
      ensure   => latest
    }

    package { "python36-keras_preprocessing":
      ensure   => latest
    }
  }

  $python27_dependencies = [
    Package["python27-numpy"],
    Package["python27-six"],
    Package["python27-enum36"],
    Package["python27-protobuf"],
    Package["python27-backports.weakref"],
    Package["python27-werkzeug"],
    Package["python27-futures"],
    Package["python27-tensorboard"],
    Package["python27-html5lib"],
    Package["python27-bleach"],
    Package["python27-funcsigs"],
    Package["python27-mock"],
    Package["python27-pbr"],
    Package["python27-absl-py"],
    Package["python27-astor"],
    Package["python27-gast"],
    Package["python27-grpcio"],
    Package["python27-termcolor"],
    Package["python27-keras_applications"],
    Package["python27-keras_preprocessing"]
  ]

  $python36_dependencies = [
    Package["python36-numpy"],
    Package["python36-six"],
    Package["python36-protobuf"],
    Package["python36-werkzeug"],
    Package["python36-futures"],
    Package["python36-tensorboard"],
    Package["python36-html5lib"],
    Package["python36-bleach"],
    Package["python36-markdown"],
    Package["python36-funcsigs"],
    Package["python36-absl-py"],
    Package["python36-astor"],
    Package["python36-gast"],
    Package["python36-grpcio"],
    Package["python36-termcolor"],
    Package["python27-keras_applications"],
    Package["python27-keras_preprocessing"]
  ]

  class cpu_library {
    include tensorflow::common
    
    package { "python27-tensorflow":
      ensure   => latest,
      require  => $python27_dependencies
    }

    package { "python36-tensorflow":
      ensure   => latest,
      require  => $python36_dependencies
    }
  }

  class cpu_mkl_library {
    include tensorflow::common

    package { "python27-tensorflow-mkl":
      ensure   => latest,
      require  => $python27_dependencies
    }

    package { "python36-tensorflow-mkl":
      ensure   => latest,
      require  => $python36_dependencies
    }
  }

  class gpu_library {
    include tensorflow::common
    
    package { "python27-tensorflow-gpu":
      ensure   => latest,
      require  => $python27_dependencies
    }

    package { "python36-tensorflow-gpu":
      ensure   => latest,
      require  => $python36_dependencies
    }
  }

  class gpu_nccl_library {
    include tensorflow::common

    package { "python27-tensorflow-gpu-nccl":
      ensure   => latest,
      require  => $python27_dependencies
    }

    package { "python36-tensorflow-gpu-nccl":
      ensure   => latest,
      require  => $python36_dependencies
    }
  }
}
