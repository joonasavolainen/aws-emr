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

require 'rexml/element'
require 'rexml/text'

module Bigtop
  module HadoopConfig
    class Node
      def initialize(element, formatter)
        @element = element
        @formatter = formatter
      end

      protected

      def add_child(name)
        child = REXML::Element.new(name)

        last_child = last_nontext_child
        if last_child
          @element.insert_after(last_child, child)
        else
          @element[0, 0] = child
        end

        @formatter.insert_seperators(child) if @formatter
        child
      end

      def find_child(name)
        @element.elements[".//#{name}"]
      end

      def last_nontext_child
        reverse_each do |child|
          return child unless child.is_a? REXML::Text
        end
        nil
      end

      def reverse_each
        @element.size.downto(1) do |index|
          yield @element[index - 1]
        end
      end
    end
  end
end
