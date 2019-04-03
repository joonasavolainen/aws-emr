Facter.add(:ec2_metadata_public_hostname) do
  setcode 'curl -s http://169.254.169.254/latest/meta-data/public-hostname'
end
