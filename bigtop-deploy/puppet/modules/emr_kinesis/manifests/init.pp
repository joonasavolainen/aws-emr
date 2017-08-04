class emr_kinesis {

  class deploy ($roles) {
    if ("emr-kinesis" in $roles) {
      include emr_kinesis::library
    }
  }

  class library {
    package { 'emr-kinesis':
      ensure => present,
    }
  }
}
