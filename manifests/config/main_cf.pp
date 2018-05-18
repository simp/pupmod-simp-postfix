#
# Read the settings from main_cf_hash in the data file and
# create entries for them in the /etc/postfix/main.cf
# file.
#
# The settings not in the hash that are set here
# are left outside the hash so the interface
# for the postfix module remains the same.  They will be
# moved in future releases if possible.
#
class postfix::config::main_cf(
){

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
