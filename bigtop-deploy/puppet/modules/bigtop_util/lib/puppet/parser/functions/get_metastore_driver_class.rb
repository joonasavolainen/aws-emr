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

# Gets the JDBC driver class name corresponding to the given metastore type.

require_relative '../../../preconditions.rb'

Puppet::Parser::Functions.newfunction(:get_metastore_driver_class, :type => :rvalue) do |args|
  Preconditions.checkCondition(args.size == 1, "Expected exactly 1 arg but got #{args.size}")
  Preconditions.checkAllArgsAreStringsOrNil(args)

  type = args[0]

  case type
    when 'derby'
      'org.apache.derby.jdbc.EmbeddedDriver'
    when 'mysql'
      'com.mysql.jdbc.Driver'
    when 'mariadb'
      'org.mariadb.jdbc.Driver'
    else
      fail Puppet::ParseError, "Invalid metastore type '#{type}'"
  end
end
