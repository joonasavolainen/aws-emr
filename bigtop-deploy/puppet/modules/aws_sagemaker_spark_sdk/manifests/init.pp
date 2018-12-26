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

    package { 'python36-numpy':
      ensure => present,
    }

    package { 'python27-sagemaker_pyspark':
      ensure => present,
      require => Package['python27-numpy']
    }

    package { 'python36-sagemaker_pyspark':
      ensure => present,
      require => Package['python36-numpy']
    }
  }
}
