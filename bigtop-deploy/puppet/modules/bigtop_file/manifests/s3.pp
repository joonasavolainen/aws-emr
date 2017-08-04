define bigtop_file::s3($source, $destination, $ensure) {
  include bigtop_file::library

  if !($ensure in ['present', 'latest']) {
    fail('ensure parameter must be present or latest')
  }

  $flag = $ensure ? {
    'present' => ' --ignore-existing',
    default => ''
  }
  $command = join(["s3get -s ", shellquote($source), " -d ", shellquote($destination), $flag])

  exec { "s3get:$title":
    command => $command,
    path => "/usr/lib/bigtop-utils:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin",
    logoutput => on_failure,
    require => Package["bigtop-utils"],
  }
}
