# == Class: postfix::server
#
# This sets up an outward facing Postfix server
#
# Any configuration settings not set below can be set using the
# postfix_main_cf type.
#
# == Parameters
#
# [*inet_interfaces*]
# Type: Array or String
# Default: 'all'
#   The interfaces upon which to listen per the inet_interfaces option
#   in main.cf.
#   This defaults to 'all' since it is assumed that you would not be
#   using this class if you didn't want an externally listening
#   server.
#
# [*enable_iptables*]
# Type: Boolean
# Default: 'true'
#   If the externally facing server is enabled, whether or not to use
#   the SIMP iptables class.
#
# [*client_nets*]
# Type: Network List
# Default: hiera('client_nets')
#   The list of clients to allow through IPTables
#
# [*enable_user_connect*]
# Type: Boolean
# Default: 'true'
#   If set to 'true', allows users to connect on port 587 directly.
#   This probably is what you want for an internal server, but not
#   what you want for an externally facing bastion server.
#
# [*enable_tls*]
# Type: Boolean
# Default: 'true'
#   Whether or not to enable TLS.
#
# [*enforce_tls*]
# Type: Boolean
# Default: 'true'
#   Whether or not to enforce the use of TLS, even over port 25.
#
# [*mandatory_ciphers*]
# Type: String
# Default: 'high'
#   The ciphers that must be used for TLS connections.
#
# [*use_haveged*]
# Type: boolean
# Default: true
#   If true, include haveged to assist with entropy generation.
#
# [*enable_simp_pki*]
# Type: Boolean
# Default: 'true'
#   Whether or not to use the SIMP PKI module.
#   If you don't do this, you're on your own with how you incorporate
#   PKI into the Postfix server for TLS.
#
# == Authors
#
# * Trevor Vaughan <tvaughan@onyxpoint.com>
#
class postfix::server (
  $inet_interfaces = ['all'],
  $enable_iptables = true,
  $client_nets = hiera('client_nets'),
  $enable_user_connect = true,
  $enable_tls = true,
  $enforce_tls = true,
  $mandatory_ciphers = 'high',
  $use_haveged = true,
  $enable_simp_pki = true
) {
  validate_array($inet_interfaces)
  validate_bool($enable_iptables)
  validate_net_list($client_nets)
  validate_bool($enable_user_connect)
  validate_bool($enable_tls)
  validate_bool($enforce_tls)
  validate_array_member($mandatory_ciphers,['export','low','medium','high','null'])
  validate_bool($enable_simp_pki)
  validate_bool($use_haveged)

  compliance_map()

  include 'postfix'

  # Don't do any of this if we're just listening on localhost.
  if $inet_interfaces != ['localhost'] {
    postfix_main_cf { 'inet_interfaces':
      value => inline_template('<%= Array(@inet_interfaces).join(",") -%>')
    }

    if $enable_iptables {
      include 'iptables'

      $_dports      = $enable_user_connect ? {
        true    => ['25','587'],
        default => '25'
      }

      ::iptables::add_tcp_stateful_listen { 'allow_postfix':
        client_nets => $client_nets,
        dports      => $_dports
      }
    }

    if $enable_tls {

      if $use_haveged {
        include "::haveged"
      }

      postfix_main_cf { 'smtp_use_tls': value => 'yes' }

      if $enforce_tls {
        postfix_main_cf { 'smtp_enforce_tls': value => 'yes' }
      }

      postfix_main_cf { 'smtp_tls_mandatory_ciphers': value => $mandatory_ciphers }

      if $enable_simp_pki {
        include 'pki'
        ::pki::copy { '/etc/postfix':
          group  => 'postfix',
          notify => Service['postfix']
        }

        postfix_main_cf { 'smtp_tls_CApath':
          value   => '/etc/postfix/pki/cacerts',
          require => ::Pki::Copy['/etc/postfix']
        }

        postfix_main_cf { 'smtp_tls_cert_file':
          value   => "/etc/postfix/pki/public/${::fqdn}.pub",
          require => ::Pki::Copy['/etc/postfix']
        }

        postfix_main_cf { 'smtp_tls_key_file':
          value   => "/etc/postfix/pki/private/${::fqdn}.pem",
          require => ::Pki::Copy['/etc/postfix']
        }
      }
    }
  }
}
