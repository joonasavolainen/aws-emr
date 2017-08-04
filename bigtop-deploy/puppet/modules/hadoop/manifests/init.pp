# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

class hadoop ($hadoop_security_authentication = "simple",
  $ha = "disabled",
  $hadoop_namenode_host = $fqdn,
  $hadoop_namenode_port = "8020",
  $nameservice_id = "ha-nn-uri",
  $kerberos_realm = undef,
  $zk = "",
  # Set from facter if available
  $hadoop_storage_dirs = split($::hadoop_storage_dirs, ";"),
  $key_provider_uri = undef,
  $hadoop_lzo_codec = undef,
  $use_emrfs = false,
  $use_dynamodb = false,
  $use_emr_goodies = false,
  $use_kinesis = false,
  $proxyusers = {
    oozie => { groups => 'hudson,testuser,root,hadoop,jenkins,oozie,hive,httpfs,hue,users', hosts => "*" },
     hive => { groups => 'hudson,testuser,root,hadoop,jenkins,oozie,hive,httpfs,hue,users', hosts => "*" },
      hue => { groups => 'hudson,testuser,root,hadoop,jenkins,oozie,hive,httpfs,hue,users', hosts => "*" },
   httpfs => { groups => 'hudson,testuser,root,hadoop,jenkins,oozie,hive,httpfs,hue,users', hosts => "*" } },
  $generate_secrets = false,
) {

  include stdlib

  class deploy ($roles) {

    if ("datanode" in $roles) {
      include hadoop::datanode
    }

    if ("namenode" in $roles) {
      include hadoop::init_hdfs
      include hadoop::namenode

      if ("datanode" in $roles) {
        Class['Hadoop::Namenode'] -> Class['Hadoop::Datanode'] -> Class['Hadoop::Init_hdfs']
      } else {
        Class['Hadoop::Namenode'] -> Class['Hadoop::Init_hdfs']
      }
    }

    if ("standby-namenode" in $roles) {
      include hadoop::standby_namenode
    }

    if ("mapred-app" in $roles) {
      include hadoop::mapred_app
    }

    if ("nodemanager" in $roles) {
      include hadoop::nodemanager
    }

    if ("resourcemanager" in $roles) {
      include hadoop::resourcemanager
      include hadoop::historyserver
      include hadoop::proxyserver

      if ("nodemanager" in $roles) {
        Class['Hadoop::Resourcemanager'] -> Class['Hadoop::Nodemanager']
      }
    }

    if ("timelineserver" in $roles) {
      include hadoop::timelineserver
    }

    if ("secondarynamenode" in $roles) {
      include hadoop::secondarynamenode
    }

    if ("hadoop-client" in $roles) {
      include hadoop::client
    }

    if ("hdfs-library" in $roles) {
      include hadoop::hdfs_library
    }

    if ("httpfs-server" in $roles) {
      include hadoop::httpfs
    }

    if ("kms-server" in $roles) {
      include hadoop::kms
    }

    if ("journalnode" in $roles) {
      include hadoop::journalnode
    }
  }

  class init_hdfs(
    $hdfs_root_user = 'hdfs',
    $key_provider_uri = $hadoop::key_provider_uri,
    $dirs = {},
    $users = {},
  ) inherits hadoop {

    include hadoop::common_hdfs

    exec { 'hdfs ready':
      path      => ['/bin','/sbin','/usr/bin','/usr/sbin'],
      command   => 'hdfs dfsadmin -safemode wait',
      tries     => 60,
      try_sleep => 1,
      require   => [Package['hadoop-hdfs'],
        Bigtop_file::Site['/etc/hadoop/conf/core-site.xml'],
        Bigtop_file::Site['/etc/hadoop/conf/hdfs-site.xml']],
      logoutput => true
    }

    file { '/var/lib/hadoop-hdfs/init-hcfs.json':
      content => template('hadoop/init-hcfs.json.tmpl'),
      require => [Package['hadoop']]
    }

    exec { 'init hdfs':
      path    => ['/bin','/sbin','/usr/bin','/usr/sbin'],
      command => 'bash -x /usr/lib/hadoop/libexec/init-hdfs.sh /var/lib/hadoop-hdfs/init-hcfs.json',
      require => [Package['hadoop-hdfs'], Exec['hdfs ready'],
        File['/var/lib/hadoop-hdfs/init-hcfs.json'],
        Bigtop_file::Site['/etc/hadoop/conf/core-site.xml'],
        Bigtop_file::Site['/etc/hadoop/conf/hdfs-site.xml']],
      logoutput => true
    }

    if ($key_provider_uri) {
      exec { 'key provider ready':
        path      => ['/bin','/sbin','/usr/bin','/usr/sbin'],
        command   => 'hadoop key list',
        tries     => 60,
        try_sleep => 1,
        require   => [Package['hadoop'], Bigtop_file::Site['/etc/hadoop/conf/core-site.xml']],
        logoutput => true
      }

      Service <| title == 'hadoop-kms' |> -> Exec['key provider ready'] -> Exec['init hdfs']
    } elsif (!empty($encryption_keys) or !empty($encryption_zones)) {
      fail('$key_provider_uri must be configured if $encryption_keys or $encryption_zones are configured')
    }
  }

  class common ($hadoop_java_home = undef,
      $hadoop_classpath = undef,
      $hadoop_heapsize = undef,
      $hadoop_opts = undef,
      $hadoop_namenode_opts = undef,
      $hadoop_secondarynamenode_opts = undef,
      $hadoop_datanode_opts = undef,
      $hadoop_balancer_opts = undef,
      $hadoop_jobtracker_opts = undef,
      $hadoop_tasktracker_opts = undef,
      $hadoop_client_opts = undef,
      $hadoop_ssh_opts = undef,
      $hadoop_log_dir = undef,
      $hadoop_slaves = undef,
      $hadoop_master = undef,
      $hadoop_slave_sleep = undef,
      $hadoop_pid_dir = undef,
      $hadoop_ident_string = undef,
      $hadoop_niceness = undef,
      $use_tez = false,
      $tez_conf_dir = undef,
      $tez_jars = undef,
      $hadoop_lzo_codec = $hadoop::hadoop_lzo_codec,
      $use_emrfs = $hadoop::use_emrfs,
      $use_dynamodb = $hadoop::use_dynamodb,
      $use_emr_goodies = $hadoop::use_emr_goodies,
      $use_kinesis = $hadoop::use_kinesis,
      $use_alluxio = false,
      $hadoop_env_overrides = {},
      $hadoop_log4j_overrides = {},
      $hadoop_metrics2_overrides = {},
  ) inherits hadoop {

    if ($hadoop_lzo_codec) {
      include hadoop::lzo_codec
      Package["hadoop-lzo"] -> Bigtop_file::Env["/etc/hadoop/conf/hadoop-env.sh"]
    }

    if ($use_emrfs) {
      include emrfs::library
      Package["emrfs"] -> Bigtop_file::Env["/etc/hadoop/conf/hadoop-env.sh"]

      Bigtop_file::Site <| title == "/usr/share/aws/emr/emrfs/conf/emrfs-site.xml" |> {
        tag => "hadoop-plugin",
      }
    }

    if ($use_dynamodb) {
      include emr_ddb::library
      Package["emr-ddb"] -> Bigtop_file::Env["/etc/hadoop/conf/hadoop-env.sh"]
    }

    if ($use_emr_goodies) {
      include emr_goodies::library
      Package["emr-goodies"] -> Bigtop_file::Env["/etc/hadoop/conf/hadoop-env.sh"]
    }

    if ($use_kinesis) {
      include emr_kinesis::library
      Package["emr-kinesis"] -> Bigtop_file::Env["/etc/hadoop/conf/hadoop-env.sh"]
    }

    bigtop_file::properties { '/etc/hadoop/conf/hadoop-metrics2.properties':
      overrides => $hadoop_metrics2_overrides,
      require   => Package['hadoop'],
    }

    package { 'cloudwatch-sink':
      ensure  => latest,
      require => Package['hadoop'],
      before  => Bigtop_file::Env['/etc/hadoop/conf/hadoop-env.sh'],
    }

    bigtop_file::env { "/etc/hadoop/conf/hadoop-env.sh":
      content => template('hadoop/hadoop-env.sh'),
      overrides => $hadoop_env_overrides,
      require => [Package["hadoop"]],
    }

    package { "hadoop":
      ensure => latest,
      require => Package["jdk"],
    }

    bigtop_file::properties { "/etc/hadoop/conf/log4j.properties":
      overrides => $hadoop_log4j_overrides,
      require => Package["hadoop"],
    }

    #FIXME: package { "hadoop-native":
    #  ensure => latest,
    #  require => [Package["hadoop"]],
    #}
  }

  class common_yarn (
      $yarn_data_dirs = suffix($hadoop::hadoop_storage_dirs, "/yarn"),
      $hadoop_ps_host,
      $hadoop_ps_port = "20888",
      $hadoop_rm_host,
      $hadoop_rm_port = "8032",
      $hadoop_rm_admin_port = "8033",
      $hadoop_rm_webapp_port = "8088",
      $hadoop_rm_bind_host = undef,
      $hadoop_rt_port = "8025",
      $hadoop_sc_port = "8030",
      $yarn_log_server_url = undef,
      $yarn_nodemanager_resource_memory_mb = undef,
      $yarn_scheduler_maximum_allocation_mb = undef,
      $yarn_scheduler_minimum_allocation_mb = undef,
      $yarn_resourcemanager_scheduler_class = undef,
      $yarn_resourcemanager_ha_enabled = undef,
      $yarn_resourcemanager_cluster_id = "ha-rm-uri",
      $yarn_resourcemanager_zk_address = $hadoop::zk,
      # work around https://issues.apache.org/jira/browse/YARN-2847 by default
      $container_executor_banned_users = "doesnotexist",
      $container_executor_min_user_id = "499",
      $hadoop_lzo_codec = $hadoop::hadoop_lzo_codec,
      $use_emrfs = $hadoop::use_emrfs,
      $use_dynamodb = $hadoop::use_dynamodb,
      $use_emr_goodies = $hadoop::use_emr_goodies,
      $use_kinesis = $hadoop::use_kinesis,
      $hadoop_security_authentication = $hadoop::hadoop_security_authentication,
      $kerberos_realm = $hadoop::kerberos_realm,
      $yarn_nodemanager_vmem_check_enabled = undef,
      $yarn_site_overrides = {},
      $yarn_env_overrides = {},
      $capacity_scheduler_overrides = {},
      $container_log4j_overrides = {},
      $use_mapreduce_shuffle = false,
      $use_spark_datanucleus = false,
      $use_spark_shuffle = false,
  ) inherits hadoop {

    include hadoop::common_core

    package { "hadoop-yarn":
      ensure => latest,
      require => [Package["jdk"], Package["hadoop"]],
    }

    if ($use_emrfs) {
      include emrfs::library
    }

    if ($use_dynamodb) {
      include emr_ddb::library
    }

    if ($use_emr_goodies) {
      include emr_goodies::library
    }

    if ($use_kinesis) {
      include emr_kinesis::library
      Package["emr-kinesis"] -> Bigtop_file::Site["/etc/hadoop/conf/yarn-site.xml"]
    }

    if ($use_mapreduce_shuffle) {
      include hadoop::common_mapred_app
      Package["hadoop-mapreduce"] -> Bigtop_file::Site["/etc/hadoop/conf/yarn-site.xml"]
    }

    if ($use_spark_datanucleus) {
      include spark::datanucleus
    }

    if ($use_spark_shuffle) {
      include spark::yarn_shuffle
      Package["spark-yarn-shuffle"] -> Bigtop_file::Env["/etc/hadoop/conf/yarn-env.sh"]
      Package["spark-yarn-shuffle"] -> Bigtop_file::Site["/etc/hadoop/conf/yarn-site.xml"]
    }

    if ($hadoop_security_authentication == "kerberos") {
      require kerberos::client
      kerberos::host_keytab { "yarn":
        tag    => "mapreduce",
        spnego => true,
        # we don't actually need this package as long as we don't put the
        # keytab in a directory managed by it. But it creates user mapred whom we
        # wan't to give the keytab to.
        require => Package["hadoop-yarn"],
      }
    }

    bigtop_file::site { "/etc/hadoop/conf/yarn-site.xml":
      content => template('hadoop/yarn-site.xml'),
      overrides => $yarn_site_overrides,
      require => [Package["hadoop-yarn"]],
    }

    bigtop_file::env { "/etc/hadoop/conf/yarn-env.sh":
      content => template('hadoop/yarn-env.sh'),
      overrides => $yarn_env_overrides,
      require => [Package["hadoop-yarn"]],
    }

    bigtop_file::site { "/etc/hadoop/conf/capacity-scheduler.xml":
      overrides => $capacity_scheduler_overrides,
      require => [Package["hadoop-yarn"]],
    }

    file { "/etc/hadoop/conf/container-executor.cfg":
      content => template('hadoop/container-executor.cfg'), 
      require => [Package["hadoop"]],
    }

    bigtop_file::properties { "/etc/hadoop/conf/container-log4j.properties":
      overrides => $container_log4j_overrides,
      require => [Package["hadoop-yarn"]],
    }
  }

  class common_core (
      $ha = $hadoop::ha,
      $hadoop_namenode_host = $hadoop::hadoop_namenode_host,
      $hadoop_namenode_port = $hadoop::hadoop_namenode_port,
      $nameservice_id = $nameservice_id,
      $zk = $hadoop::zk,
      $hadoop_core_proxyusers = $hadoop::proxyusers,
      $hadoop_config_fs_inmemory_size_mb = undef,
      $hadoop_security_group_mapping = undef,
      $hadoop_snappy_codec = undef,
      $hadoop_lzo_codec = $hadoop::hadoop_lzo_codec,
      $use_emrfs = $hadoop::use_emrfs,
      $hadoop_base_tmp_dir = undef,
      $s3_buffer_dirs = undef,
      $hadoop_security_authentication = $hadoop::hadoop_security_authentication,
      $key_provider_uri = $hadoop::key_provider_uri,
      $core_site_overrides = {},
      $hadoop_ssl_server_overrides = {},
      $hadoop_ssl_client_overrides = {},
  ) inherits hadoop {

    include hadoop::common

    $hadoop_shared_dirs = concat(
      $s3_buffer_dirs ? { undef => [], default => $s3_buffer_dirs },
      $hadoop_base_tmp_dir ? { undef => [], default => $hadoop_base_tmp_dir }
    )

    file { $hadoop_shared_dirs:
      ensure => directory,
      owner => hadoop,
      group => hadoop,
      mode => '1777',
      require => [Package["hadoop"]],
    }

    bigtop_file::site { "/etc/hadoop/conf/core-site.xml":
      content => template('hadoop/core-site.xml'),
      overrides => $core_site_overrides,
      require => [Package["hadoop"], File[$hadoop_shared_dirs]],
    }


    bigtop_file::site { '/etc/hadoop/conf/ssl-server.xml':
      content   => template('hadoop/ssl-server.xml'),
      overrides => $hadoop_ssl_server_overrides,
      require   => [Package['hadoop'], Bigtop_file::Site['/etc/hadoop/conf/core-site.xml']],
    }


    bigtop_file::site { '/etc/hadoop/conf/ssl-client.xml':
      content   => template('hadoop/ssl-client.xml'),
      overrides => $hadoop_ssl_client_overrides,
      require   => [Package['hadoop'], Bigtop_file::Site['/etc/hadoop/conf/core-site.xml']],
    }

  }

  class hdfs_library {
    package { "hadoop-hdfs":
      ensure => latest,
      require => [Package["jdk"], Package["hadoop"]],
    }
  }

  class common_hdfs (
      $ha = $hadoop::ha,
      $hadoop_config_dfs_block_size = undef,
      $hadoop_config_namenode_handler_count = undef,
      $hadoop_dfs_datanode_plugins = "",
      $hadoop_dfs_namenode_plugins = "",
      $hadoop_namenode_host = $hadoop::hadoop_namenode_host,
      $hadoop_namenode_port = $hadoop::hadoop_namenode_port,
      $hadoop_namenode_bind_host = undef,
      $hadoop_namenode_http_port = "50070",
      $hadoop_namenode_http_bind_host = undef,
      $hadoop_namenode_https_port = "50470",
      $hadoop_namenode_https_bind_host = undef,
      $hdfs_data_dirs = suffix($hadoop::hadoop_storage_dirs, "/hdfs"),
      $hdfs_shortcut_reader = undef,
      $hdfs_support_append = undef,
      $hdfs_replace_datanode_on_failure = undef,
      $hdfs_webhdfs_enabled = "true",
      $hdfs_replication = undef,
      $hdfs_datanode_fsdataset_volume_choosing_policy = undef,
      $hdfs_nfs_bridge = "disabled",
      $hdfs_nfs_bridge_user = undef,
      $hdfs_nfs_gw_host = undef,
      $hdfs_nfs_proxy_groups = undef,
      $namenode_data_dirs = suffix($hadoop::hadoop_storage_dirs, "/namenode"),
      $nameservice_id = $hadoop::nameservice_id,
      $journalnode_host = "0.0.0.0",
      $journalnode_port = "8485",
      $journalnode_http_port = "8480",
      $journalnode_https_port = "8481",
      $journalnode_edits_dir = "${hadoop::hadoop_storage_dirs[0]}/journalnode",
      $shared_edits_dir = "/hdfs_shared",
      $testonly_hdfs_sshkeys  = "no",
      $hadoop_ha_sshfence_user_home = "/var/lib/hadoop-hdfs",
      $sshfence_privkey = "hadoop/id_sshfence",
      $sshfence_pubkey = "hadoop/id_sshfence.pub",
      $sshfence_user = "hdfs",
      $zk = $hadoop::zk,
      $hadoop_security_authentication = $hadoop::hadoop_security_authentication,
      $kerberos_realm = $hadoop::kerberos_realm,
      $hadoop_http_authentication_type = undef,
      $hadoop_http_authentication_signature_secret = undef,
      $hadoop_http_authentication_signature_secret_file = "/etc/hadoop/conf/hadoop-http-authentication-signature-secret",
      $hadoop_http_authentication_cookie_domain = regsubst($fqdn, "^[^\\.]+\\.", ""),
      $generate_secrets = $hadoop::generate_secrets,
      $namenode_datanode_registration_ip_hostname_check = undef,
      $key_provider_uri = $hadoop::key_provider_uri,
      $hdfs_site_overrides = {},
  ) inherits hadoop {

    $sshfence_keydir  = "$hadoop_ha_sshfence_user_home/.ssh"
    $sshfence_keypath = "$sshfence_keydir/id_sshfence"

    include hadoop::common_core
    include hadoop::hdfs_library

  # Check if test mode is enforced, so we can install hdfs ssh-keys for passwordless
    if ($testonly_hdfs_sshkeys == "yes") {
      notify{"WARNING: provided hdfs ssh keys are for testing purposes only.\n
        They shouldn't be used in production cluster": }
      $ssh_user        = "hdfs"
      $ssh_user_home   = "/var/lib/hadoop-hdfs"
      $ssh_user_keydir = "$ssh_user_home/.ssh"
      $ssh_keypath     = "$ssh_user_keydir/id_hdfsuser"
      $ssh_privkey     = "hadoop/hdfs/id_hdfsuser"
      $ssh_pubkey      = "hadoop/hdfs/id_hdfsuser.pub"

      file { $ssh_user_keydir:
        ensure  => directory,
        owner   => 'hdfs',
        group   => 'hdfs',
        mode    => '0700',
        require => Package["hadoop-hdfs"],
      }

      file { $ssh_keypath:
        source  => "puppet:///modules/$ssh_privkey",
        owner   => 'hdfs',
        group   => 'hdfs',
        mode    => '0600',
        require => File[$ssh_user_keydir],
      }

      file { "$ssh_user_keydir/authorized_keys":
        source  => "puppet:///modules/$ssh_pubkey",
        owner   => 'hdfs',
        group   => 'hdfs',
        mode    => '0600',
        require => File[$ssh_user_keydir],
      }
    }
    if ($hadoop_security_authentication == "kerberos" and $ha != "disabled") {
      fail("High-availability secure clusters are not currently supported")
    }

    if ($hadoop_security_authentication == "kerberos") {
      require kerberos::client
      kerberos::host_keytab { "hdfs":
        princs => [ "hdfs", "host" ],
        spnego => true,
        # we don't actually need this package as long as we don't put the
        # keytab in a directory managed by it. But it creates user hdfs whom we
        # wan't to give the keytab to.
        require => Package["hadoop-hdfs"],
      }
    }

    bigtop_file::site { "/etc/hadoop/conf/hdfs-site.xml":
      content => template('hadoop/hdfs-site.xml'),
      overrides => $hdfs_site_overrides,
      require => [Package["hadoop"]],
    }

    if $hadoop_http_authentication_type == "kerberos" {
      if $generate_secrets {
        $http_auth_sig_secret = trocla("hadoop_http_authentication_signature_secret", "plain")
      } else {
        $http_auth_sig_secret = $hadoop_http_authentication_signature_secret
      }
      if $http_auth_sig_secret == undef {
        fail("Hadoop HTTP authentication signature secret must be set")
      }

      file { 'hadoop-http-auth-sig-secret':
        path => "${hadoop_http_authentication_signature_secret_file}",
        # it's a password file - do not filebucket
        backup => false,
        mode => "0440",
        owner => "root",
        # allows access by hdfs and yarn (and mapred - mhmm...)
        group => "hadoop",
        content => $http_auth_sig_secret,
        require => [Package["hadoop"]],
      }

      # all the services will need this
      File['hadoop-http-auth-sig-secret'] ~> Service<| title == "hadoop-hdfs-journalnode" |>
      File['hadoop-http-auth-sig-secret'] ~> Service<| title == "hadoop-hdfs-namenode" |>
      File['hadoop-http-auth-sig-secret'] ~> Service<| title == "hadoop-hdfs-datanode" |>
      File['hadoop-http-auth-sig-secret'] ~> Service<| title == "hadoop-yarn-resourcemanager" |>
      File['hadoop-http-auth-sig-secret'] ~> Service<| title == "hadoop-yarn-nodemanager" |>

      require kerberos::client
      kerberos::host_keytab { "HTTP":
        # we need only the HTTP SPNEGO keys
        princs => [],
        spnego => true,
        owner => "root",
        group => "hadoop",
        mode => "0440",
        # we don't actually need this package as long as we don't put the
        # keytab in a directory managed by it. But it creates group hadoop which
        # we wan't to give the keytab to.
        require => Package["hadoop"],
      }

      # all the services will need this as well
      Kerberos::Host_keytab["HTTP"] -> Service<| title == "hadoop-hdfs-journalnode" |>
      Kerberos::Host_keytab["HTTP"] -> Service<| title == "hadoop-hdfs-namenode" |>
      Kerberos::Host_keytab["HTTP"] -> Service<| title == "hadoop-hdfs-datanode" |>
      Kerberos::Host_keytab["HTTP"] -> Service<| title == "hadoop-yarn-resourcemanager" |>
      Kerberos::Host_keytab["HTTP"] -> Service<| title == "hadoop-yarn-nodemanager" |>
    }
  }

  class common_mapred_app (
      $mapreduce_cluster_acls_enabled = undef,
      $mapreduce_jobhistory_host = undef,
      $mapreduce_jobhistory_port = "10020",
      $mapreduce_jobhistory_webapp_port = "19888",
      $mapreduce_framework_name = "yarn",
      $mapred_data_dirs = suffix($hadoop::hadoop_storage_dirs, "/mapred"),
      $mapreduce_cluster_temp_dir = undef,
      $mapreduce_jobtracker_system_dir = undef,
      $mapreduce_jobtracker_staging_root_dir = undef,
      $yarn_app_mapreduce_am_staging_dir = undef,
      $yarn_app_mapreduce_am_jhs_backup_dir = undef,
      $mapreduce_task_io_sort_factor = 64,              # 10 default
      $mapreduce_task_io_sort_mb = 256,                 # 100 default
      $mapreduce_reduce_shuffle_parallelcopies = undef, # 5 is default
      # processorcount == facter fact
      $mapreduce_tasktracker_map_tasks_maximum = inline_template("<%= [1, @processorcount.to_i * 0.20].max.round %>"),
      $mapreduce_tasktracker_reduce_tasks_maximum = inline_template("<%= [1, @processorcount.to_i * 0.20].max.round %>"),
      $mapreduce_tasktracker_http_threads = 60,         # 40 default
      $mapreduce_output_fileoutputformat_compress_type = "BLOCK", # "RECORD" default
      $mapreduce_map_output_compress = undef,
      $mapreduce_job_reduce_slowstart_completedmaps = undef,
      $mapreduce_map_memory_mb = undef,
      $mapreduce_reduce_memory_mb = undef,
      $mapreduce_map_java_opts = "-Xmx1024m",
      $mapreduce_reduce_java_opts = "-Xmx1024m",
      $hadoop_lzo_codec = $hadoop::hadoop_lzo_codec,
      $use_emrfs = $hadoop::use_emrfs,
      $use_dynamodb = $hadoop::use_dynamodb,
      $use_emr_goodies = $hadoop::use_emr_goodies,
      $use_kinesis = $hadoop::use_kinesis,
      $use_alluxio = $hadoop::common::use_alluxio,
      $hadoop_security_authentication = $hadoop::hadoop_security_authentication,
      $kerberos_realm = $hadoop::kerberos_realm,
      $mapred_site_overrides = {},
      $mapred_env_overrides = {},
  ) inherits hadoop {
    include hadoop::common_hdfs

    package { "hadoop-mapreduce":
      ensure => latest,
      require => [Package["jdk"], Package["hadoop"]],
    }

    if ($use_emrfs) {
      include emrfs::library
    }

    if ($use_dynamodb) {
      include emr_ddb::library
    }

    if ($use_emr_goodies) {
      include emr_goodies::library
    }

    if ($use_kinesis) {
      include emr_kinesis::library
      Package["emr-kinesis"] -> Bigtop_file::Site["/etc/hadoop/conf/mapred-site.xml"]
    }

    if ($use_alluxio) {
      include alluxio::common
      Package["alluxio"] -> Bigtop_file::Site["/etc/hadoop/conf/mapred-site.xml"]
    }

    if ($hadoop_security_authentication == "kerberos") {
      require kerberos::client

      kerberos::host_keytab { "mapred":
        tag    => "mapreduce",
        spnego => true,
        # we don't actually need this package as long as we don't put the
        # keytab in a directory managed by it. But it creates user yarn whom we
        # wan't to give the keytab to.
        require => Package["hadoop-mapreduce"],
      }
    }

    bigtop_file::site { "/etc/hadoop/conf/mapred-site.xml":
      content => template('hadoop/mapred-site.xml'),
      overrides => $mapred_site_overrides,
      require => [Package["hadoop-mapreduce"]],
    }

    bigtop_file::env { "/etc/hadoop/conf/mapred-env.sh":
      overrides => $mapred_env_overrides,
      require => [Package["hadoop-mapreduce"]],
    }

    file { "/etc/hadoop/conf/taskcontroller.cfg":
      content => template('hadoop/taskcontroller.cfg'), 
      require => [Package["hadoop"]],
    }
  }

  class datanode (
    $hadoop_security_authentication = $hadoop::hadoop_security_authentication,
  ) inherits hadoop {
    include hadoop::common_hdfs

    package { "hadoop-hdfs-datanode":
      ensure => latest,
      require => Package["jdk"],
    }

    file {
      "/etc/default/hadoop-hdfs-datanode":
        content => template('hadoop/hadoop-hdfs'),
        require => [Package["hadoop-hdfs-datanode"]],
    }

    service { "hadoop-hdfs-datanode":
      ensure => running,
      hasstatus => true,
      subscribe => [Package["hadoop-hdfs-datanode"], Bigtop_file::Site["/etc/hadoop/conf/core-site.xml"], Bigtop_file::Site["/etc/hadoop/conf/hdfs-site.xml"],
        Bigtop_file::Env["/etc/hadoop/conf/hadoop-env.sh"], Bigtop_file::Properties['/etc/hadoop/conf/hadoop-metrics2.properties'],],
      require => [ Package["hadoop-hdfs-datanode"], File["/etc/default/hadoop-hdfs-datanode"], File[$hadoop::common_hdfs::hdfs_data_dirs] ],
    }
    Kerberos::Host_keytab <| title == "hdfs" |> -> Service["hadoop-hdfs-datanode"]
    Service<| title == 'hadoop-hdfs-namenode' |> -> Service['hadoop-hdfs-datanode']
    Bigtop_file::Site<| tag == 'hadoop-plugin' |> ~> Service['hadoop-hdfs-datanode']

    hadoop::create_storage_dir { $hadoop::common_hdfs::hdfs_data_dirs: } ->
    file { $hadoop::common_hdfs::hdfs_data_dirs:
      ensure => directory,
      owner => hdfs,
      group => hdfs,
      mode => '755',
      require => [ Package["hadoop-hdfs"] ],
    }
  }

  class httpfs ($hadoop_httpfs_port = "14000",
      $secret = "hadoop httpfs secret",
      $generate_secrets = $hadoop::generate_secrets,
      $hadoop_core_proxyusers = $hadoop::proxyusers,
      $hadoop_security_authentcation = $hadoop::hadoop_security_authentication,
      $kerberos_realm = $hadoop::kerberos_realm,
      $httpfs_site_overrides = {},
      $httpfs_env_overrides = {},
  ) inherits hadoop {
    include hadoop::common_hdfs

    if ($hadoop_security_authentication == "kerberos") {
      kerberos::host_keytab { "httpfs":
        spnego => true,
        require => Package["hadoop-httpfs"],
      }
    }

    package { "hadoop-httpfs":
      ensure => latest,
      require => Package["jdk"],
    }

    bigtop_file::site { "/etc/hadoop-httpfs/conf/httpfs-site.xml":
      content => template('hadoop/httpfs-site.xml'),
      overrides => $httpfs_site_overrides,
      require => [Package["hadoop-httpfs"]],
    }

    bigtop_file::env { "/etc/hadoop-httpfs/conf/httpfs-env.sh":
      content => template('hadoop/httpfs-env.sh'),
      overrides => $httpfs_env_overrides,
      require => [Package["hadoop-httpfs"]],
    }

    if $generate_secrets {
      $httpfs_signature_secret = trocla("httpfs-signature-secret", "plain")
    } else {
      $httpfs_signature_secret = $secret
    }
    if $httpfs_signature_secret == undef {
      fail("HTTPFS signature secret must be set")
    }

    file { "/etc/hadoop-httpfs/conf/httpfs-signature.secret":
      content => $httpfs_signature_secret,
      # it's a password file - do not filebucket
      backup => false,
      require => [Package["hadoop-httpfs"]],
    }

    service { "hadoop-httpfs":
      ensure => running,
      hasstatus => true,
      subscribe => [Package["hadoop-httpfs"], Bigtop_file::Site["/etc/hadoop-httpfs/conf/httpfs-site.xml"],
        Bigtop_file::Env["/etc/hadoop-httpfs/conf/httpfs-env.sh"], File["/etc/hadoop-httpfs/conf/httpfs-signature.secret"],
        Bigtop_file::Site["/etc/hadoop/conf/core-site.xml"], Bigtop_file::Site["/etc/hadoop/conf/hdfs-site.xml"],
        Bigtop_file::Properties['/etc/hadoop/conf/hadoop-metrics2.properties'],],
      require => [ Package["hadoop-httpfs"] ],
    }
    Kerberos::Host_keytab <| title == "httpfs" |> -> Service["hadoop-httpfs"]
    Bigtop_file::Site <| tag == "hadoop-plugin" |> ~> Service["hadoop-httpfs"]
  }

  class kms (
    $hadoop_kms_http_port = '16000',
    $hadoop_kms_admin_port = '16001',
    $keystore_password = 'hadoop kms secret',
    $generate_keystore_password = $hadoop::generate_secrets,
    $hadoop_security_authentication = $hadoop::hadoop_security_authentication,
    $kms_acls_overrides = {},
    $kms_env_overrides = {},
    $kms_log4j_overrides = {},
    $kms_site_overrides = {},
  ) inherits hadoop {

    include hadoop::common_core

    if ($hadoop_security_authentication == 'kerberos') {
      require kerberos::client
      kerberos::host_keytab { 'kms':
        spnego => true,
        require => Package['hadoop-kms'],
      }
    }

    package { 'hadoop-kms':
      ensure => latest,
      require => Package['jdk'],
    }

    bigtop_file::site { '/etc/hadoop-kms/conf/kms-acls.xml':
      overrides => $kms_acls_overrides,
      require => Package['hadoop-kms'],
    }

    bigtop_file::env { '/etc/hadoop-kms/conf/kms-env.sh':
      content => template('hadoop/kms-env.sh'),
      overrides => $kms_env_overrides,
      require => Package['hadoop-kms'],
    }

    bigtop_file::site { '/etc/hadoop-kms/conf/kms-site.xml':
      content => template('hadoop/kms-site.xml'),
      overrides => $kms_site_overrides,
      require => Package['hadoop-kms'],
    }

    bigtop_file::properties { '/etc/hadoop-kms/conf/kms-log4j.properties':
      overrides => $kms_log4j_overrides,
      require => Package['hadoop-kms'],
    }

    if $generate_keystore_password {
      $kms_keystore_password = trocla('kms-keystore-password', 'plain')
    } else {
      $kms_keystore_password = $keystore_password
    }
    if $kms_keystore_password == undef {
      fail('KMS keystore password must be set')
    }

    file { '/etc/hadoop-kms/conf/keystore.password':
      content => $kms_keystore_password,
    # it's a password file - do not filebucket
      backup => false,
      mode => '600',
      owner => 'kms',
      group => 'kms',
      require => [Package['hadoop-kms']],
    }

    service { 'hadoop-kms':
      ensure => running,
      hasstatus => true,
      subscribe => [Package['hadoop-kms'], Bigtop_file::Site['/etc/hadoop-kms/conf/kms-site.xml'],
        Bigtop_file::Env['/etc/hadoop-kms/conf/kms-env.sh'], File['/etc/hadoop-kms/conf/keystore.password'],
        Bigtop_file::Site['/etc/hadoop/conf/core-site.xml'],],
      require => [Package['hadoop-kms']],
    }
    Kerberos::Host_keytab <| title == 'kms' |> -> Service['hadoop-kms']
  }

  class kinit {
    include hadoop::common_hdfs

    exec { "HDFS kinit":
      command => "/usr/bin/kinit -kt /etc/hdfs.keytab hdfs/$fqdn && /usr/bin/kinit -R",
      user    => "hdfs",
      require => Kerberos::Host_keytab["hdfs"],
    }
  }

  class create_hdfs_dirs($hdfs_dirs_meta,
      $hadoop_security_authentcation = $hadoop::hadoop_security_authentication ) inherits hadoop {
    $user = $hdfs_dirs_meta[$title][user]
    $perm = $hdfs_dirs_meta[$title][perm]

    if ($hadoop_security_authentication == "kerberos") {
      require hadoop::kinit
      Exec["HDFS kinit"] -> Exec["HDFS init $title"]
    }

    exec { "HDFS init $title":
      user => "hdfs",
      command => "/bin/bash -c 'hadoop fs -mkdir $title ; hadoop fs -chmod $perm $title && hadoop fs -chown $user $title'",
      require => Service["hadoop-hdfs-namenode"],
    }
    Exec <| title == "activate nn1" |>  -> Exec["HDFS init $title"]
  }

  class rsync_hdfs($files,
      $hadoop_security_authentcation = $hadoop::hadoop_security_authentication ) inherits hadoop {
    $src = $files[$title]

    if ($hadoop_security_authentication == "kerberos") {
      require hadoop::kinit
      Exec["HDFS kinit"] -> Exec["HDFS init $title"]
    }

    exec { "HDFS rsync $title":
      user => "hdfs",
      command => "/bin/bash -c 'hadoop fs -mkdir -p $title ; hadoop fs -put -f $src $title'",
      require => Service["hadoop-hdfs-namenode"],
    }
    Exec <| title == "activate nn1" |>  -> Exec["HDFS rsync $title"]
  }

  class namenode ( $nfs_server = "", $nfs_path = "",
      $standby_bootstrap_retries = 10,
      # milliseconds
      $standby_bootstrap_retry_interval = 30000,
      $should_format_namenode = undef) {
    include hadoop::common_hdfs

    if ($hadoop::common_hdfs::ha != 'disabled') {
      file { $hadoop::common_hdfs::sshfence_keydir:
        ensure  => directory,
        owner   => 'hdfs',
        group   => 'hdfs',
        mode    => '0700',
        require => Package["hadoop-hdfs"],
      }

      file { $hadoop::common_hdfs::sshfence_keypath:
        source  => "puppet:///files/$hadoop::common_hdfs::sshfence_privkey",
        owner   => 'hdfs',
        group   => 'hdfs',
        mode    => '0600',
        before  => Service["hadoop-hdfs-namenode"],
        require => File[$hadoop::common_hdfs::sshfence_keydir],
      }

      file { "$hadoop::common_hdfs::sshfence_keydir/authorized_keys":
        source  => "puppet:///files/$hadoop::common_hdfs::sshfence_pubkey",
        owner   => 'hdfs',
        group   => 'hdfs',
        mode    => '0600',
        before  => Service["hadoop-hdfs-namenode"],
        require => File[$hadoop::common_hdfs::sshfence_keydir],
      }

      if (! ('qjournal://' in $hadoop::common_hdfs::shared_edits_dir)) {
        hadoop::create_storage_dir { $hadoop::common_hdfs::shared_edits_dir: } ->
        file { $hadoop::common_hdfs::shared_edits_dir:
          ensure => directory,
        }

        if ($nfs_server) {
          if (!$nfs_path) {
            fail("No nfs share specified for shared edits dir")
          }

          require nfs::client

          mount { $hadoop::common_hdfs::shared_edits_dir:
            ensure  => "mounted",
            atboot  => true,
            device  => "${nfs_server}:${nfs_path}",
            fstype  => "nfs",
            options => "tcp,soft,timeo=10,intr,rsize=32768,wsize=32768",
            require => File[$hadoop::common::hdfs::shared_edits_dir],
            before  => Service["hadoop-hdfs-namenode"],
          }
        }
      }
    }

    package { "hadoop-hdfs-namenode":
      ensure => latest,
      require => Package["jdk"],
    }

    service { "hadoop-hdfs-namenode":
      ensure => running,
      hasstatus => true,
      subscribe => [Package["hadoop-hdfs-namenode"], Bigtop_file::Site["/etc/hadoop/conf/core-site.xml"],
        Bigtop_file::Site["/etc/hadoop/conf/hdfs-site.xml"], Bigtop_file::Env["/etc/hadoop/conf/hadoop-env.sh"],
        Bigtop_file::Properties['/etc/hadoop/conf/hadoop-metrics2.properties'],],
      require => [Package["hadoop-hdfs-namenode"]],
    }
    Kerberos::Host_keytab <| title == "hdfs" |> -> Exec <| tag == "namenode-format" |> -> Service["hadoop-hdfs-namenode"]
    Bigtop_file::Site <| tag == "hadoop-plugin" |> ~> Service["hadoop-hdfs-namenode"]

    if ($hadoop::common_hdfs::ha == "auto") {
      package { "hadoop-hdfs-zkfc":
        ensure => latest,
        require => Package["jdk"],
      }

      service { "hadoop-hdfs-zkfc":
        ensure => running,
        hasstatus => true,
        subscribe => [Package["hadoop-hdfs-zkfc"], Bigtop_file::Site["/etc/hadoop/conf/core-site.xml"], Bigtop_file::Site["/etc/hadoop/conf/hdfs-site.xml"],
          Bigtop_file::Env["/etc/hadoop/conf/hadoop-env.sh"], Bigtop_file::Properties['/etc/hadoop/conf/hadoop-metrics2.properties'],],
        require => [Package["hadoop-hdfs-zkfc"]],
      }
      Service <| title == "hadoop-hdfs-zkfc" |> -> Service <| title == "hadoop-hdfs-namenode" |>
      Bigtop_file::Site <| tag == "hadoop-plugin" |> ~> Service["hadoop-hdfs-zkfc"]
    }

    $namenode_array = any2array($hadoop::common_hdfs::hadoop_namenode_host)
    $first_namenode = $namenode_array[0]

    $is_first_namenode = $::fqdn == $first_namenode
    $format_namenode = $should_format_namenode ? {
      undef => $is_first_namenode,
      default => $should_format_namenode
    }
    if ($format_namenode) {
      exec { "namenode format":
        user => "hdfs",
        command => "/bin/bash -c 'hdfs namenode -format -nonInteractive >> /var/lib/hadoop-hdfs/nn.format.log 2>&1'",
        returns => [ 0, 1],
        creates => "${hadoop::common_hdfs::namenode_data_dirs[0]}/current/VERSION",
        require => [ Package["hadoop-hdfs-namenode"], File[$hadoop::common_hdfs::namenode_data_dirs],
          Bigtop_file::Site["/etc/hadoop/conf/hdfs-site.xml"], Bigtop_file::Env["/etc/hadoop/conf/hadoop-env.sh"] ],
        tag     => "namenode-format",
      }

      if ($hadoop::common_hdfs::ha != "disabled") {
        if ($hadoop::common_hdfs::ha == "auto") {
          exec { "namenode zk format":
            user => "hdfs",
            command => "/bin/bash -c 'hdfs zkfc -formatZK -nonInteractive >> /var/lib/hadoop-hdfs/zk.format.log 2>&1'",
            returns => [ 0, 2],
            require => [ Package["hadoop-hdfs-zkfc"], Bigtop_file::Site["/etc/hadoop/conf/hdfs-site.xml"],
             Bigtop_file::Env["/etc/hadoop/conf/hadoop-env.sh"] ],
            tag     => "namenode-format",
          }
          Service <| title == "zookeeper-server" |> -> Exec <| title == "namenode zk format" |>
          Exec <| title == "namenode zk format" |>  -> Service <| title == "hadoop-hdfs-zkfc" |>
        } else {
          exec { "activate nn1": 
            command => "/usr/bin/hdfs haadmin -transitionToActive nn1",
            user    => "hdfs",
            unless  => "/usr/bin/test $(/usr/bin/hdfs haadmin -getServiceState nn1) = active",
            require => Service["hadoop-hdfs-namenode"],
          }
        }
      }
    } elsif ($hadoop::common_hdfs::ha == "auto") {
      $retry_params = "-Dipc.client.connect.max.retries=$standby_bootstrap_retries \
        -Dipc.client.connect.retry.interval=$standby_bootstrap_retry_interval"

      exec { "namenode bootstrap standby":
        user => "hdfs",
        # first namenode might be rebooting just now so try for some time
        command => "/bin/bash -c 'hdfs namenode -bootstrapStandby $retry_params >> /var/lib/hadoop-hdfs/nn.bootstrap-standby.log 2>&1'",
        creates => "${hadoop::common_hdfs::namenode_data_dirs[0]}/current/VERSION",
        require => [ Package["hadoop-hdfs-namenode"], File[$hadoop::common_hdfs::namenode_data_dirs],
          Bigtop_file::Site["/etc/hadoop/conf/hdfs-site.xml"], Bigtop_file::Env["/etc/hadoop/conf/hadoop-env.sh"] ],
        tag     => "namenode-format",
      }
    } elsif ($hadoop::common_hdfs::ha != "disabled") {
      hadoop::namedir_copy { $hadoop::common_hdfs::namenode_data_dirs:
        source       => $first_namenode,
        ssh_identity => $hadoop::common_hdfs::sshfence_keypath,
        require      => File[$hadoop::common_hdfs::sshfence_keypath],
      }
    }

    file {
      "/etc/default/hadoop-hdfs-namenode":
        content => template('hadoop/hadoop-hdfs'),
        require => [Package["hadoop-hdfs-namenode"]],
    }

    hadoop::create_storage_dir { $hadoop::common_hdfs::namenode_data_dirs: } ->
    file { $hadoop::common_hdfs::namenode_data_dirs:
      ensure => directory,
      owner => hdfs,
      group => hdfs,
      mode => '700',
      require => [Package["hadoop-hdfs"]], 
    }
  }

  define create_storage_dir {
    exec { "mkdir $name":
      command => "/bin/mkdir -p $name",
      creates => $name,
      user =>"root",
    }
  }

  define namedir_copy ($source, $ssh_identity) {
    exec { "copy namedir $title from first namenode":
      command => "/usr/bin/rsync -avz -e '/usr/bin/ssh -oStrictHostKeyChecking=no -i $ssh_identity' '${source}:$title/' '$title/'",
      user    => "hdfs",
      tag     => "namenode-format",
      creates => "$title/current/VERSION",
    }
  }

  class standby_namenode {
    include hadoop::namenode
  }
      
  class secondarynamenode {
    include hadoop::common_hdfs

    package { "hadoop-hdfs-secondarynamenode":
      ensure => latest,
      require => Package["jdk"],
    }

    file {
      "/etc/default/hadoop-hdfs-secondarynamenode":
        content => template('hadoop/hadoop-hdfs'),
        require => [Package["hadoop-hdfs-secondarynamenode"]],
    }

    service { "hadoop-hdfs-secondarynamenode":
      ensure => running,
      hasstatus => true,
      subscribe => [Package["hadoop-hdfs-secondarynamenode"], Bigtop_file::Site["/etc/hadoop/conf/core-site.xml"],
        Bigtop_file::Site["/etc/hadoop/conf/hdfs-site.xml"], Bigtop_file::Env["/etc/hadoop/conf/hadoop-env.sh"],
        Bigtop_file::Properties['/etc/hadoop/conf/hadoop-metrics2.properties'],],
      require => [Package["hadoop-hdfs-secondarynamenode"]],
    }
    Kerberos::Host_keytab <| title == "hdfs" |> -> Service["hadoop-hdfs-secondarynamenode"]
    Bigtop_file::Site <| tag == "hadoop-plugin" |> ~> Service["hadoop-hdfs-secondarynamenode"]
  }

  class journalnode {
    include hadoop::common_hdfs

    package { "hadoop-hdfs-journalnode":
      ensure => latest,
      require => Package["jdk"],
    }

    $journalnode_cluster_journal_dir = "${hadoop::common_hdfs::journalnode_edits_dir}/${hadoop::common_hdfs::nameservice_id}"

    service { "hadoop-hdfs-journalnode":
      ensure => running,
      hasstatus => true,
      subscribe => [Package["hadoop-hdfs-journalnode"], Bigtop_file::Env["/etc/hadoop/conf/hadoop-env.sh"],
        Bigtop_file::Site["/etc/hadoop/conf/hdfs-site.xml"], Bigtop_file::Site["/etc/hadoop/conf/core-site.xml"],
        Bigtop_file::Properties['/etc/hadoop/conf/hadoop-metrics2.properties'],],
      require => [ Package["hadoop-hdfs-journalnode"], File[$journalnode_cluster_journal_dir] ],
    }
    Bigtop_file::Site <| tag == "hadoop-plugin" |> ~> Service["hadoop-hdfs-journalnode"]

    hadoop::create_storage_dir { [$hadoop::common_hdfs::journalnode_edits_dir, $journalnode_cluster_journal_dir]: } ->
    file { [ "${hadoop::common_hdfs::journalnode_edits_dir}", "$journalnode_cluster_journal_dir" ]:
      ensure => directory,
      owner => 'hdfs',
      group => 'hdfs',
      mode => '755',
      require => [Package["hadoop-hdfs"]],
    }
  }


  class resourcemanager {
    include hadoop::common_yarn

    package { "hadoop-yarn-resourcemanager":
      ensure => latest,
      require => Package["jdk"],
    }

    service { "hadoop-yarn-resourcemanager":
      ensure => running,
      hasstatus => true,
      subscribe => [Package["hadoop-yarn-resourcemanager"], Bigtop_file::Env["/etc/hadoop/conf/hadoop-env.sh"],
        Bigtop_file::Env["/etc/hadoop/conf/yarn-env.sh"], Bigtop_file::Site["/etc/hadoop/conf/yarn-site.xml"],
        Bigtop_file::Site["/etc/hadoop/conf/core-site.xml"], Bigtop_file::Properties['/etc/hadoop/conf/hadoop-metrics2.properties'],],
      require => [ Package["hadoop-yarn-resourcemanager"] ],
    }
    Bigtop_file::Site <| tag == "hadoop-plugin" |> ~> Service["hadoop-yarn-resourcemanager"]

    exec { "yarn rmadmin -refreshQueues":
      subscribe => [Bigtop_file::Site["/etc/hadoop/conf/capacity-scheduler.xml"]],
      require => Service["hadoop-yarn-resourcemanager"],
      path => [ "/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin" ],
    }
    Kerberos::Host_keytab <| tag == "mapreduce" |> -> Service["hadoop-yarn-resourcemanager"]
  }

  class proxyserver {
    include hadoop::common_yarn

    package { "hadoop-yarn-proxyserver":
      ensure => latest,
      require => Package["jdk"],
    }

    service { "hadoop-yarn-proxyserver":
      ensure => running,
      hasstatus => true,
      subscribe => [Package["hadoop-yarn-proxyserver"], Bigtop_file::Env["/etc/hadoop/conf/hadoop-env.sh"],
        Bigtop_file::Env["/etc/hadoop/conf/yarn-env.sh"], Bigtop_file::Site["/etc/hadoop/conf/yarn-site.xml"],
        Bigtop_file::Site["/etc/hadoop/conf/core-site.xml"],Bigtop_file::Properties['/etc/hadoop/conf/hadoop-metrics2.properties'],],
      require => [ Package["hadoop-yarn-proxyserver"] ],
    }
    Kerberos::Host_keytab <| tag == "mapreduce" |> -> Service["hadoop-yarn-proxyserver"]
    Bigtop_file::Site <| tag == "hadoop-plugin" |> ~> Service["hadoop-yarn-proxyserver"]
  }

  class timelineserver {
    include hadoop::common_yarn

    package { "hadoop-yarn-timelineserver":
      ensure => latest,
      require => Package["jdk"],
    }

    service { "hadoop-yarn-timelineserver":
      ensure => running,
      hasstatus => true,
      subscribe => [Package["hadoop-yarn-timelineserver"], Bigtop_file::Env["/etc/hadoop/conf/hadoop-env.sh"],
        Bigtop_file::Env["/etc/hadoop/conf/yarn-env.sh"], Bigtop_file::Site["/etc/hadoop/conf/yarn-site.xml"],
        Bigtop_file::Site["/etc/hadoop/conf/core-site.xml"],Bigtop_file::Properties['/etc/hadoop/conf/hadoop-metrics2.properties'],],
      require => [ Package["hadoop-yarn-timelineserver"] ],
    }
    Kerberos::Host_keytab <| tag == "mapreduce" |> -> Service["hadoop-yarn-timelineserver"]
    Bigtop_file::Site <| tag == "hadoop-plugin" |> ~> Service["hadoop-yarn-timelineserver"]
  }

  class historyserver {
    include hadoop::common_mapred_app

    package { "hadoop-mapreduce-historyserver":
      ensure => latest,
      require => Package["jdk"],
    }

    service { "hadoop-mapreduce-historyserver":
      ensure => running,
      hasstatus => true,
      subscribe => [Package["hadoop-mapreduce-historyserver"], Bigtop_file::Env["/etc/hadoop/conf/hadoop-env.sh"],
        Bigtop_file::Env["/etc/hadoop/conf/yarn-env.sh"], Bigtop_file::Site["/etc/hadoop/conf/yarn-site.xml"],
        Bigtop_file::Site["/etc/hadoop/conf/core-site.xml"], Bigtop_file::Env["/etc/hadoop/conf/mapred-env.sh"],
        Bigtop_file::Site["/etc/hadoop/conf/mapred-site.xml"],Bigtop_file::Properties['/etc/hadoop/conf/hadoop-metrics2.properties'],],
      require => [Package["hadoop-mapreduce-historyserver"]],
    }
    Kerberos::Host_keytab <| tag == "mapreduce" |> -> Service["hadoop-mapreduce-historyserver"]
    Bigtop_file::Site <| tag == "hadoop-plugin" |> ~> Service["hadoop-mapreduce-historyserver"]
  }


  class nodemanager {
    include hadoop::common_mapred_app
    include hadoop::common_yarn

    package { "hadoop-yarn-nodemanager":
      ensure => latest,
      require => Package["jdk"],
    }

    service { "hadoop-yarn-nodemanager":
      ensure => running,
      hasstatus => true,
      subscribe => [Package["hadoop-yarn-nodemanager"], Bigtop_file::Env["/etc/hadoop/conf/hadoop-env.sh"],
        Bigtop_file::Site["/etc/hadoop/conf/yarn-site.xml"], Bigtop_file::Site["/etc/hadoop/conf/core-site.xml"],
        Bigtop_file::Env["/etc/hadoop/conf/yarn-env.sh"], Bigtop_file::Properties['/etc/hadoop/conf/hadoop-metrics2.properties'],],
      require => [ Package["hadoop-yarn-nodemanager"], File[$hadoop::common_yarn::yarn_data_dirs] ],
    }
    Kerberos::Host_keytab <| tag == "mapreduce" |> -> Service["hadoop-yarn-nodemanager"]
    Bigtop_file::Site <| tag == "hadoop-plugin" |> ~> Service["hadoop-yarn-nodemanager"]

    hadoop::create_storage_dir { $hadoop::common_yarn::yarn_data_dirs: } ->
    file { $hadoop::common_yarn::yarn_data_dirs:
      ensure => directory,
      owner => yarn,
      group => yarn,
      mode => '755',
      require => [Package["hadoop-yarn"]],
    }
  }

  class mapred_app {
    include hadoop::common_mapred_app

    hadoop::create_storage_dir { $hadoop::common_mapred_app::mapred_data_dirs: } ->
    file { $hadoop::common_mapred_app::mapred_data_dirs:
      ensure => directory,
      owner => yarn,
      group => yarn,
      mode => '755',
      require => [Package["hadoop-mapreduce"]],
    }

    if ($hadoop::common_mapred_app::yarn_app_mapreduce_am_jhs_backup_dir) {
      file { $hadoop::common_mapred_app::yarn_app_mapreduce_am_jhs_backup_dir:
        ensure => directory,
        owner => yarn,
        group => yarn,
        mode => '775',
        require => [Package["hadoop-mapreduce"]],
      }
    }
  }

  class client {
      include hadoop::common_mapred_app
      include hadoop::common_yarn

      $hadoop_client_packages = $operatingsystem ? {
        /(OracleLinux|CentOS|RedHat|Fedora)/  => [ "hadoop-client", "hadoop-libhdfs", "hadoop-debuginfo" ],
        /(SLES|OpenSuSE)/                     => [ "hadoop-client", "hadoop-libhdfs" ],
        /(Ubuntu|Debian)/                     => [ "hadoop-client", "libhdfs0-dev"   ],
        default                               => [ "hadoop-client" ],
      }

      package { $hadoop_client_packages:
        ensure => latest,
        require => [Package["jdk"], Package["hadoop"], Package["hadoop-hdfs"], Package["hadoop-mapreduce"]],  
      }
  }

  class lzo_codec {
    package { "hadoop-lzo":
      ensure => latest
    }
  }
}
