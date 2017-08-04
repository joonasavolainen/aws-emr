class postgresql_connector {
  class library {
    class jar {
        package { 'postgresql-jdbc':
         ensure => latest,
       }
    }
  }
}