# == Define: postfix::alias
#
# Add an alias to the postalias file.
# See aliases(5) for details of the internal format.
#
# == Parameters
#
# [*name*]
# Type: String
#   The account to receive the alias.
#
# [*values*]
# Type: String
#   The RHS values of the postalias file in accordance with
#   aliases(5).
#
# == Authors
#
# * Trevor Vaughan <tvaughan@onyxpoint.com>
#
define postfix::alias (
    $values
  ){
  simpcat_fragment { "postfix+${name}.alias":
    content => "${name}: ${values}\n"
  }
}
