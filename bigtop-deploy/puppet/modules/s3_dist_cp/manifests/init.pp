class s3_dist_cp {

  class deploy ($roles) {
    if ('s3-dist-cp' in $roles) {
      include s3_dist_cp::tool
    }
  }

  class tool() {
    package { 's3-dist-cp':
      ensure => present,
    }
  }
}
