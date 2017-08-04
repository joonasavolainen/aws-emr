define mysql_connector::link {
  include mysql_connector::library::jar

  file { $name:
    ensure => link,
    target => '/usr/share/java/mysql-connector-java.jar',
    require => Package['mysql-connector-java'],
  }
}