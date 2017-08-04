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

describe 'to_json' do
  let(:scope) { PuppetlabsSpec::PuppetInternals.scope }
  subject { scope.function_to_json([input]) }

  context 'with an empty hash' do
    let(:input) { Hash[] }
    it { is_expected.to eq '{}' }
  end

  context 'with a simple hash' do
    let(:input) do
      Hash[
        'a' => { 'test' => 3 },
        'b' => nil,
        'c' => [1, 2, 3]
      ]
    end
    it { is_expected.to eq '{"a":{"test":3},"b":null,"c":[1,2,3]}' }
  end
end
