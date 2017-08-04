define mariadb_connector::link {
  include mariadb_connector::library::jar

  file { $name:
    ensure => link,
    target => '/usr/share/java/mariadb-connector-java.jar',
    require => Package['mariadb-connector-java'],
  }
}