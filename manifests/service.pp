#
#  Start the postfix service
#
class postfix::service (
) {

  service { 'postfix':
    ensure     => 'running',
    enable     => true,
    hasrestart => true,
    hasstatus  => true
  }

}
