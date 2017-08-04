class emr_goodies {

  class deploy ($roles) {
    if ("emr-goodies" in $roles) {
      include emr_goodies::library
    }
 }

  class library {
    package { 'emr-goodies':
      ensure => present,
    }
  }
}
