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
$classpath += ':/etc/hive/conf' if @use_hive
$classpath += ':/usr/lib/hadoop-lzo/lib/*' if @hadoop_lzo_codec
$classpath += ':/usr/share/aws/aws-java-sdk/*'
$classpath += ':/usr/share/aws/emr/emrfs/conf:/usr/share/aws/emr/emrfs/lib/*:/usr/share/aws/emr/emrfs/auxlib/*' if @use_emrfs

$libraryPath = ':/usr/lib/hadoop/lib/native'
$libraryPath += ':/usr/lib/hadoop-lzo/lib/native' if @hadoop_lzo_codec
-%>

export CLASSPATH+="<%= $classpath %>"
export LD_LIBRARY_PATH+="<%= $libraryPath %>"
