class mariadb_connector {
  class library {
    class jar {
        package { 'mariadb-connector-java':
         ensure => latest,
       }
    }
  }
}