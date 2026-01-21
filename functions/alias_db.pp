# @summary Determine the postfix alias database file name based on the alias_database setting
# @param alias_database The alias_database setting from postfix
# @return The alias database file name or undef if not supported
function postfix::alias_db(Optional[String[1]] $alias_database) >> Optional[String[1]] {
  $db = $alias_database.lest || { $facts['postfix_alias_database'] }
  if $db =~ Undef {
    return undef
  }

  $parts = $db.split(/:/)
  if $parts.size != 2 {
    warning("Invalid alias_database format '${db}'")
    return undef
  }

  $db_type = $parts[0]
  $aliases_file = $parts[1]
  unless $db_type =~ String[1] and $aliases_file =~ String[1] {
    return undef
  }

  case $db_type {
    'cdb': { return "${aliases_file}.${db_type}" }
    'dbm', 'sdbm': { return "${aliases_file}.dir" }
    'lmdb': { return "${aliases_file}.${db_type}" }
    'hash', 'btree': { return "${aliases_file}.db" }
    default: {
      warning("Unsupported alias database type '${db_type}'")
      return undef
    }
  }
}
