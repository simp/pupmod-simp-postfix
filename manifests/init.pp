# Set up the postfix mail server.
# This also aliases 'mail' to 'mutt' for root.
#
# @param enable_server
#   Whether or not to enable the *externally facing* server.
#
# @param postfix_ensure String to pass to the `postfix` package ensure attribute
#
# @param mutt_ensure String to pass to the `mutt` package ensure attribute
#
# @param inet_protocols
#   The protocols to use when enabling the service
#
 #@author https://github.com/simp/pupmod-simp-postfix/graphs/contributors
#
class postfix (
  Hash                    $main_cf_hash,    # Set in module data
  Boolean                 $enable_server  = false,
  String                  $postfix_ensure = simplib::lookup('simp_options::package_ensure', { 'default_value' => 'installed' }),
  String                  $mutt_ensure    = simplib::lookup('simp_options::package_ensure', { 'default_value' => 'installed' }),
  Postfix::InetProtocols  $inet_protocols = fact('ipv6_enabled') ? { true => ['all'], default => ['ipv4'] }
) {

  include '::postfix::install'
  include '::postfix::config'
  include '::postfix::service'

  Class['postfix::install']
  -> Class['postfix::config']
  -> Class['postfix::service']

  if $enable_server {
    include '::postfix::server'
    Class['postfix::install']
    -> Class['postfix::server']
    -> Class['postfix::service']
  }

}
