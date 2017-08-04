class emr_scripts {
  define scripts() {
    package { 'emr-scripts':
      ensure => present,
    }
  }
}
