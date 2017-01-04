# This sets up an outward facing Postfix server
#
# Any configuration settings not set below can be set using the
# postfix_main_cf type.
#
# @param inet_interfaces
#   The interfaces upon which to listen per the inet_interfaces option
#   in main.cf.
#   This defaults to 'all' since it is assumed that you would not be
#   using this class if you didn't want an externally listening
#   server.
#
# @param firewall
#   If the externally facing server is enabled, whether or not to use
#   the SIMP iptables class.
#
# @param trusted_nets
#   The list of clients to allow through IPTables
#
# @param enable_user_connect
#   If set to 'true', allows users to connect on port 587 directly.
#   This probably is what you want for an internal server, but not
#   what you want for an externally facing bastion server.
#
# @param enable_tls
#   Whether or not to enable TLS.
#
# @param enforce_tls
#   Whether or not to enforce the use of TLS, even over port 25.
#
# @param mandatory_ciphers
#   The ciphers that must be used for TLS connections.
#
# @param haveged
#   If true, include haveged to assist with entropy generation.
#
# @param enable_simp_pki
#   Whether or not to use the SIMP PKI module.
#   If you don't do this, you're on your own with how you incorporate
#   PKI into the Postfix server for TLS.
#
# @author Trevor Vaughan <tvaughan@onyxpoint.com>
#
class postfix::server (
  Array[String]       $inet_interfaces     = ['all'],
  Boolean             $firewall            = simplib::lookup('simp_options::firewall', { 'default_value' => false }),
  Simplib::Netlist    $trusted_nets        = simplib::lookup('simp_options::trusted_nets', { 'default_value' => ['127.0.0.1'] }),
  Boolean             $enable_user_connect = true,
  Boolean             $enable_tls          = true,
  Boolean             $enforce_tls         = true,
  Postfix::ManCiphers $mandatory_ciphers   = 'high',
  Boolean             $haveged             = simplib::lookup('simp_options::haveged', { 'default_value' => false }),
  Boolean             $enable_simp_pki     = true
) {
  validate_net_list($trusted_nets)

  include '::postfix'

  # Don't do any of this if we're just listening on localhost.
  if $inet_interfaces != ['localhost'] {
    postfix_main_cf { 'inet_interfaces':
      value => inline_template('<%= Array(@inet_interfaces).join(",") -%>')
    }

    if $firewall {
      include '::iptables'

      $_dports = $enable_user_connect ? {
        true    => [ 25,587 ],
        default => 25
      }

      iptables::listen::tcp_stateful { 'allow_postfix':
        trusted_nets => $trusted_nets,
        dports       => $_dports
      }
    }

    if $enable_tls {
      if $haveged { include '::haveged' }

      postfix_main_cf { 'smtp_use_tls': value => 'yes' }

      if $enforce_tls {
        postfix_main_cf { 'smtp_enforce_tls': value => 'yes' }
      }

      postfix_main_cf { 'smtp_tls_mandatory_ciphers': value => $mandatory_ciphers }

      if $enable_simp_pki {
        include '::pki'
        pki::copy { '/etc/postfix':
          group  => 'postfix',
          notify => Service['postfix']
        }

        postfix_main_cf { 'smtp_tls_CApath':
          value   => '/etc/postfix/pki/cacerts',
          require => Pki::Copy['/etc/postfix']
        }

        postfix_main_cf { 'smtp_tls_cert_file':
          value   => "/etc/postfix/pki/public/${facts['fqdn']}.pub",
          require => Pki::Copy['/etc/postfix']
        }

        postfix_main_cf { 'smtp_tls_key_file':
          value   => "/etc/postfix/pki/private/${facts['fqdn']}.pem",
          require => Pki::Copy['/etc/postfix']
        }
      }
    }
  }
}
