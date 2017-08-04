class mysql_connector {
  class library {
    class jar {
        package { 'mysql-connector-java':
         ensure => latest,
       }
    }
  }
}