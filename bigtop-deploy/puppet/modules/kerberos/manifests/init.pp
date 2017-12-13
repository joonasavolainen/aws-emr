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

class kerberos {

  class deploy ($roles) {
    if ("kerberos-ad-joiner" in $roles) {
      include kerberos::ad_joiner
    }
    if ("kerberos-server" in $roles) {
      include kerberos::kdc
      include kerberos::kdc::admin_server
    }
    if ("kerberos-client" in $roles) {
      include kerberos::client
    }
  }

  class site ($domain = inline_template('<%= domain %>'),
      $realm = inline_template('<%= domain.upcase %>'),
      $krb5_rdns = true,
      $kdc_server = 'localhost',
      $kdc_port = '88',
      $admin_port = 749,
      $admin_password = 'secure',
      $principal_creation_timeout = 300, # 5 minutes
      $log_dir = "/var/log/kerberos",
      $cross_realm_trust_enabled = false,
      $cross_realm_trust_domain = undef,
      $cross_realm_trust_realm = undef,
      $cross_realm_trust_kdc_server = undef,
      $cross_realm_trust_admin_server = undef,
      $cross_realm_trust_principal_password = undef,
      $ticket_lifetime = "24h",
      $keytab_export_dir = "/var/lib/bigtop_keytabs") {

    if ($cross_realm_trust_enabled) {

      if ($cross_realm_trust_domain == undef) { fail("Kerberos cross realm trust domain is not defined when kerberos cross realm trust is enabled.") }
      if ($cross_realm_trust_realm == undef) { fail("Kerberos cross realm trust realm is not defined when kerberos cross realm trust is enabled.") }
      if ($cross_realm_trust_kdc_server == undef) { fail("Kerberos cross realm trust KDC server is not defined when kerberos cross realm trust is enabled.") }
      if ($cross_realm_trust_admin_server == undef) { fail("Kerberos cross realm trust admin server is not defined when kerberos cross realm trust is enabled.") }
    }

    case $operatingsystem {
        'ubuntu','debian': {
            $package_name_kdc    = 'krb5-kdc'
            $service_name_kdc    = 'krb5-kdc'
            $package_name_admin  = 'krb5-admin-server'
            $service_name_admin  = 'krb5-admin-server'
            $package_name_client = 'krb5-user'
            $exec_path           = '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin'
            $kdc_etc_path        = '/etc/krb5kdc'
            $kdc_db_path         = '/var/lib/krb5kdc'
        }
        # default assumes CentOS, Redhat 5 series (just look at how random it all looks :-()
        default: {
            $package_name_kdc    = 'krb5-server'
            $service_name_kdc    = 'krb5kdc'
            $package_name_admin  = 'krb5-libs'
            $service_name_admin  = 'kadmin'
            $package_name_client = 'krb5-workstation'
            $exec_path           = '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/kerberos/sbin:/usr/kerberos/bin'
            $kdc_etc_path        = '/var/kerberos/krb5kdc'
            $kdc_db_path         = '/var/kerberos/krb5kdc'
        }
    }

    file { $log_dir:
      ensure => 'directory',
      owner => "root",
      group => "root",
    }

    file { "/etc/krb5.conf":
      content => template('kerberos/krb5.conf'),
      require => File[$kerberos::site::log_dir],
      owner => "root",
      group => "root",
      mode => "0644",
    }

    @file { $keytab_export_dir:
      ensure => directory,
      owner  => "root",
      group  => "root",
    }

    # Required for SPNEGO
    @principal { "HTTP": 

    }
  }

  class ad_joiner(
    $ad_domain_join_user = undef,
    $ad_domain_join_password = undef,
    $package_name_sssd = 'sssd',
    $package_name_realmd = 'realmd',
  ) inherits kerberos::site {

    case $operatingsystem {
      'ubuntu','debian': {
        # TODO Add support for other operating systems.
        fail("Active Directory Integration not implemented for $operatinsystem")
      }
      # default assumes CentOS, Redhat 5 series
      default: {
        $service_name_sshd = 'sshd'
        $package_name_sshd = 'openssh-server'
      }
    }

    include kerberos::client

    if $ad_domain_join_user == undef { fail("AD Domain Join User is not defined when active directory integration with kerberos is requested.") }
    if $ad_domain_join_password == undef { fail("AD Domain Join Password is not defined when active directory integration with kerberos is requested.") }

    package { "$package_name_sssd":
      ensure => installed,
    }

    package { "$package_name_realmd":
      ensure => installed,
    }

    package { "$package_name_sshd":
      ensure => installed,
    }

    exec { "realm_join":
      path        => $kerberos::site::exec_path,
      environment => ["AD_DOMAIN_JOIN_PASSWORD=${ad_domain_join_password}", "AD_DOMAIN_JOIN_USER=${ad_domain_join_user}",
        "CROSS_REALM_TRUST_REALM=${cross_realm_trust_realm}", "CROSS_REALM_TRUST_DOMAIN=${cross_realm_trust_domain}"],
      command     => 'echo "${AD_DOMAIN_JOIN_PASSWORD}" | realm join -U "${AD_DOMAIN_JOIN_USER}"@"${CROSS_REALM_TRUST_REALM}" "${CROSS_REALM_TRUST_DOMAIN}"',
      require     => [Package["$package_name_realmd"], Package["$package_name_sssd"]],
      before      => [File["/etc/krb5.conf"], Class["kerberos::client"]],
      unless      => 'realm list | grep -w "${CROSS_REALM_TRUST_REALM}"',
      tries => 3,
      try_sleep => 5,
      logoutput => true,
    }

    augeas { 'ssh_password_authentication':
      context => '/files/etc/ssh/sshd_config',
      changes => [
        "set PasswordAuthentication yes"
      ],
      require => Package["$package_name_sshd"],
    }

    $upcased_cross_realm_trust_domain = upcase($cross_realm_trust_domain)
    augeas { 'sssd_use_fully_qualified_names':
      context => '/files/etc/sssd/sssd.conf',
      changes => [
        "set *[ad_domain = '$cross_realm_trust_domain' or ad_domain = '$upcased_cross_realm_trust_domain']/use_fully_qualified_names False"
      ],
      require => [Package[$package_name_sssd], Exec["realm_join"]],
    }

    service { "$service_name_sshd":
      ensure     => running,
      subscribe  => Augeas['ssh_password_authentication'],
      hasrestart => true,
      require    => Package["$package_name_sshd"],
    }

    service { "$package_name_sssd":
      ensure     => running,
      subscribe  => [Augeas['sssd_use_fully_qualified_names'], File['/etc/krb5.conf']],
      hasrestart => true,
      require => Package[$package_name_sssd],
    }
  }

  class kdc inherits kerberos::site {
    package { $package_name_kdc:
      ensure => installed,
    }

    file { $kdc_etc_path:
    	ensure => directory,
        owner => root,
        group => root,
        mode => "0700",
        require => Package["$package_name_kdc"],
    }
    file { "${kdc_etc_path}/kdc.conf":
      content => template('kerberos/kdc.conf'),
      require => Package["$package_name_kdc"],
      owner => "root",
      group => "root",
      mode => "0644",
    }
    file { "${kdc_etc_path}/kadm5.acl":
      content => template('kerberos/kadm5.acl'),
      require => Package["$package_name_kdc"],
      owner => "root",
      group => "root",
      mode => "0644",
    }

    exec { "kdb5_util":
      path => $exec_path,
      environment => ["PASSWORD=${admin_password}"],
      command => "rm -f /etc/kadm5.keytab ; kdb5_util -P \"\$PASSWORD\" -r ${realm} create -s && kadmin.local -q \"cpw -pw \\\"\$PASSWORD\\\" kadmin/admin\"",
      
      creates => "${kdc_etc_path}/stash",

      subscribe => File["${kdc_etc_path}/kdc.conf"],
      # refreshonly => true, 

      require => [Package["$package_name_kdc"], File["${kdc_etc_path}/kdc.conf"], File["/etc/krb5.conf"]],
    }

    service { $service_name_kdc:
      ensure => running,
      require => [Package["$package_name_kdc"], File["${kdc_etc_path}/kdc.conf"], Exec["kdb5_util"]],
      subscribe => [File["${kdc_etc_path}/kadm5.acl"], File["${kdc_etc_path}/kdc.conf"]],
      hasrestart => true,
    }
    Service["$service_name_kdc"] -> Principal <| |>

    class admin_server inherits kerberos::kdc {
      $se_hack = "setsebool -P kadmind_disable_trans  1 ; setsebool -P krb5kdc_disable_trans 1"

      package { "$package_name_admin":
        ensure => installed,
        require => Package["$package_name_kdc"],
      } 
  
      service { "$service_name_admin":
        ensure => running,
        require => [Package["$package_name_admin"], Service["$service_name_kdc"]],
        subscribe => [File["${kdc_etc_path}/kadm5.acl"], File["${kdc_etc_path}/kdc.conf"]],
        hasrestart => true,
        restart => "${se_hack} ; service ${service_name_admin} restart",
        start => "${se_hack} ; service ${service_name_admin} start",
      }
      Service["$service_name_admin"] -> Principal <| |>

      if ($cross_realm_trust_enabled) {

        if ($cross_realm_trust_principal_password == undef) { fail("Kerberos cross realm trust principal password is not defined when kerberos cross realm trust is enabled.") }

        principal { "krbtgt/${cross_realm_trust_realm}@${realm}":
          principal_password => "$cross_realm_trust_principal_password",
          create_keytab      => false,
        }
        principal { "krbtgt/${realm}@${cross_realm_trust_realm}":
          principal_password => "$cross_realm_trust_principal_password",
          create_keytab      => false,
        }
      }
    }
  }

  class client inherits kerberos::site {
    package { $package_name_client:
      ensure => installed,
    }
  }

  define principal($principal_password = undef,
    $create_keytab = true) {

    if ($principal_password != undef and $create_keytab) {
      fail("Setting a principal password and keytab creation are mutually exclusive.")
    }
    require "kerberos::client"

    $admin_password = $kerberos::site::admin_password
    $principal_creation_timeout = $kerberos::site::principal_creation_timeout
    $base_environment = ["PASSWORD=${admin_password}"]

    if ($create_keytab) {
      realize(File[$kerberos::site::keytab_export_dir])

      $principal = "$title/$::fqdn"
      $keytab    = "$kerberos::site::keytab_export_dir/$title.keytab"
      $password_argument = '-randkey'
      $environment = $base_environment

      exec { "xst.$title":
        path    => $kerberos::site::exec_path,
        environment => $environment,
        command => "kadmin -w \"\$PASSWORD\" -p kadmin/admin -q 'xst -k $keytab $principal'",
        unless  => "klist -kt $keytab 2>/dev/null | grep -q $principal",
        tries => 120,
        try_sleep => 5,
        timeout => $principal_creation_timeout,
        require => [File[$kerberos::site::keytab_export_dir], Exec["principal_creation.$principal"]]
      }
    }
    else {
      $principal = $title
      $password_argument = '-pw \\"$PRINCIPAL_PASSWORD\\"'
      if ($principal_password == undef) {
        fail('principal_password is not defined')
      }
      $environment = concat($base_environment, "PRINCIPAL_PASSWORD=${principal_password}")
    }

    exec { "principal_creation.$principal":
      path => $kerberos::site::exec_path,
      environment => $environment,
      command => "kadmin -w \"\$PASSWORD\" -p kadmin/admin -q \"addprinc $password_argument $principal\"",
      unless => "kadmin -w \"\$PASSWORD\" -p kadmin/admin -q listprincs | grep -q $principal",
      tries => 120,  # Adding tries if slave node come up before the kdc is ready
      try_sleep => 5,
      timeout => $principal_creation_timeout,
      require => File["/etc/krb5.conf"],
    }
  }

  define host_keytab($princs = [ $title ], $spnego = false,
    $owner = $title, $group = "", $mode = "0400",
  ) {
    $keytab = "/etc/$title.keytab"

    $internal_princs = $spnego ? {
      true => [ 'HTTP' ],
      default => [ ],
    }
    realize(Kerberos::Principal[$internal_princs])

    $includes = inline_template("<%=
      [@princs, @internal_princs].flatten.map { |x|
        \"rkt $kerberos::site::keytab_export_dir/#{x}.keytab\"
      }.join(\"\n\")
    %>")

    kerberos::principal { $princs:
    }

    exec { "ktinject.$title":
      path     => $kerberos::site::exec_path,
      command  => "ktutil <<EOF
        $includes
        wkt $keytab
EOF
        chown ${owner}:${group} ${keytab}
        chmod ${mode} ${keytab}",
      creates => $keytab,
      require => [ Kerberos::Principal[$princs],
                   Kerberos::Principal[$internal_princs] ],
    }

    exec { "aquire $title keytab":
        path    => $kerberos::site::exec_path,
        user    => $owner,
        command => "bash -c 'kinit -kt $keytab ${title}/$::fqdn'",
        require => Exec["ktinject.$title"],
    }
  }
}
