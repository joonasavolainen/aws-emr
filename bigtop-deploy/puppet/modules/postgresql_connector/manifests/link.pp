define postgresql_connector::link {
  include postgresql_connector::library::jar

  file { $name:
    ensure => link,
    target => '/usr/share/java/postgresql-jdbc.jar',
    require => Package['postgresql-jdbc'],
  }
}