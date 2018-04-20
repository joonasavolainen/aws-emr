define emrfs::link($path) {
  include emrfs::library

  exec { $name:
    path => '/bin',
    command => "ln -sf /usr/share/aws/emr/emrfs/lib/* $path",
    require => Package['emrfs']
  }

  exec { "$name - aux-jars":
    path => '/bin',
    command => "ln -sf /usr/share/aws/emr/emrfs/auxlib/* $path",
    require => Package['emrfs']
  }
}