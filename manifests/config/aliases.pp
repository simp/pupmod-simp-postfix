# aliases configuration class called from postfix::config.
#
class postfix::config::aliases {
  assert_private()

  exec { 'postalias':
    command     => '/usr/sbin/postalias /etc/aliases; \
                    /usr/sbin/postalias /etc/aliases.db',
    subscribe   => Concat['/etc/aliases'],
    refreshonly => true,
  }

  concat { '/etc/aliases':
    owner => 'root',
    group => 'root',
    mode  => '0644',
  }

  concat::fragment { 'main.alias':
    order   => 1,
    target  => '/etc/aliases',
    content => template('postfix/aliases.erb')
  }

  file { '/etc/aliases.db':
    owner     => 'root',
    group     => 'root',
    mode      => '0644',
    subscribe => Exec['postalias'],
  }
}
