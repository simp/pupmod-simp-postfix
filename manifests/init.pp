# == Class: postfix
#
# Set up the postfix mail server.
# This also aliases 'mail' to 'mutt' for root.
#
# == Parameters
#
# [*enable_server*]
# Type: Boolean
# Default: 'false'
#   Whether or not to enable the *externally facing* server.
#
# == Authors
#
# * Trevor Vaughan <tvaughan@onyxpoint.com>
#
class postfix (
  $enable_server = false
) {
  validate_bool($enable_server)

  if $enable_server { include 'postfix::server' }

  simp_file_line { '/root/.bashrc':
    path       => '/root/.bashrc',
    line       => 'alias mail="mutt"',
    deconflict => true
  }

  exec { 'postalias':
    command     => '/usr/sbin/postalias /etc/aliases; \
                    /usr/sbin/postalias /etc/aliases.db',
    subscribe   => File['/etc/aliases'],
    refreshonly => true,
    require     => Package['postfix']
  }

  simpcat_build { 'postfix':
    order  => ['*.alias'],
    target => '/etc/aliases'
  }

  simpcat_fragment { 'postfix+0.alias':
    content => template('postfix/aliases.erb')
  }

  file { '/etc/postfix':
    owner   => 'root',
    group   => 'postfix',
    mode    => '0755',
    require => Package['postfix']
  }

  file { [
    '/etc/postfix/postfix-script',
    '/etc/postfix/post-install'
  ]:
    owner   => 'root',
    group   => 'postfix',
    mode    => '0750',
    require => Package['postfix']
  }

  #---
  # Files to be templated. Templates are commented.
  #+++

  file { '/etc/aliases.db':
    owner     => 'root',
    group     => 'root',
    mode      => '0644',
    subscribe => Exec['postalias'],
    require   => Package['postfix']
  }

  file {'/etc/aliases':
    owner     => 'root',
    group     => 'root',
    mode      => '0644',
    require   => Package['postfix'],
    subscribe => Simpcat_build['postfix'],
    audit     => content
  }

  # Main configuration file
  file { '/etc/postfix/main.cf':
    ensure  => 'file',
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    audit   => 'content',
    notify  => Service['postfix'],
    require => Package['postfix']
  }

  file { '/etc/postfix/master.cf':
    ensure  => 'file',
    owner   => 'root',
    group   => 'root',
    mode    => '0640',
    #content => template('postfix/master.cf.erb'),
    audit   => 'content',
    notify  => Service['postfix'],
    require => Package['postfix']
  }

  # postmap files.
  file { [
          '/etc/postfix/access',
          '/etc/postfix/canonical',
          '/etc/postfix/generic',
          '/etc/postfix/relocated',
          '/etc/postfix/transport',
          '/etc/postfix/virtual'
  ]:
    ensure  => 'file',
    owner   => 'root',
    group   => 'root',
    mode    => '0640',
    #content => template('postfix/postmap.erb'),
    audit   => 'content',
    require => Package['postfix'],
    #notify => Exec['postmap']
  }

  # Content checks
  # These need defines to add stuff to them.
  file { [
          '/etc/postfix/header_checks',
          '/etc/postfix/mime_header_checks',
          '/etc/postfix/nested_header_checks',
          '/etc/postfix/body_checks'
  ]:
    ensure  => 'file',
    owner   => 'root',
    group   => 'root',
    mode    => '0640',
    #content => template('postfix/checks.erb'),
    audit   => 'content',
    notify  => Service['postfix'],
    require => Package['postfix']
  }

  file { '/usr/libexec/postfix':
    ensure  => 'present',
    recurse => true,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    require => Package['postfix']
  }

  file { '/var/spool/postfix':
    ensure  => 'directory',
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    require => Package['postfix']
  }

  file { '/var/spool/mail':
    ensure  => 'directory',
    owner   => 'root',
    group   => 'mail',
    mode    => '0755',
    require => Package['postfix']
  }

  file { '/var/mail':
    ensure  => 'link',
    target  => '/var/spool/mail',
    force   => true,
    require => Package['postfix']
  }

  # Since we're using Maildir's set up root's mail alias to be mutt and set
  # up the mutt configuration to read the Maildir in root's home directory.

  file { '/root/.muttrc':
    owner   => 'root',
    group   => 'root',
    mode    => '0600',
    replace => false,
    content => 'set mbox_type="Maildir"
set folder="~/Maildir"
set mask="!^\\.[^.]"
set mbox="~/Maildir"
set record="+.Sent"
set postponed="+.Drafts"
set spoolfile="/var/spool/mail/root"
mailboxes `echo -n "+ "; find ~/Maildir -type d -name ".*" -printf "+\'%f\' "`
',
    require => Package['postfix']
  }

  group { 'postfix':
    ensure    => 'present',
    allowdupe => false,
    gid       => '89',
    require   => Package['postfix']
  }

  group { 'postdrop':
    ensure    => 'present',
    allowdupe => false,
    gid       => '90',
    require   => Package['postfix']
  }

  package { 'postfix': ensure => 'latest' }

  package { 'mutt': ensure => 'latest' }

  service { 'postfix':
    ensure     => 'running',
    enable     => true,
    hasrestart => true,
    hasstatus  => true
  }

  user { 'postfix':
    ensure     => 'present',
    allowdupe  => false,
    uid        => '89',
    gid        => '89',
    home       => '/var/spool/postfix',
    membership => 'inclusive',
    shell      => '/sbin/nologin',
    require    => Package['postfix']
  }
}
