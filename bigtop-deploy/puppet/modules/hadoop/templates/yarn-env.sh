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

<% if @use_spark_shuffle -%>
export HADOOP_CLASSPATH="$HADOOP_CLASSPATH:/usr/lib/spark/yarn/lib/spark-yarn-shuffle.jar"
<% end -%>

<% if @hadoop_security_authentication == "kerberos" -%>
DISABLE_USE_SUBJECT_CREDS_ONLY="-Djavax.security.auth.useSubjectCredsOnly=false"
export YARN_RESOURCEMANAGER_OPTS="${DISABLE_USE_SUBJECT_CREDS_ONLY} ${YARN_RESOURCEMANAGER_OPTS}"
export YARN_HISTORYSERVER_OPTS="${DISABLE_USE_SUBJECT_CREDS_ONLY} ${YARN_HISTORYSERVER_OPTS}"
export YARN_TIMELINESERVER_OPTS="${DISABLE_USE_SUBJECT_CREDS_ONLY} ${YARN_TIMELINESERVER_OPTS}"
export YARN_NODEMANAGER_OPTS="${DISABLE_USE_SUBJECT_CREDS_ONLY} ${YARN_NODEMANAGER_OPTS}"
export YARN_PROXYSERVER_OPTS="${DISABLE_USE_SUBJECT_CREDS_ONLY} ${YARN_PROXYSERVER_OPTS}"
<% end -%>