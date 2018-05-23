# Service class called from postfix
#
class postfix::service {
  assert_private()

  service { 'postfix':
    ensure     => 'running',
    enable     => true,
    hasrestart => true,
    hasstatus  => true
  }

}
