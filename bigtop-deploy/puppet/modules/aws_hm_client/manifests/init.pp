class aws_hm_client {

  class deploy ($roles) {
    if ("aws-hm-client" in $roles) {
      include aws_hm_client::library
    }
  }

  class library {
    package { 'aws-hm-client':
      ensure => present,
    }
  }
}
