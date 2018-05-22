# main.cf configuration class called from postfix::config.
#
# Set settings in /etc/postfix/main.cf based on
# postfix:: main_cf_hash and postfix::inet_protocols.
#
# IMPORTANT:
# * postfix::main_cf_hash value is a deep merge of hieradata
#   and data-in-module settings.
# * For backward compatibility, all main.cf settings already set
#   from other sources in this module (postfix::inet_procotols
#   and numerous postfix::server parameters) **CANNOT** be
#   also set in postfix::main_cf_hash. Otherwise, the catalog
#   will fail to compile because of  duplicate `postfix_main_cf`
#   resource declarations.
#
class postfix::config::main_cf(
){
  assert_private()

  file { '/etc/postfix/main.cf':
    ensure => 'file',
    owner  => 'root',
    group  => 'root',
    mode   => '0644',
  }

  postfix_main_cf { 'inet_protocols':
    value => join($::postfix::inet_protocols, ',')
  }

  # Add values to the postfix/main.cf file.
  $::postfix::main_cf_hash.each |String $setting, $data|{
    if $data['value'] =~ Array {
      $_value = join($data['value'], ',')
    }
    else {
      $_value = $data['value']
    }
    postfix_main_cf { $setting:
      value => $_value
    }
  }
}
