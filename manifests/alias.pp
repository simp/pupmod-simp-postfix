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
# @author https://github.com/simp/pupmod-simp-postfix/graphs/contributors
#
define postfix::alias (
  String[1] $values
){

  concat::fragment { "postfix+${name}.alias":
    order   => 2,
    target  => '/etc/aliases',
    content => "${name}: ${values}\n"
  }

}
