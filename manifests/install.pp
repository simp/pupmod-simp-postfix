# Install the packages, users and groups
# needed for the postfix server.
#
# @author https://github.com/simp/pupmod-simp-postfix/graphs/contributors
#
class postfix::install {
  assert_private()

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

  package { 'postfix': ensure => $::postfix::postfix_ensure }
  package { 'mutt':    ensure => $::postfix::mutt_ensure }

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
