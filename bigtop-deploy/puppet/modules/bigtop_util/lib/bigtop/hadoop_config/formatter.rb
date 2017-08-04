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

require 'rexml/text'

module Bigtop
  module HadoopConfig
    class Formatter
      def initialize(options = {})
        defaults = { indent: 2, compact: false, newlines: 1 }
        options = defaults.merge(options)

        @indent = options[:indent]
        @compact = options[:compact]
        @newlines = options[:newlines]
      end

      def insert_seperators(element)
        depth = height(element)
        fail ArgumentError, 'Given element has no parent' unless depth >= 0

        element.parent.insert_before(element, new_seperator(depth, @newlines))
        element.add_text(new_seperator(depth, 1)) unless @compact
      end

      private

      def new_seperator(depth, newlines)
        whitespace = "\n" * newlines + ' ' * @indent * depth
        REXML::Text.new(whitespace, true)
      end

      def height(element)
        count = -1
        each_ancestor(element) { |_ancestor| count += 1 }
        count
      end

      def each_ancestor(element, &block)
        ancestor = element.parent
        until ancestor.nil?
          block.call(ancestor)
          ancestor = ancestor.parent
        end
      end
    end
  end
end
