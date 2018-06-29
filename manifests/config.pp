# Configuration class called from postfix.
#
# * Configures settings in the main.cf file.
# * Builds the alias database so most system users mail will get sent
#   to the root mailbox.
# * Setup root's mail alias to be mutt and set up the mutt
#   configuration to read the Maildir in root's home directory.
# * Sets permissions on other postfix configuration files.
# * Creates postfix processing directories.
#
class postfix::config {
  assert_private()

  include 'postfix::config::main_cf'
  include 'postfix::config::aliases'
  include 'postfix::config::root'

  file { '/etc/postfix':
    ensure => 'directory',
    owner  => 'root',
    group  => 'postfix',
    mode   => '0755',
  }

  file { [
    '/etc/postfix/postfix-script',
    '/etc/postfix/post-install'
  ]:
    owner => 'root',
    group => 'postfix',
    mode  => '0750';
  }


  #---
  # Files to be templated. Templates are commented.
  #+++

  # master daemon configuration file
  file { '/etc/postfix/master.cf':
    ensure => 'file',
    owner  => 'root',
    group  => 'root',
    mode   => '0644',
    #content => template('postfix/master.cf.erb'),
  }

  # postmap files.
  file { [
    '/etc/postfix/access',
    '/etc/postfix/canonical',
    '/etc/postfix/generic',
    '/etc/postfix/relocated',
    '/etc/postfix/transport',
    '/etc/postfix/virtual',
  ]:
    ensure => 'file',
    owner  => 'root',
    group  => 'root',
    mode   => '0644';
    #content => template('postfix/postmap.erb'),
    #notify => Exec['postmap']
  }

  # Content checks
  # These need defines to add stuff to them.
  file { [
    '/etc/postfix/header_checks',
    '/etc/postfix/mime_header_checks',
    '/etc/postfix/nested_header_checks',
    '/etc/postfix/body_checks',
  ]:
    ensure => 'file',
    owner  => 'root',
    group  => 'root',
    mode   => '0644',
    #content => template('postfix/checks.erb'),
  }

  file { '/usr/libexec/postfix':
    ensure => 'directory',
    owner  => 'root',
    group  => 'root',
    mode   => '0755'
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
    mode   => '0775'
  }

  file { '/var/mail':
    ensure => 'link',
    target => '/var/spool/mail',
    force  => true
  }

}
