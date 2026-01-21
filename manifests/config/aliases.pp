# aliases configuration class called from postfix::config.
#
class postfix::config::aliases {
  assert_private()

  exec { 'postalias':
    command     => '/usr/sbin/postalias /etc/aliases',
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

  if defined('$postfix::main_cf_hash') and $postfix::main_cf_hash =~ Hash {
    $alias_database = $postfix::main_cf_hash.dig('alias_database', 'value')
  } else {
    $alias_database = undef
  }
  $db_file = postfix::alias_db($alias_database)

  if $db_file {
    file { $db_file:
      ensure    => 'file',
      owner     => 'root',
      group     => 'root',
      mode      => '0644',
      subscribe => Exec['postalias'],
    }
  }
}
