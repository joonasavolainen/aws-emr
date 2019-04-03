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

$roles_map = {
  apex => {
    client => ["apex-client"],
  },
  hdfs-non-ha => {
    master => ["namenode"],
    worker => ["datanode"],
    standby => ["secondarynamenode"],
    library => ["hdfs-library"],
  },
  hdfs-ha => {
    master => ["namenode", "journalnode"],
    worker => ["datanode"],
    standby => ["standby-namenode"],
    library => ["hdfs-library"],
  },
  yarn => {
    master => ["resourcemanager"],
    worker => ["nodemanager"],
    client => ["hadoop-client"],
    # mapred is the default app which runs on yarn.
    library => ["mapred-app"],
  },
  mapred => {
    library => ["mapred-app"],
  },
  hbase => {
    master => ["hbase-master", "zookeeper-server"],
    gateway_server => ["hbase-thrift-server", "hbase-rest-server"],
    worker => ["hbase-server"],
    client => ["hbase-client"],
  },
  phoenix => {
    library => ["phoenix-library"],
    gateway_server => ["phoenix-query-server"],
  },
  ignite_hadoop => {
    worker => ["ignite-server"],
  },
  solrcloud => {
    worker => ["solr-server"],
  },
  spark => {
    master => ["spark-on-yarn"],
    gateway_server => ["spark-history-server", "spark-thriftserver"],
    client => ["spark-client"],
    worker => ["spark-yarn-slave"],
  },
  alluxio => {
    master => ["alluxio-master"],
    worker => ["alluxio-worker"],
  },
  presto => {
    master => ["presto-coordinator"],
    worker => ["presto-worker"],
  },
  flink => {
    master => ["flink-jobmanager"],
    worker => ["flink-taskmanager"],
  },
  flume => {
    worker => ["flume-agent"],
  },
  kerberos => {
    master => ["kerberos-server"],
  },
  oozie => {
    master => ["oozie-server"],
    client => ["oozie-client"],
  },
  hcat => {
    master => ["hcatalog-server"],
    gateway_server => ["webhcat-server"],
    client => ["hcatalog-client"],
  },
  sqoop => {
    client => ["sqoop-client"],
  },
  sqoop2 => {
    gateway_server => ["sqoop2-server"],
    client => ["sqoop2-client"],
  },
  httpfs => {
    gateway_server => ["httpfs-server"],
  },
  hue => {
    gateway_server => ["hue-server"],
  },
  livy => {
    master => ["livy-server"],
  },
  knox => {
    master => ["knox-server"],
  },
  mahout => {
    client => ["mahout-client"],
  },
  giraph => {
    client => ["giraph-client"],
  },
  crunch => {
    client => ["crunch-client"],
  },
  pig => {
    client => ["pig-client"],
  },
  hive => {
    master => ["hive-server2", "hive-metastore"],
    client => ["hive-client"],
    gateway_server => ["hive-server", "hive-metastore-server"],
  },
  spark-jobserver => {
    master => ["spark-jobserver"],
  },
  tez => {
    client => ["tez-client"],
  },
  zeppelin => {
    master => ["zeppelin-server"],
  },
  zeppelin-kerberos => {
    worker => ["zeppelin-user"],
  },
  zookeeper => {
    worker => ["zookeeper-server"],
    client => ["zookeeper-client"],
  },
  bigtop-mysql => {
    master => ["mysql-server"],
    client => ["mysql-client"],
  },
  bigtop-webserver => {
    gateway_server => ["webserver"],
  },
  emrfs => {
    library => ["emrfs"],
  },
  s3-dist-cp => {
    tool => ["s3-dist-cp"],
  },
  emr-ddb => {
    library => ["emr-ddb"],
  },
  emr-s3-select => {
    library => ["emr-s3-select"],
  },
  aws-hm-client => {
    library => ["aws-hm-client"],
  },
  aws-sagemaker-spark-sdk => {
    library => ["aws-sagemaker-spark-sdk"],
  },
  emr-goodies => {
    library => ["emr-goodies"],
  },
  emr-kinesis => {
    library => ["emr-kinesis"],
  },
  ycsb => {
    client => ["ycsb-client"],
  },
  ganglia => {
    gateway_server => ["ganglia-web", "ganglia-metadata-collector", "ganglia-monitor"],
    worker => ["ganglia-monitor"],
  },
  qfs => {
    master => ["qfs-metaserver"],
    worker => ["qfs-chunkserver"],
    client => ["qfs-client"],
  },
  gpdb => {
    master => ["gpdb-master"],
    worker => ["gpdb-segment"],
  },
  kafka => {
    master => ["kafka-server"],
  }
}

class hadoop_cluster_node (
  $hadoop_security_authentication = hiera("hadoop::hadoop_security_authentication", "simple"),
  $bigtop_real_users = [ 'jenkins', 'testuser', 'hudson' ],
  $cluster_components = ["all"]
  ) {

  user { $bigtop_real_users:
    ensure     => present,
    system     => false,
    managehome => true,
  }

  if ($hadoop_security_authentication == "kerberos") {
    kerberos::host_keytab { $bigtop_real_users: }
    User<||> -> Kerberos::Host_keytab<||>
    include kerberos::client
  }

  $hadoop_head_node = hiera("bigtop::hadoop_head_node")
  $standby_head_node_0 = hiera("bigtop::standby_head_node_0", "")
  $standby_head_node_1 = hiera("bigtop::standby_head_node_1", "")
  $hadoop_gateway_node = hiera("bigtop::hadoop_gateway_node", $hadoop_head_node) 

  emr_scripts::scripts{ 'emr_scripts scripts': }
}

class node_with_roles ($roles = hiera("bigtop::roles")) inherits hadoop_cluster_node {

  define deploy_module($roles) {
    class { "${name}::deploy":
      roles => $roles,
    }
  }

  $modules = [
    "alluxio",
    "apex",
    "aws_hm_client",
    "aws_sagemaker_spark_sdk",
    "bigtop_mysql",
    "bigtop_webserver",
    "crunch",
    "emr_ddb",
    "emr_goodies",
    "emr_kinesis",
    "emr_s3_select",
    "emrfs",
    "flink",
    "ganglia",
    "giraph",
    "gpdb",
    "hadoop",
    "hadoop_hbase",
    "ignite_hadoop",
    "hadoop_flume",
    "hadoop_hive",
    "hadoop_oozie",
    "hadoop_pig",
    "hadoop_zookeeper",
    "hcatalog",
    "hue",
    "jupyter",
    "kafka",
    "kerberos",
    "livy",
    "knox",
    "nginx",
    "nvidia",
    "mahout",
    "mxnet",
    "phoenix",
    "presto",
    "s3_dist_cp",
    "solr",
    "spark",
    "spark_jobserver",
    "sqoop",
    "sqoop2",
    "qfs",
    "tensorflow",
    "tez",
    "ycsb",
    "zeppelin",
  ]

  deploy_module { $modules:
    roles => $roles,
  }
}

class node_with_components inherits hadoop_cluster_node {

  # Ensure (even if a single value) that the type is an array.
  if (is_array($cluster_components)) {
    $components_array = $cluster_components
  } else {
    if ($cluster_components == undef) {
      $components_array = ["all"]
    } else {
      $components_array = [$cluster_components]
    }
  }

  $given_components = $components_array[0] ? {
    "all"   => delete(keys($roles_map), ["hdfs-non-ha", "hdfs-ha", "zeppelin-kerberos"]),
    default => $components_array,
  }
  $ha_dependent_components = $ha_enabled ? {
    true    => ["hdfs-ha"],
    default => ["hdfs-non-ha"],
  }
  $zeppelin_kerberos_components = (("kerberos" in $given_components) and ("zeppelin" in $given_components)) ? {
    true    => ["zeppelin-kerberos"],
    default => [],
  }
  $components = concat(
    $given_components,
    $ha_dependent_components,
    $zeppelin_kerberos_components)

  $master_role_types = ["master", "worker", "library"]
  $standby_role_types = ["standby", "library"]
  $worker_role_types = ["worker", "library"]
  $gateway_role_types = ["client", "gateway_server", "tool"]

  if ($::fqdn == $hadoop_head_node or $::fqdn == $hadoop_gateway_node) {
    if ($hadoop_gateway_node == $hadoop_head_node) {
      $role_types = concat($master_role_types, $gateway_role_types)
    } elsif ($::fqdn == $hadoop_head_node) {
      $role_types = $master_role_types
    } else {
      $role_types = $gateway_role_types
    }
  } elsif ($::fqdn == $standby_head_node_0 or $::fqdn == $standby_head_node_1) {
    $role_types = $standby_role_types
  } else {
    $role_types = $worker_role_types
  }

  $roles = get_roles($components, $role_types, $roles_map)

  class { 'node_with_roles':
    roles => $roles,
  }
}
