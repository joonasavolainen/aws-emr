<?php

#
# /etc/ganglia/conf.php
#
# You can use this file to override default settings.
#
# For a list of available options, see /usr/share/ganglia/conf_default.php
#
$conf['time_ranges'] = array(
  'hour'  => 3600,
  '2hr'   => 7200,
  '4hr'   => 14400,
  'day'   => 86400,
  'week'  => 604800,
  'month' => 2419200,
  'year'  => 31449600,
);
$conf['ganglia_port'] = <%= @gmetad_interactive_port %>;
$conf['rrdcached_socket'] = '/var/lib/ganglia/rrdcached/rrdcached.limited.sock';
<% if @auth_system -%>
$conf['auth_system'] = '<%= @auth_system %>';
<% end -%>
<% if @default_optional_graph_size -%>
$conf['default_optional_graph_size'] = '<%= @default_optional_graph_size %>';
<% end -%>
?>
