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

# Functions for checking preconditions and arguments, etc.

module Preconditions
  def Preconditions.checkCondition(condition, error_msg)
    unless condition
      fail Puppet::ParseError, error_msg
    end
  end

  def Preconditions.checkAllArgsAreStringsOrNil(args)
    args.each_with_index do |arg, i|
      checkCondition((arg.nil? or arg.is_a? String), "Expected arg #{i} to be a String")
    end
  end

  def Preconditions.checkNonEmpty(arg_value, arg_name)
    checkCondition(!arg_value.to_s.empty?, "#{arg_name} must not be empty")
  end
end
