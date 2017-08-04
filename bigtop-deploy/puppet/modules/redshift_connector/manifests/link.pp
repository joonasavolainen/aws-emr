define redshift_connector::link {
  include redshift_connector::library::jar

  file { $name:
    ensure => link,
    target => '/usr/share/aws/redshift/jdbc/RedshiftJDBC.jar',
  }
}