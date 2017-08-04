#!/bin/bash
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License. See accompanying LICENSE file.
#

# Set kms specific environment variables here.

# The HTTP port used by KMS
#
export KMS_HTTP_PORT=<%= @hadoop_kms_http_port %>

# The Admin port used by KMS
#
export KMS_ADMIN_PORT=<%= @hadoop_kms_admin_port %>
