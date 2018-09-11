# This sets up an outward facing Postfix server
#
# Any configuration settings not set below can be set using the
# postfix_main_cf type.
#
# @param inet_interfaces
#   The interfaces upon which to listen per the inet_interfaces option
#   in main.cf.
#
#   * This defaults to `all` since it is assumed that you would not be using
#     this class if you didn't want an externally listening server.
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
# @param pki
#   * If 'simp', include SIMP's pki module and use pki::copy to manage
#     application certs in /etc/pki/simp_apps/postfix/x509
#   * If true, do *not* include SIMP's pki module, but still use pki::copy
#     to manage certs in /etc/pki/simp_apps/postfix/x509
#   * If false, do not include SIMP's pki module and do not use pki::copy
#     to manage certs.  You will need to appropriately assign a subset of:
#     * app_pki_dir
#     * app_pki_key
#     * app_pki_cert
#     * app_pki_ca
#     * app_pki_ca_dir
#
# @param app_pki_external_source
#   * If pki = 'simp' or true, this is the directory from which certs will be
#     copied, via pki::copy.  Defaults to /etc/pki/simp/x509.
#
#   * If pki = false, this variable has no effect.
#
# @param app_pki_dir
#   This variable controls the basepath of $app_pki_key, $app_pki_cert,
#   $app_pki_ca, $app_pki_ca_dir, and $app_pki_crl.
#   It defaults to /etc/pki/simp_apps/postfix/pki.
#
# @param app_pki_key
#   Path and name of the private SSL key file
#
# @param app_pki_cert
#   Path and name of the public SSL certificate
#
# @param app_pki_ca_dir
#   Path to the CA.
#
# @author https://github.com/simp/pupmod-simp-postfix/graphs/contributors
#
class postfix::server (
  Array[String[1]]              $inet_interfaces         = ['all'],
  Boolean                       $firewall                = simplib::lookup('simp_options::firewall', { 'default_value' => false }),
  Simplib::Netlist              $trusted_nets            = simplib::lookup('simp_options::trusted_nets', { 'default_value' => ['127.0.0.1'] }),
  Boolean                       $enable_user_connect     = true,
  Boolean                       $enable_tls              = true,
  Boolean                       $enforce_tls             = true,
  Postfix::ManCiphers           $mandatory_ciphers       = 'high',
  Boolean                       $haveged                 = simplib::lookup('simp_options::haveged', { 'default_value'      => false }),
  Variant[Enum['simp'],Boolean] $pki                     = simplib::lookup('simp_options::pki', { 'default_value'          => false }),
  String                        $app_pki_external_source = simplib::lookup('simp_options::pki::source', { 'default_value'  => '/etc/pki/simp/x509' }),
  Stdlib::Absolutepath          $app_pki_dir             = '/etc/pki/simp_apps/postfix/x509',
  Stdlib::Absolutepath          $app_pki_key             = "${app_pki_dir}/private/${facts['fqdn']}.pem",
  Stdlib::Absolutepath          $app_pki_cert            = "${app_pki_dir}/public/${facts['fqdn']}.pub",
  Stdlib::Absolutepath          $app_pki_ca_dir          = "${app_pki_dir}/cacerts"
) {
  include 'postfix'

  # Don't do any of this if we're just listening on localhost.
  if $inet_interfaces != ['localhost'] {
    postfix_main_cf { 'inet_interfaces':
      value => join($inet_interfaces, ',')
    }

    if $firewall {
      include 'iptables'

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
      if $haveged { include 'haveged' }

      if $enforce_tls {
        postfix_main_cf { 'smtp_enforce_tls': value => 'yes' }
      }

      postfix_main_cf {
        'smtp_use_tls'               : value => 'yes';
        'smtp_tls_mandatory_ciphers' : value => $mandatory_ciphers;
        'smtp_tls_CApath'            : value => $app_pki_ca_dir;
        'smtp_tls_cert_file'         : value => $app_pki_cert;
        'smtp_tls_key_file'          : value => $app_pki_key;
      }

      if $pki {
        pki::copy { 'postfix':
          pki    => $pki,
          source => $app_pki_external_source,
          group  => 'postfix',
          notify => Service['postfix']
        }
      }
    }
  }
}
