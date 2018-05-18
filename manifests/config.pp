# This module does basic configuration for the postfix
# server.
#
# It builds the alias database so most system users
# mail will get sent to the root mailbox.
# Sets permissions on the configuration files.
# Configures settings in the main.cf file.
# Setup root's mail alias to be mutt and set
# up the mutt configuration to read the Maildir in root's home directory.
#
class postfix::config (
) {

  assert_private()

  include '::postfix::config::main_cf'

  simp_file_line { '/root/.bashrc':
    path       => '/root/.bashrc',
    line       => 'alias mail="mutt"',
    deconflict => true
  }

  exec { 'postalias':
    command     => '/usr/sbin/postalias /etc/aliases; \
                    /usr/sbin/postalias /etc/aliases.db',
    subscribe   => Concat['/etc/aliases'],
    refreshonly => true,
  }

  concat { '/etc/aliases':
    owner  => 'root',
    group  => 'root',
    mode   => '0644',
    notify => Service['postfix']
  }

  concat::fragment { 'main.alias':
    order   => 1,
    target  => '/etc/aliases',
    content => template('postfix/aliases.erb')
  }

  file { '/etc/postfix':
    owner => 'root',
    group => 'postfix',
    mode  => '0755',
  }

  file {
    default:
      owner => 'root',
      group => 'postfix',
      mode  => '0750';

    '/etc/postfix/postfix-script':;
    '/etc/postfix/post-install':;
  }

  #---
  # Files to be templated. Templates are commented.
  #+++

  file { '/etc/aliases.db':
    owner     => 'root',
    group     => 'root',
    mode      => '0644',
    subscribe => Exec['postalias'],
  }

  # Main configuration file
  file { '/etc/postfix/main.cf':
    ensure => 'file',
    owner  => 'root',
    group  => 'root',
    mode   => '0644',
    notify => Service['postfix'],
  }

  file { '/etc/postfix/master.cf':
    ensure => 'file',
    owner  => 'root',
    group  => 'root',
    mode   => '0640',
    #content => template('postfix/master.cf.erb'),
    notify => Service['postfix'],
  }

  # postmap files.
  file {
    default:
      ensure => 'file',
      owner  => 'root',
      group  => 'root',
      mode   => '0640';
      #content => template('postfix/postmap.erb'),
      #notify => Exec['postmap']

    '/etc/postfix/access':;
    '/etc/postfix/canonical':;
    '/etc/postfix/generic':;
    '/etc/postfix/relocated':;
    '/etc/postfix/transport':;
    '/etc/postfix/virtual':;
  }

  # Content checks
  # These need defines to add stuff to them.
  file {
    default:
      ensure => 'file',
      owner  => 'root',
      group  => 'root',
      mode   => '0640',
      #content => template('postfix/checks.erb'),
      notify => Service['postfix'];

    '/etc/postfix/header_checks':;
    '/etc/postfix/mime_header_checks':;
    '/etc/postfix/nested_header_checks':;
    '/etc/postfix/body_checks':;
  }

  file { '/usr/libexec/postfix':
    ensure  => 'present',
    recurse => true,
    owner   => 'root',
    group   => 'root',
    mode    => '0755'
  }

  file { '/var/spool/postfix':
    ensure => 'directory',
    owner  => 'root',
    group  => 'root',
    mode   => '0755'
  }

  file { '/var/spool/mail':
    ensure => 'directory',
    owner  => 'root',
    group  => 'mail',
    mode   => '0755'
  }

  file { '/var/mail':
    ensure => 'link',
    target => '/var/spool/mail',
    force  => true
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
'
  }

}
