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

require 'spec_helper'

RSpec.shared_examples 'for merging' do
  context 'given empty overrides' do
    let(:overrides) { Hash[] }
    it { is_expected.to eq original_config }
  end
end

describe 'merge_hadoop_config' do
  let(:scope) { PuppetlabsSpec::PuppetInternals.scope }
  subject { scope.function_merge_hadoop_config([original_config, overrides]) }

  context 'with a simple config' do
    let(:original_config) { fixture('test-site.xml') }

    include_examples 'for merging'

    context 'given various overrides' do
      let(:overrides) do
        Hash[
          'a' => 'overridden_a',
          'c' => 'overridden_c',
          'd' => 'new_d',
          'e' => 'overridden_e',
          'f' => 'new_f',
          'g' => 'new_g'
        ]
      end
      it { is_expected.to eq fixture('merged-test-site.xml') }
    end
  end

  context 'with an empty config' do
    let(:original_config) { fixture('empty-site.xml') }

    include_examples 'for merging'

    context 'given various overrides' do
      let(:overrides) do
        Hash[
          'a' => 'new_a',
          'b' => 'new_b',
          'c' => 'new_c'
        ]
      end
      it { is_expected.to eq fixture('merged-empty-site.xml') }
    end
  end
end
