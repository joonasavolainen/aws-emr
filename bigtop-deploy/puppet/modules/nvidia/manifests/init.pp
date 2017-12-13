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

class nvidia {

  class deploy($roles)
  {
    $instance_family = split($ec2_instance_type,'[.]')[0]

    if ($instance_family in ['p2','p3'])
    {
      include nvidia::common
    }
  }

  class common
  {

    package { "kernel-devel-$kernelrelease" :
      ensure => 'installed',
    }

    package { "nvidia-cuda" :
      ensure  => 'installed',
      require => Package["kernel-devel-$kernelrelease"],
    }
  }
}
