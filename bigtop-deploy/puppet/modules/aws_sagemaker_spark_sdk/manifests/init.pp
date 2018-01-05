class aws_sagemaker_spark_sdk {

  class deploy ($roles) {
    if ("aws-sagemaker-spark-sdk" in $roles) {
      include aws_sagemaker_spark_sdk::library
    }
  }

  class library {
    package { 'aws-sagemaker-spark-sdk':
      ensure => present,
    }

    package { 'python27-numpy':
      ensure => present,
    }

    package { 'python34-numpy':
      ensure => present,
    }

    package { 'python27-sagemaker_pyspark':
      ensure => present,
      require => Package['python27-numpy']
    }

    package { 'python34-sagemaker_pyspark':
      ensure => present,
      require => Package['python34-numpy']
    }
  }
}
