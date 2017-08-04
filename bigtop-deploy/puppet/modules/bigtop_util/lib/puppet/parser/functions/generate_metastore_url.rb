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

# Generates a Hive Metastore URL based upon metastore type, host, port and (database) name.
# Only the metastore type is required, as the other arguments might not apply depending on the type.

require_relative '../../../preconditions.rb'

Puppet::Parser::Functions.newfunction(:generate_metastore_url, :type => :rvalue) do |args|
  Preconditions.checkCondition(args.size == 4, "Expected exactly 4 args but got #{args.size}")
  Preconditions.checkAllArgsAreStringsOrNil(args)

  (type, host, port, name) = args

  case type
    when 'derby'
      'jdbc:derby:;databaseName=/var/lib/hive/metastore/metastore_db;create=true'
    when 'mysql', 'mariadb'
      Preconditions.checkNonEmpty(host, "host")
      Preconditions.checkNonEmpty(port, "port")
      Preconditions.checkNonEmpty(name, "name")
      "jdbc:mysql://#{host}:#{port}/#{name}?createDatabaseIfNotExist=true"
    else
      fail Puppet::ParseError, "Invalid metastore type '#{type}'"
  end
end
