Summary: Postfix Puppet Module
Name: pupmod-postfix
Version: 4.1.0
Release: 4
License: Apache License, Version 2.0
Group: Applications/System
Source: %{name}-%{version}-%{release}.tar.gz
Buildroot: %{_tmppath}/%{name}-%{version}-%{release}-buildroot
Requires: pupmod-common >= 2.1.2-2
Requires: pupmod-concat >= 2.0.0-0
Requires: pupmod-iptables >= 2.0.0-0
Requires: pupmod-rsync >= 2.0.0-0
Requires: puppet >= 3.3.0
Requires: puppetlabs-stdlib
Buildarch: noarch
Requires: simp-bootstrap >= 4.2.0
Obsoletes: pupmod-postfix-test

Prefix: /etc/puppet/environments/simp/modules

%description
This Puppet module provides the capability to configure a localhost oriented
mail server for your systems.

Domain mail server capability is not yet supported.

%prep
%setup -q

%build

%install
[ "%{buildroot}" != "/" ] && rm -rf %{buildroot}

mkdir -p %{buildroot}/%{prefix}/postfix

dirs='files lib manifests templates'
for dir in $dirs; do
  test -d $dir && cp -r $dir %{buildroot}/%{prefix}/postfix
done

mkdir -p %{buildroot}/usr/share/simp/tests/modules/postfix

%clean
[ "%{buildroot}" != "/" ] && rm -rf %{buildroot}

mkdir -p %{buildroot}/%{prefix}/postfix

%files
%defattr(0640,root,puppet,0750)
%{prefix}/postfix

%post
#!/bin/sh

if [ -d %{prefix}/postfix/plugins ]; then
  /bin/mv %{prefix}/postfix/plugins %{prefix}/postfix/plugins.bak
fi

%postun
# Post uninstall stuff

%changelog
* Thu Feb 19 2015 Trevor Vaughan <tvaughan@onyxpoint.com> - 4.1.0-4
- Migrated to the new 'simp' environment.

* Fri Jan 16 2015 Trevor Vaughan <tvaughan@onyxpoint.com> - 4.1.0-3
- Changed puppet-server requirement to puppet

* Tue Jun 24 2014 Nick Markowski <nmarkowski@keywcorp.com> - 4.1.0-2
- Changed all checksums to sha256 instead of md5 in an effort to
  enable FIPS.

* Tue Mar 18 2014 Trevor Vaughan <tvaughan@onyxpoint.com> - 4.1.0-1
- Added rspec tests.
- Removed the postfix::conf::main_cf::set define and replaced it with the
  postfix_main_cf native type.
- Updated all classes to be Puppet3 and Hiera compatible.
- Fleshed out the postfix::server class in such a way that it now provides a
  fully functioning server when called.

* Tue Jan 28 2014 Kendall Moore <kmoore@keywcorp.com> 4.1.0-0
- Update to remove warnings about IPTables not being detected. This is a
  nuisance when allowing other applications to manage iptables legitimately.

* Fri Jul 26 2013 Trevor Vaughan <tvaughan@onyxpoint.com> - 2.0.1-5
- Updated to use simp_file_line instead of file_line from stdlib.

* Tue Jan 15 2013 Maintenance
2.0.1-4
- Created a Cucumber test which installs and confiugres a postfix server and checks
  to make sure a user is created and the postfix service is running.

* Mon Aug 20 2012 Maintenance
2.0.1-3
- Ensure that /etc/postfix is world readable.

* Wed Apr 11 2012 Maintenance
2.0.1-2
- Now use the Puppet Labs stdlib function 'file_line' instead of
  'functions::append_if_no_such_line'
- Moved mit-tests to /usr/share/simp...
- Updated pp files to better meet Puppet's recommended style guide.

* Fri Mar 02 2012 Maintenance
2.0.1-1
- Improved test stubs.

* Wed Feb 22 2012 Maintenance
2.0.1-0
- Postfix now no longer attempts to copy the content of any file into
  place except those that you piece together with the aliases
  commands. It was simply too restrictive for successful mail server
  usage.
  was getting copied into /etc/postfix.
- Loosened up some of the permissions to allow people to do crazy things in
  their /etc/postfix directory manually if they so choose.

* Mon Dec 26 2011 Maintenance
2.0.0-4
- Updated the spec file to not require a separate file list.

* Mon Dec 05 2011 Maintenance
2.0.0-3
- Removed the conflicting 'tidy' statement from init.pp and replaced it with a
  'purge' in the associated file statment.

* Mon Oct 10 2011 Maintenance
2.0.0-2
- Modified all multi-line exec statements to act as defined on a single line to
  address bugs in puppet 2.7.5

* Mon Apr 18 2011 Maintenance - 2.0.0-1
- Changed puppet://$puppet_server/ to puppet:///
- Changed all instances of defined(Class['foo']) to defined('foo') per the
  directions from the Puppet mailing list.
- Updated to use concat_build and concat_fragment types

* Tue Jan 11 2011 Maintenance
2.0.0-0
- Refactored for SIMP-2.0.0-alpha release

* Tue Oct 26 2010 Maintenance - 1-1
- Converting all spec files to check for directories prior to copy.

* Mon May 24 2010 Maintenance
1.0-0
- Doc update and code refactor.

* Thu Jan 28 2010 Maintenance
0.1-11
- Root's .muttrc now properly points to /var/spool/mail/root for newly delivered
  mail and pulls it into a Maildir in ~root/Maildir.

* Wed Dec 16 2009 Maintenance
0.1-10
- Added a conf::main_cf::set define that calls the postconf application to set
  any value in main.cf that you like.

* Mon Dec 04 2009 Maintenance
0.1-9
- Removed dependence on rsync.
- Added templates for files that should be templated.
- Moved static files into 'files' section of the module.
