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

require_relative 'formatter.rb'
require_relative 'property.rb'

require 'rexml/document'

module Bigtop
  module HadoopConfig
    class Document < Node
      def initialize(content, formatters = {})
        defaults = {
          document: Formatter.new(indent: 2, newlines: 2),
          property: Formatter.new(indent: 2, compact: true)
        }
        @formatters = defaults.merge(formatters)
        super(REXML::Document.new(content).root, @formatters[:document])

        populate_properties
      end

      def [](name)
        property = @properties[name]
        property['value'] if property
      end

      def []=(name, value)
        property = @properties[name]
        property ||= add_property(name)
        property['value'] = value
      end

      def to_s
        @element.parent.to_s
      end

      private

      def populate_properties
        @properties = {}
        @element.elements.each('//property/name') do |name|
          property = create_property(name.parent)
          use_property(property)
        end
      end

      def create_property(element)
        Property.new(element, @formatters[:property])
      end

      def add_property(name)
        child = add_child('property')
        property = create_property(child)
        property['name'] = name
        use_property(property)
      end

      def use_property(property)
        @properties[property['name']] = property
      end
    end
  end
end
