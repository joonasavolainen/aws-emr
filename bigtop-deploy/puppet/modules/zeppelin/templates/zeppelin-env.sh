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
<%-
$classpath = ''
$classpath += ':/usr/lib/hadoop-lzo/lib/*' if @hadoop_lzo_codec
$classpath += ':/usr/lib/hadoop/hadoop-aws.jar'
$classpath += ':/usr/share/aws/aws-java-sdk/*'
$classpath += ':/usr/share/aws/emr/emrfs/conf:/usr/share/aws/emr/emrfs/lib/*:/usr/share/aws/emr/emrfs/auxlib/*' if @use_emrfs
$classpath += ':/usr/share/aws/hmclient/lib/aws-glue-datacatalog-spark-client.jar' if @use_aws_hm_client
-%>

export ZEPPELIN_PORT=<%= @server_port %>
export ZEPPELIN_CONF_DIR=/etc/zeppelin/conf
export ZEPPELIN_LOG_DIR=/var/log/zeppelin
export ZEPPELIN_PID_DIR=/var/run/zeppelin
export ZEPPELIN_PID=$ZEPPELIN_PID_DIR/zeppelin.pid
export ZEPPELIN_WAR_TEMPDIR=/var/run/zeppelin/webapps
export ZEPPELIN_NOTEBOOK_DIR=/var/lib/zeppelin/notebook
export MASTER=<%= @spark_master_url %>
export SPARK_HOME=/usr/lib/spark
export HADOOP_CONF_DIR=/etc/hadoop/conf
export CLASSPATH="<%= $classpath %>"
