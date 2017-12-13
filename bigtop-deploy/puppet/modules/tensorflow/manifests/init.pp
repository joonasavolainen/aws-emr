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
      if ($ec2_instance_type =~ /^p2/ or $ec2_instance_type =~ /^p3/) {
        include tensorflow::gpu_library
      } else {
        include tensorflow::cpu_library
      }
    }
  }

  class common {
    if ! defined(Package["python27-numpy"]) {
      package { "python27-numpy":
        ensure   => latest
      }
    }
    if ! defined(Package["python34-numpy"]) {
      package { "python34-numpy":
        ensure   => latest
      }
    }

    package { "python27-six":
      ensure   => latest
    }
    package { "python34-six":
      ensure   => latest
    }

    package { "python27-enum34":
      ensure   => latest
    }
    package { "python34-enum34":
      ensure   => latest
    }

    package { "python27-protobuf":
      ensure   => latest,
      require  => [
        Package["python27-six"]
      ]
    }

    package { "python34-protobuf":
      ensure   => latest,
      require  => [
        Package["python34-six"]
      ]
    }

    package { "python27-backports.weakref":
      ensure   => latest
    }
    package { "python34-backports.weakref":
      ensure   => latest
    }

    package { "python27-werkzeug":
      ensure   => latest
    }
    package { "python34-werkzeug":
      ensure   => latest
    }

   package { "python27-futures":
      ensure   => latest
    }
    package { "python34-futures":
      ensure   => latest
    }

   package { "python27-tensorflow-tensorboard":
      ensure   => latest
   }
   
   package { "python34-tensorflow-tensorboard":
      ensure   => latest
   }

   package { "python27-html5lib":
      ensure   => latest
   }
   
   package { "python34-html5lib":
      ensure   => latest
   }

   package { "python27-bleach":
      ensure   => latest
   }   

   package { "python34-bleach":
      ensure   => latest
   }

   package { "python27-funcsigs":
      ensure   => latest
    }
   
   package { "python34-funcsigs":
      ensure   => latest
   }

   # 1. Because of a conflict, we currently can only install markdown for Python3. 
   # 2. We only need to install mock and pbr for Python 2.7. See:
   #    https://tiny.amazon.com/1j570t2w1/githtenstensf722

   package { "python34-markdown":
      ensure   => latest
   }
    
   package { "python27-mock":
      ensure   => latest
   }

   package { "python27-pbr":
      ensure   => latest
   }
  }

  class cpu_library {
    include tensorflow::common
    
    package { "python27-tensorflow":
      ensure   => latest,
      require  => [
        Package["python27-numpy"],
        Package["python27-six"],
        Package["python27-enum34"],
        Package["python27-protobuf"],
        Package["python27-backports.weakref"],
        Package["python27-werkzeug"],
        Package["python27-futures"],
        Package["python27-tensorflow-tensorboard"],
        Package["python27-html5lib"],
        Package["python27-bleach"],
        Package["python34-markdown"],
        Package["python27-funcsigs"],
        Package["python27-mock"],
        Package["python27-pbr"]
      ]
    }

    package { "python34-tensorflow":
      ensure   => latest,
      require  => [
        Package["python34-numpy"],
        Package["python34-six"],
        Package["python34-enum34"],
        Package["python34-protobuf"],
        Package["python34-backports.weakref"],
        Package["python34-werkzeug"],
        Package["python34-futures"],
        Package["python34-tensorflow-tensorboard"],
        Package["python34-html5lib"],
        Package["python34-bleach"],
        Package["python34-markdown"],
        Package["python34-funcsigs"]
      ]
    }
  }

  class gpu_library {
    include tensorflow::common
    
    package { "python27-tensorflow-gpu":
      ensure   => latest,
      require  => [
        Package["python27-numpy"],
        Package["python27-six"],
        Package["python27-enum34"],
        Package["python27-protobuf"],
        Package["python27-backports.weakref"],
        Package["python27-werkzeug"],
        Package["python27-futures"],
        Package["python27-tensorflow-tensorboard"],
        Package["python27-html5lib"],
        Package["python27-bleach"],
        Package["python34-markdown"],
        Package["python27-funcsigs"],
        Package["python27-mock"], 
        Package["python27-pbr"]
      ]
    }

    package { "python34-tensorflow-gpu":
      ensure   => latest,
      require  => [
        Package["python34-numpy"],
        Package["python34-six"],
        Package["python34-enum34"],
        Package["python34-protobuf"],
        Package["python34-backports.weakref"],
        Package["python34-werkzeug"],
        Package["python34-futures"],
        Package["python34-tensorflow-tensorboard"],
        Package["python34-html5lib"],
        Package["python34-bleach"],
        Package["python34-markdown"],
        Package["python34-funcsigs"]
      ]
    }
  }
}