require 'securerandom'

Puppet::Parser::Functions.newfunction(:generate_node_id, :type => :rvalue) do |args|
  SecureRandom.uuid
end