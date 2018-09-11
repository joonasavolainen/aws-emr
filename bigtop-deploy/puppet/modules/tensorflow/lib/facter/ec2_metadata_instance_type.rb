Facter.add(:ec2_metadata_instance_type) do
  setcode 'curl http://169.254.169.254/latest/meta-data/instance-type'
end
