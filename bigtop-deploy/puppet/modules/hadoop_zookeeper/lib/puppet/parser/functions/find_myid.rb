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

module Puppet::Parser::Functions
    # This function is provided to extract the Zookeeper $myid
    # variable from the provided Zookeeper ensemble
    newfunction(:find_myid, :type => :rvalue) do |args|
        myid = args[0]
        fqdn = args[1]
        ensemble = args[2]

        if myid.nil? or myid == 'undef'
           filtered_ensemble = ensemble.select do |member|
             fqdn == member[1].split(':')[0]
           end
           unless filtered_ensemble[0].any?
              puts "myid not set and did not find myid in ensemble, setting '0' as default myid"
              found_myid = 0
           else
              found_myid = filtered_ensemble[0][0]
           end
        else
          found_myid = myid
        end
        return found_myid
    end
end