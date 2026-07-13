# AGENTS.md

This file provides guidance to AI agents when working with code in this repository.

## What this module does

`simp-postfix` is a SIMP Puppet module that installs and configures the
**Postfix mail server** on Enterprise Linux systems. Including the top-level
`postfix` class installs the `postfix` and `mutt` packages, creates the postfix
users/groups, lays down `/etc/postfix` config files, writes `main.cf` settings,
builds the `/etc/aliases` database, wires root's mail to `mutt` reading a
Maildir, and runs the `postfix` service (`manifests/init.pp`). It is a
full install/config/service module, not a thin package wrapper.

Optionally, setting `postfix::enable_server: true` pulls in `postfix::server`
(`init.pp`), which turns the host into an *externally facing* SMTP server:
it sets `inet_interfaces`, optionally opens the firewall via SIMP `iptables`,
and optionally configures TLS (with PKI cert management and haveged entropy).

### Business logic

Eight classes (`postfix`, `postfix::install`, `postfix::config`,
`postfix::config::main_cf`, `postfix::config::aliases`, `postfix::config::root`,
`postfix::service`, `postfix::server`), one define (`postfix::alias`), one
Puppet function (`postfix::alias_db`), one custom type/provider
(`postfix_main_cf`), and one custom fact (`postfix_alias_database`).

**Public API** (no `assert_private()` — consumed with `include` / as a define):

- **`postfix` (`manifests/init.pp`)** — Public entry class. Parameters
  (`init.pp`):
  - `$main_cf_hash` (`Hash`, **no default**) — required; supplied from module
    data (`data/common.yaml`, deep-merged, see below). Hash of `main.cf`
    settings.
  - `$enable_server` (`Boolean`, default `false`) — gate for `postfix::server`
    (`init.pp`).
  - `$postfix_ensure` / `$mutt_ensure` (`String`) — each default
    `simplib::lookup('simp_options::package_ensure', { 'default_value' => 'installed' })`
    (`init.pp`).
  - `$inet_protocols` (`Postfix::InetProtocols`) — defaults to
    `fact('ipv6_enabled') ? { true => ['all'], default => ['ipv4'] }`
    (`init.pp`).
  - `$aliases` (`Optional[Hash]`, **no default**) — required; from module data
    (`data/common.yaml` sets `postfix::aliases: {}`).

  It `include`s `postfix::install` → `postfix::config` ~> `postfix::service`
  (ordered/notify, `init.pp`); conditionally `include`s `postfix::server`
  notifying the service (`init.pp`); and declares a `postfix::alias`
  resource for each entry of `$aliases` (`init.pp`).
- **`postfix::server` (`manifests/server.pp`)** — Public class for the
  externally facing server. `include`s `postfix` (`server.pp`). Does nothing
  when `$inet_interfaces == ['localhost']` (`server.pp`). Otherwise sets
  `postfix_main_cf { 'inet_interfaces' }` (`server.pp`); if `$firewall`,
  asserts `simp/iptables`, `include`s `iptables`, and opens tcp 25 (plus 587 if
  `$enable_user_connect`) via `iptables::listen::tcp_stateful`
  (`server.pp`); if `$enable_tls`, optionally asserts+includes `haveged`
  (`server.pp`), sets the TLS `postfix_main_cf` settings
  (`server.pp`), and if `$pki` runs `pki::copy { 'postfix' }`
  notifying the service (`server.pp`).
- **`postfix::alias` (`manifests/alias.pp`)** — Public define. Namevar is
  the account; `$values` (`String[1]`) is the RHS. Creates a
  `concat::fragment` (`order => 2`) on `/etc/aliases` with
  `"${name}: ${values}\n"`.

**Private classes** (all call `assert_private()` — internal, not for direct
`include`):

- **`postfix::install` (`manifests/install.pp`, `assert_private()` at
  `install.pp`)** — `group`s `postfix` (gid 89) and `postdrop` (gid 90),
  `package`s `postfix`/`mutt` at the ensure params from the `postfix` class, and
  `user` `postfix` (uid 89). The packages are referenced via
  `$postfix::postfix_ensure` / `$postfix::mutt_ensure` (top-scope class vars).
- **`postfix::config` (`manifests/config.pp`, `assert_private()` at
  `config.pp`)** — `include`s the three `config::*` subclasses and manages the
  `/etc/postfix` directory tree, script/postmap/checks files, spool dirs, and the
  `/var/mail -> /var/spool/mail` symlink. Note: `master.cf`, the postmap files,
  and the checks files are created **empty** — the `content => template(...)`
  lines are commented out (`config.pp`).
- **`postfix::config::main_cf` (`manifests/config/main_cf.pp`,
  `assert_private()` at `main_cf.pp`)** — manages `/etc/postfix/main.cf`, sets
  `postfix_main_cf { 'inet_protocols' }` from `$postfix::inet_protocols`
  (`main_cf.pp`), then iterates `$postfix::main_cf_hash` declaring a
  `postfix_main_cf` per setting — **skipping** any key in the hard-coded
  `$_main_cf_blacklist` (`main_cf.pp`) with a `notify` instead
  (`main_cf.pp`). Array values are joined with commas (`main_cf.pp`).
- **`postfix::config::aliases` (`manifests/config/aliases.pp`,
  `assert_private()` at `aliases.pp`)** — builds `/etc/aliases` via `concat`
  (main fragment from `templates/aliases.erb`, `order => 1`), runs
  `exec { 'postalias' }` (`refreshonly`) on change, and manages the resolved
  alias DB file. It resolves the DB filename by calling the
  `postfix::alias_db()` function on the `alias_database` value dug out of
  `$postfix::main_cf_hash` (`aliases.pp`).
- **`postfix::config::root` (`manifests/config/root.pp`, `assert_private()`
  at `root.pp`)** — adds `alias mail="mutt"` to `/root/.bashrc` via
  `simp_file_line` (`root.pp`) and writes `/root/.muttrc` configured for a
  Maildir (`replace => false`, `root.pp`).
- **`postfix::service` (`manifests/service.pp`, `assert_private()` at
  `service.pp`)** — `service { 'postfix': ensure => running, enable => true }`.

**Supporting code:**

- **`postfix::alias_db` function (`functions/alias_db.pp`)** — given the
  `alias_database` setting (or, if `undef`, the `postfix_alias_database` fact,
  `alias_db.pp`), parses `type:path` and returns the on-disk DB filename per
  type: `hash`/`btree` → `.db`, `dbm`/`sdbm` → `.dir`, `cdb`/`lmdb` →
  `.<type>` (`alias_db.pp`). Returns `undef` (with a `warning`) for a
  malformed or unsupported value.
- **`postfix_main_cf` type/provider (`lib/puppet/type/postfix_main_cf.rb`,
  `lib/puppet/provider/postfix_main_cf/ruby.rb`)** — native type that edits
  individual `main.cf` settings; `autonotify`s `Service['postfix']`
  (`type/postfix_main_cf.rb`). This is the module's own type, not from a
  dependency.
- **`postfix_alias_database` fact (`lib/facter/postfix_alias_database.rb`)** —
  runs `postconf -h alias_database` (confined to hosts with `postconf`).

### Gotchas / non-obvious details

- **`main.cf` settings have two mutually-exclusive sources.** Settings managed
  directly by this module (`inet_protocols` and the `postfix::server` TLS
  settings) are held in `$_main_cf_blacklist` (`main_cf.pp`) and are
  **silently skipped** (only a `notify`) if you also try to set them via
  `postfix::main_cf_hash` — this prevents duplicate `postfix_main_cf` resource
  declarations that would fail compilation (`init.pp`, `main_cf.pp`).
- **`master.cf`, postmap, and content-check files are created empty.** The
  `content => template(...)` lines in `postfix::config` are commented out
  (`config.pp`); the `templates/*.erb` files exist but are **not
  wired in**. These resources only enforce ownership/mode, not content.
- **`$main_cf_hash` and `$aliases` are required with no code default** — they
  come exclusively from module data. `data/common.yaml` provides
  `postfix::main_cf_hash` (with a `deep`/`--` knockout merge via `lookup_options`,
  `common.yaml`) and `postfix::aliases: {}` (`common.yaml`). Without
  data present, the `postfix` class will not compile.
- **`postfix::server` `include`s `postfix`, and `postfix` conditionally
  `include`s `postfix::server`.** This is intentional (either entry point works),
  but it means the server params only take effect when `enable_server` is true
  *or* `postfix::server` is included directly.
- **Firewall and haveged are OPTIONAL dependencies**, guarded by
  `simplib::assert_optional_dependency` + a boolean before any `include`
  (`server.pp`). `simp/iptables` and `simp/haveged` are declared
  only under `metadata.json` `simp.optional_dependencies`, not as hard runtime
  deps. Do not hard-`include` them.
- **`simp/simp_options` is NOT a declared dependency** in `metadata.json`, yet
  the manifests consume the `simp_options::*` seam via `simplib::lookup`
  (provided by `simp/simplib`). `simp_options` is present only as a fixture
  (`.fixtures.yml`). The explicit `default_value` in each call is what lets the
  classes compile without it.
- **No `assert_metadata` gate.** Unlike some SIMP modules, no class calls
  `simplib::assert_metadata`, so applying on an unsupported OS is not blocked at
  compile time by this module.
- **The alias DB filename is derived, not configured directly.**
  `postfix::config::aliases` digs `alias_database` out of `main_cf_hash`, falls
  back to the `postfix_alias_database` fact, and runs it through
  `postfix::alias_db()` to compute the managed file (`aliases.pp`,
  `alias_db.pp`).

## The `simp_options` / `simplib::lookup` seam

This is the module's SIMP feature-toggle seam. All calls (across two manifests):

| File | Key | `default_value` |
|------|-----|-----------------|
| `manifests/init.pp` | `simp_options::package_ensure` | `'installed'` |
| `manifests/init.pp` | `simp_options::package_ensure` | `'installed'` |
| `manifests/server.pp` | `simp_options::firewall` | `false` |
| `manifests/server.pp` | `simp_options::trusted_nets` | `['127.0.0.1']` |
| `manifests/server.pp` | `simp_options::haveged` | `false` |
| `manifests/server.pp` | `simp_options::pki` | `false` |
| `manifests/server.pp` | `simp_options::pki::source` | `'/etc/pki/simp/x509'` |

Keep routing SIMP feature toggles through `simplib::lookup('simp_options::*', {
'default_value' => ... })` with an explicit default rather than assuming
`simp_options` is included.

## Dependencies

Module dependencies (from `metadata.json`):

- `puppetlabs/concat` `>= 6.4.0 < 10.0.0` (provides `concat` / `concat::fragment`
  used to build `/etc/aliases`)
- `simp/simplib` `>= 4.9.0 < 6.0.0` (provides `simplib::lookup`,
  `simplib::assert_optional_dependency`, `simp_file_line`, and the
  `Simplib::Netlist` type)
- `puppetlabs/stdlib` `>= 8.0.0 < 10.0.0` (provides the `Stdlib::Absolutepath`
  type; `join()` is a built-in)

Optional dependencies (from `metadata.json` `simp.optional_dependencies`),
asserted at runtime only when the corresponding feature is enabled:

- `simp/haveged` `>= 0.4.5 < 1.0.0` — included only when TLS + `$haveged`.
- `simp/iptables` `>= 6.5.3 < 8.0.0` — included only when `$firewall`.

`simp/pki` is NOT a declared dependency (not runtime, not optional); the
`postfix::server` TLS branch calls `pki::copy` when `$pki` is set, so PKI must be
provided by the environment. It is present as a fixture (`.fixtures.yml`).

Fixture-only dependencies (from `.fixtures.yml`, for test compilation, not
runtime deps): `auditd`, `augeas_core`, `augeasproviders_core`,
`augeasproviders_grub`, `firewalld`, `logrotate`, `pki`, `rsyslog`,
`simp_firewalld`, `simp_options`, `systemd` (plus the runtime and optional deps).

Runtime requirement (from `metadata.json` `requirements`): `openvox >= 8.0.0 < 9.0.0`.

Supported OS matrix (from `metadata.json`): CentOS 9/10; RedHat 8/9/10;
OracleLinux 8/9/10; Rocky 8/9/10; AlmaLinux 8/9/10.

## Repository layout

- `manifests/init.pp` — the `postfix` public entry class.
- `manifests/install.pp`, `manifests/config.pp`, `manifests/service.pp` — private
  install/config/service classes (all `assert_private()`).
- `manifests/config/main_cf.pp`, `config/aliases.pp`, `config/root.pp` — private
  config subclasses (all `assert_private()`).
- `manifests/server.pp` — the public `postfix::server` class (external SMTP).
- `manifests/alias.pp` — the public `postfix::alias` define.
- `functions/alias_db.pp` — the `postfix::alias_db` Puppet function.
- `types/inetprotocols.pp` — `Postfix::InetProtocols` (`Array[Enum['all','ipv4','ipv6']]`).
- `types/manciphers.pp` — `Postfix::ManCiphers` (`Enum['export','low','medium','high','null']`).
- `lib/puppet/type/postfix_main_cf.rb`, `lib/puppet/provider/postfix_main_cf/ruby.rb`
  — the native `postfix_main_cf` type/provider.
- `lib/facter/postfix_alias_database.rb` — the `postfix_alias_database` fact.
- `templates/aliases.erb` — the main `/etc/aliases` fragment (the **only** wired-in
  template). `templates/master.cf.erb`, `checks.erb`, `postmap.erb` exist but are
  currently commented out in `manifests/config.pp`.
- `data/common.yaml` — module data: `main_cf_hash` (with deep-merge
  `lookup_options`) and `aliases: {}`.
- `hiera.yaml` — module data hierarchy (v5): OS family+major.minor → OS
  family+major → common.
- `metadata.json` — deps, optional deps, OS matrix, OpenVox requirement.
- `spec/classes/*.rb` (`init`, `install`, `config`, `service`, `server`),
  `spec/defines/alias_spec.rb`, `spec/functions/alias_db_spec.rb` — rspec-puppet
  unit tests.
- `spec/acceptance/suites/default/` (`00_base_spec.rb`,
  `01_user_with_existing_maildir_spec.rb`, `02_ipv6_disabled_spec.rb`) — beaker
  acceptance suites; nodesets under `spec/acceptance/nodesets/`.
- `REFERENCE.md` — generated Puppet Strings reference.
- **Acceptance runs in CI:** `.github/workflows/pr_tests.yml` has an
  `acceptance` job (matrix nodes `docker_alma8/9/10`, `docker_centos9/10`,
  `docker_oel8/9/10`, `docker_rocky8/9/10`; RHEL nodes are commented out due to
  subscription requirements) whose final step runs
  `bundle exec rake beaker:suites[default,<node>]`. The nodes are Docker-based
  and the job runs them via **podman** (it starts `podman.socket` and points
  `DOCKER_HOST` at it, `pr_tests.yml`); there is no explicit
  `BEAKER_HYPERVISOR` env in the workflow.

## Common commands

```sh
# Install dependencies
bundle install

# Run all unit tests
bundle exec rake spec

# Run a single class spec
bundle exec rspec spec/classes/server_spec.rb

# Run the function spec
bundle exec rspec spec/functions/alias_db_spec.rb

# Puppet lint
bundle exec rake lint

# Ruby lint
bundle exec rake rubocop

# Regenerate REFERENCE.md from puppet-strings docstrings
puppet strings generate --format markdown --out REFERENCE.md

# Run the default beaker acceptance suite
bundle exec rake beaker:suites[default]
```

Relevant gem pins (from `Gemfile`): `puppetlabs_spec_helper ~> 8.0.0`,
`simp-rake-helpers ~> 5.25.0`, `simp-rspec-puppet-facts ~> 4.0.0`,
`simp-beaker-helpers ~> 2.0.0`. Rubocop is pinned to `~> 1.88.0`. The test group
loads both `openvox` and `puppet` gems, defaulting to the `>= 8 < 9` range.
`spec/spec_helper.rb` uses `require 'puppetlabs_spec_helper/module_spec_helper'`.

## Conventions

- Preserve the `@summary` / `@param` puppet-strings docstrings on the classes,
  the define, and the function — they drive `REFERENCE.md`. Regenerate
  `REFERENCE.md` after changing docs or parameters.
- Keep the private classes `assert_private()`'d — only `postfix`,
  `postfix::server`, and the `postfix::alias` define are public.
- Continue routing SIMP feature toggles through
  `simplib::lookup('simp_options::*', { 'default_value' => ... })` with an
  explicit default rather than assuming `simp_options` is included.
- Guard optional integrations (`iptables`, `haveged`) with
  `simplib::assert_optional_dependency` and a boolean check, as
  `postfix::server` does — don't hard-`include` optional modules.
- When adding a `main.cf` setting that the module manages directly, add it to
  `$_main_cf_blacklist` (`main_cf.pp`) so it can't collide with a
  user-supplied `postfix::main_cf_hash` entry.
- Keep module defaults (`main_cf_hash`, `aliases`) in `data/common.yaml`, not
  hard-coded in the manifests.
- `Gemfile`, `spec/spec_helper.rb`, and `.github/workflows/pr_tests.yml` carry a
  **puppetsync** notice — they are baseline-managed and the next sync overwrites
  local edits. Push changes to those files upstream to the baseline, not here.
- Match the existing 2-space Puppet indentation and aligned-arrow parameter
  style used in `manifests/`.
