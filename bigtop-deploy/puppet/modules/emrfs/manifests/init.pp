class emrfs {

  class deploy ($roles) {
    if ("emrfs" in $roles) {
      include emrfs::library
    }
  }

  class library (
    $emrfs_site_overrides = {},
    $emrfs_annotations_overrides = {},
    $cse_provider_s3_path = undef
  ) {
    package { 'emrfs':
      ensure => present,
    }

    if ($cse_provider_s3_path != undef) {
      bigtop_file::s3 { 'cse-provider':
        ensure => present,
        source => $cse_provider_s3_path,
        destination => '/usr/share/aws/emr/emrfs/auxlib/',
        tag => 'emrfs-aux-jar',
      }
    }
    Package['emrfs'] -> Bigtop_file::S3 <| tag == 'emrfs-aux-jar' |>

    bigtop_file::site { '/usr/share/aws/emr/emrfs/conf/emrfs-site.xml':
      content => template('emrfs/emrfs-site.xml'),
      overrides => $emrfs_site_overrides,
      require => [Package["emrfs"]],
    }

    bigtop_file::properties { '/usr/share/aws/emr/emrfs/conf/emrfs-annotations.properties':
      content => template('emrfs/emrfs-annotations.properties'),
      overrides => $emrfs_annotations_overrides,
      require => [Package["emrfs"]],
    }

    Bigtop_file::S3 <| tag == 'emrfs-aux-jar' |> -> Bigtop_file::Site['/usr/share/aws/emr/emrfs/conf/emrfs-site.xml']
    Bigtop_file::S3 <| tag == 'emrfs-aux-jar' |> -> Bigtop_file::Properties['/usr/share/aws/emr/emrfs/conf/emrfs-annotations.properties']
  }
}
