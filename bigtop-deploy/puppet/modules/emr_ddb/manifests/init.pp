class emr_ddb {

  class deploy ($roles) {
    if ("emr-ddb" in $roles) {
      include emr_ddb::library
    }
  }

  class library() {
    package { 'emr-ddb':
      ensure => present,
    }
  }
}
