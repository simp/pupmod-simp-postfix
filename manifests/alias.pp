# Add an alias to the postalias file.
# See aliases(5) for details of the internal format.
#
# @param name
#   The account to receive the alias.
#
# @param values
#   The RHS values of the postalias file in accordance with
#   aliases(5).
#
# @author Trevor Vaughan <tvaughan@onyxpoint.com>
#
define postfix::alias (
  String $values
){
  simpcat_fragment { "postfix+${name}.alias":
    content => "${name}: ${values}\n"
  }
}
