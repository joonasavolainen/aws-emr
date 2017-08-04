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

describe 'generate_metastore_url' do
  let(:scope) { PuppetlabsSpec::PuppetInternals.scope }
  subject { scope.function_generate_metastore_url([type, host, port, name]) }

  context 'derby test' do
    let(:type) { 'derby' }
    let(:host) { nil }
    let(:port) { nil }
    let(:name) { nil }

    it { is_expected.to eq 'jdbc:derby:;databaseName=/var/lib/hive/metastore/metastore_db;create=true' }
  end

  context 'mysql test' do
    let(:type) { 'mysql' }
    let(:host) { 'localhost' }
    let(:port) { '1234' }
    let(:name) { 'dbname' }

    it { is_expected.to eq 'jdbc:mysql://localhost:1234/dbname?createDatabaseIfNotExist=true' }
  end

  context 'mariadb test' do
    let(:type) { 'mariadb' }
    let(:host) { 'localhost' }
    let(:port) { '1234' }
    let(:name) { 'dbname' }

    it { is_expected.to eq 'jdbc:mysql://localhost:1234/dbname?createDatabaseIfNotExist=true' }
  end

  context 'unknown type test' do
    let(:type) { 'foo' }
    let(:host) { 'localhost' }
    let(:port) { '1234' }
    let(:name) { 'dbname' }

    it { expect{subject}.to raise_error(Puppet::ParseError, /Invalid metastore type 'foo'/) }
  end

  context 'missing host test' do
    let(:type) { 'mysql' }
    let(:host) { nil }
    let(:port) { '1234' }
    let(:name) { 'dbname' }

    it { expect{subject}.to raise_error(Puppet::ParseError, /host must not be empty/) }
  end

  context 'missing port test' do
    let(:type) { 'mysql' }
    let(:host) { 'localhost' }
    let(:port) { nil }
    let(:name) { 'dbname' }

    it { expect{subject}.to raise_error(Puppet::ParseError, /port must not be empty/) }
  end

  context 'missing name test' do
    let(:type) { 'mysql' }
    let(:host) { 'localhost' }
    let(:port) { '1234' }
    let(:name) { nil }

    it { expect{subject}.to raise_error(Puppet::ParseError, /name must not be empty/) }
  end
end
