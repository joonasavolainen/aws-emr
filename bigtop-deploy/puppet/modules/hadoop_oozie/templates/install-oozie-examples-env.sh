#! /bin/bash

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

if [ -z "$RM_URI" ]; then
  export RM_URI=<%= @resource_manager_uri %>
fi

if [ -z "$FS_URI" ]; then
  export FS_URI=<%= @fs_uri %>
fi

if [ -z "$SPARK_MASTER_URL" ]; then
  export SPARK_MASTER_URL=<%= @spark_master_url %>
fi

if [ -z "$HIVE_SERVER2_URL" ]; then
  export HIVE_SERVER2_URL=<%= @hiveserver2_url %>
fi
