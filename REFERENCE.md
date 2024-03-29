# Reference

<!-- DO NOT EDIT: This document was generated by Puppet Strings -->

## Table of Contents

### Classes

* [`postfix`](#postfix): Set up the postfix mail server. This also aliases 'mail' to 'mutt' for root.
* [`postfix::config`](#postfix--config): Configuration class called from postfix.  * Configures settings in the main.cf file. * Builds the alias database so most system users mail wi
* [`postfix::config::aliases`](#postfix--config--aliases): aliases configuration class called from postfix::config.
* [`postfix::config::main_cf`](#postfix--config--main_cf): main.cf configuration class called from postfix::config.  Set settings in /etc/postfix/main.cf based on postfix:: main_cf_hash and postfix::i
* [`postfix::config::root`](#postfix--config--root): root user postfix Configuration class called from postfix::config.
* [`postfix::install`](#postfix--install): Install the packages, users and groups needed for the postfix server.
* [`postfix::server`](#postfix--server): This sets up an outward facing Postfix server  Any configuration settings not set below can be set using the postfix_main_cf type.
* [`postfix::service`](#postfix--service): Service class called from postfix

### Defined types

* [`postfix::alias`](#postfix--alias): Add an alias to the postalias file. See aliases(5) for details of the internal format.

### Resource types

* [`postfix_main_cf`](#postfix_main_cf): Modifies settings in the postfix main.cf configuration file.

### Data types

* [`Postfix::InetProtocols`](#Postfix--InetProtocols): Allowed inet protocol settings
* [`Postfix::ManCiphers`](#Postfix--ManCiphers): Allowed mandatory ciphers

## Classes

### <a name="postfix"></a>`postfix`

Set up the postfix mail server.
This also aliases 'mail' to 'mutt' for root.

#### Parameters

The following parameters are available in the `postfix` class:

* [`main_cf_hash`](#-postfix--main_cf_hash)
* [`enable_server`](#-postfix--enable_server)
* [`postfix_ensure`](#-postfix--postfix_ensure)
* [`mutt_ensure`](#-postfix--mutt_ensure)
* [`inet_protocols`](#-postfix--inet_protocols)
* [`aliases`](#-postfix--aliases)

##### <a name="-postfix--main_cf_hash"></a>`main_cf_hash`

Data type: `Hash`

Hash of main.cf configuration parameters
- Is a deep merge of hieradata and data-in-module settings.
- For backward compatibility, all main.cf settings already set
  from other sources in this module (`$inet_procotols` and
  numerous `postfix::server parameters`) **CANNOT** be also set
  in `$main_cf_hash`.  Otherwise, the catalog will fail to
  compile because of  duplicate `postfix_main_cf` resource
  declarations.

##### <a name="-postfix--enable_server"></a>`enable_server`

Data type: `Boolean`

Whether or not to enable the *externally facing* server.

Default value: `false`

##### <a name="-postfix--postfix_ensure"></a>`postfix_ensure`

Data type: `String`

String to pass to the `postfix` package ensure attribute

Default value: `simplib::lookup('simp_options::package_ensure', { 'default_value' => 'installed' })`

##### <a name="-postfix--mutt_ensure"></a>`mutt_ensure`

Data type: `String`

String to pass to the `mutt` package ensure attribute

Default value: `simplib::lookup('simp_options::package_ensure', { 'default_value' => 'installed' })`

##### <a name="-postfix--inet_protocols"></a>`inet_protocols`

Data type: `Postfix::InetProtocols`

The protocols to use when enabling the service

Default value: `fact('ipv6_enabled') ? { true => ['all'], default => ['ipv4']`

##### <a name="-postfix--aliases"></a>`aliases`

Data type: `Optional[Hash]`

Hash of alias key/value pairs that can be set in hieradata
Example:
  ---
  postfix::aliases:
    'root': 'system.administrator@mail.mil'
    'foo.bar': 'fbar, fbar@example.com'

### <a name="postfix--config"></a>`postfix::config`

Configuration class called from postfix.

* Configures settings in the main.cf file.
* Builds the alias database so most system users mail will get sent
  to the root mailbox.
* Setup root's mail alias to be mutt and set up the mutt
  configuration to read the Maildir in root's home directory.
* Sets permissions on other postfix configuration files.
* Creates postfix processing directories.

### <a name="postfix--config--aliases"></a>`postfix::config::aliases`

aliases configuration class called from postfix::config.

### <a name="postfix--config--main_cf"></a>`postfix::config::main_cf`

main.cf configuration class called from postfix::config.

Set settings in /etc/postfix/main.cf based on
postfix:: main_cf_hash and postfix::inet_protocols.

IMPORTANT:
* postfix::main_cf_hash value is a deep merge of hieradata
  and data-in-module settings.
* For backward compatibility, all main.cf settings already set
  from other sources in this module (postfix::inet_procotols
  and numerous postfix::server parameters) **CANNOT** be
  also set in postfix::main_cf_hash. Otherwise, the catalog
  will fail to compile because of  duplicate `postfix_main_cf`
  resource declarations.

### <a name="postfix--config--root"></a>`postfix::config::root`

root user postfix Configuration class called from postfix::config.

### <a name="postfix--install"></a>`postfix::install`

Install the packages, users and groups
needed for the postfix server.

### <a name="postfix--server"></a>`postfix::server`

This sets up an outward facing Postfix server

Any configuration settings not set below can be set using the
postfix_main_cf type.

#### Parameters

The following parameters are available in the `postfix::server` class:

* [`inet_interfaces`](#-postfix--server--inet_interfaces)
* [`firewall`](#-postfix--server--firewall)
* [`trusted_nets`](#-postfix--server--trusted_nets)
* [`enable_user_connect`](#-postfix--server--enable_user_connect)
* [`enable_tls`](#-postfix--server--enable_tls)
* [`enforce_tls`](#-postfix--server--enforce_tls)
* [`mandatory_ciphers`](#-postfix--server--mandatory_ciphers)
* [`haveged`](#-postfix--server--haveged)
* [`pki`](#-postfix--server--pki)
* [`app_pki_external_source`](#-postfix--server--app_pki_external_source)
* [`app_pki_dir`](#-postfix--server--app_pki_dir)
* [`app_pki_key`](#-postfix--server--app_pki_key)
* [`app_pki_cert`](#-postfix--server--app_pki_cert)
* [`app_pki_ca_dir`](#-postfix--server--app_pki_ca_dir)

##### <a name="-postfix--server--inet_interfaces"></a>`inet_interfaces`

Data type: `Array[String[1]]`

The interfaces upon which to listen per the inet_interfaces option
in main.cf.

* This defaults to `all` since it is assumed that you would not be using
  this class if you didn't want an externally listening server.

Default value: `['all']`

##### <a name="-postfix--server--firewall"></a>`firewall`

Data type: `Boolean`

If the externally facing server is enabled, whether or not to use
the SIMP iptables class.

Default value: `simplib::lookup('simp_options::firewall', { 'default_value' => false })`

##### <a name="-postfix--server--trusted_nets"></a>`trusted_nets`

Data type: `Simplib::Netlist`

The list of clients to allow through IPTables

Default value: `simplib::lookup('simp_options::trusted_nets', { 'default_value' => ['127.0.0.1'] })`

##### <a name="-postfix--server--enable_user_connect"></a>`enable_user_connect`

Data type: `Boolean`

If set to 'true', allows users to connect on port 587 directly.
This probably is what you want for an internal server, but not
what you want for an externally facing bastion server.

Default value: `true`

##### <a name="-postfix--server--enable_tls"></a>`enable_tls`

Data type: `Boolean`

Whether or not to enable TLS.

Default value: `true`

##### <a name="-postfix--server--enforce_tls"></a>`enforce_tls`

Data type: `Boolean`

Whether or not to enforce the use of TLS, even over port 25.

Default value: `true`

##### <a name="-postfix--server--mandatory_ciphers"></a>`mandatory_ciphers`

Data type: `Postfix::ManCiphers`

The ciphers that must be used for TLS connections.

Default value: `'high'`

##### <a name="-postfix--server--haveged"></a>`haveged`

Data type: `Boolean`

If true, include haveged to assist with entropy generation.

Default value: `simplib::lookup('simp_options::haveged', { 'default_value'      => false })`

##### <a name="-postfix--server--pki"></a>`pki`

Data type: `Variant[Enum['simp'],Boolean]`

* If 'simp', include SIMP's pki module and use pki::copy to manage
  application certs in /etc/pki/simp_apps/postfix/x509
* If true, do *not* include SIMP's pki module, but still use pki::copy
  to manage certs in /etc/pki/simp_apps/postfix/x509
* If false, do not include SIMP's pki module and do not use pki::copy
  to manage certs.  You will need to appropriately assign a subset of:
  * app_pki_dir
  * app_pki_key
  * app_pki_cert
  * app_pki_ca
  * app_pki_ca_dir

Default value: `simplib::lookup('simp_options::pki', { 'default_value'          => false })`

##### <a name="-postfix--server--app_pki_external_source"></a>`app_pki_external_source`

Data type: `String`

* If pki = 'simp' or true, this is the directory from which certs will be
  copied, via pki::copy.  Defaults to /etc/pki/simp/x509.

* If pki = false, this variable has no effect.

Default value: `simplib::lookup('simp_options::pki::source', { 'default_value'  => '/etc/pki/simp/x509' })`

##### <a name="-postfix--server--app_pki_dir"></a>`app_pki_dir`

Data type: `Stdlib::Absolutepath`

This variable controls the basepath of $app_pki_key, $app_pki_cert,
$app_pki_ca, $app_pki_ca_dir, and $app_pki_crl.
It defaults to /etc/pki/simp_apps/postfix/pki.

Default value: `'/etc/pki/simp_apps/postfix/x509'`

##### <a name="-postfix--server--app_pki_key"></a>`app_pki_key`

Data type: `Stdlib::Absolutepath`

Path and name of the private SSL key file

Default value: `"${app_pki_dir}/private/${facts['fqdn']}.pem"`

##### <a name="-postfix--server--app_pki_cert"></a>`app_pki_cert`

Data type: `Stdlib::Absolutepath`

Path and name of the public SSL certificate

Default value: `"${app_pki_dir}/public/${facts['fqdn']}.pub"`

##### <a name="-postfix--server--app_pki_ca_dir"></a>`app_pki_ca_dir`

Data type: `Stdlib::Absolutepath`

Path to the CA.

Default value: `"${app_pki_dir}/cacerts"`

### <a name="postfix--service"></a>`postfix::service`

Service class called from postfix

## Defined types

### <a name="postfix--alias"></a>`postfix::alias`

Add an alias to the postalias file.
See aliases(5) for details of the internal format.

#### Parameters

The following parameters are available in the `postfix::alias` defined type:

* [`name`](#-postfix--alias--name)
* [`values`](#-postfix--alias--values)

##### <a name="-postfix--alias--name"></a>`name`

The account to receive the alias.

##### <a name="-postfix--alias--values"></a>`values`

Data type: `String[1]`

The RHS values of the postalias file in accordance with
aliases(5).

## Resource types

### <a name="postfix_main_cf"></a>`postfix_main_cf`

Modifies settings in the postfix main.cf configuration file.

#### Properties

The following properties are available in the `postfix_main_cf` type.

##### `value`

The value to which to set the named parameter.

#### Parameters

The following parameters are available in the `postfix_main_cf` type.

* [`name`](#-postfix_main_cf--name)
* [`provider`](#-postfix_main_cf--provider)

##### <a name="-postfix_main_cf--name"></a>`name`

namevar

The parameter to modify.

##### <a name="-postfix_main_cf--provider"></a>`provider`

The specific backend to use for this `postfix_main_cf` resource. You will seldom need to specify this --- Puppet will
usually discover the appropriate provider for your platform.

## Data types

### <a name="Postfix--InetProtocols"></a>`Postfix::InetProtocols`

Allowed inet protocol settings

Alias of `Array[Enum['all','ipv4','ipv6']]`

### <a name="Postfix--ManCiphers"></a>`Postfix::ManCiphers`

Allowed mandatory ciphers

Alias of `Enum['export', 'low', 'medium', 'high', 'null']`

