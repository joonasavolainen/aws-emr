# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements. See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License. You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Merges a site.xml contents with configuration overrides

require_relative '../../../bigtop/hadoop_config/document.rb'

Puppet::Parser::Functions.newfunction(:merge_hadoop_config,
                                      :type => :rvalue) do |arguments|
  if arguments.size != 2
    fail Puppet::ParseError, "merge_hadoop_config(): Wrong number of " \
                             "arguments given #{arguments.size} for 2."
  end

  conf_content = arguments[0]
  overrides = arguments[1]

  unless conf_content.is_a? String
    fail Puppet::ParseError, 'merge_hadoop_config(): Requires first ' \
                             'argument to be a string.'
  end

  unless overrides.is_a? Hash
    fail Puppet::ParseError, 'merge_hadoop_config(): Requires second ' \
                             'argument to be a hash.'
  end

  doc = Bigtop::HadoopConfig::Document.new(conf_content)
  overrides.each do |name, value|
    doc[name] = value
  end
  return doc.to_s
end
