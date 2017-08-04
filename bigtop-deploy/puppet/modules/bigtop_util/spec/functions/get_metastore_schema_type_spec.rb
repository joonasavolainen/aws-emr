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

require 'rubygems'
require 'puppetlabs_spec_helper/module_spec_helper'

describe 'get_metastore_schema_type' do
  let(:scope) { PuppetlabsSpec::PuppetInternals.scope }
  subject { scope.function_get_metastore_schema_type([type]) }

  context 'derby test' do
    let(:type) { 'derby' }
    it { is_expected.to eq 'derby' }
  end

  context 'mysql test' do
    let(:type) { 'mysql' }
    it { is_expected.to eq 'mysql' }
  end

  context 'mariadb test' do
    let(:type) { 'mariadb' }
    it { is_expected.to eq 'mysql' }
  end

  context 'unknown type test' do
    let(:type) { 'foo' }
    it { expect{subject}.to raise_error(Puppet::ParseError, /Invalid metastore type 'foo'/) }
  end
end
