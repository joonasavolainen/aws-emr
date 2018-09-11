class emr_s3_select {

  class deploy ($roles) {
    if ("emr-s3-select" in $roles) {
      include emr_s3_select::library
    }
  }

  class library() {
    package { 'emr-s3-select':
      ensure => present,
    }
  }
}