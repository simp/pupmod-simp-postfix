require 'spec_helper'

describe 'postfix::config' do
  context 'supported operating systems' do
    on_supported_os.each do |os, os_facts|
      let(:facts) { os_facts }

      context 'default postfix class parameters' do
        let(:pre_condition) { 'include postfix' }

        it { is_expected.to compile.with_all_deps }

        it { is_expected.to create_class('postfix::config::main_cf') }
        it { is_expected.to contain_file('/etc/postfix/main.cf') }
        it { is_expected.to contain_postfix_main_cf('inet_protocols') }

        it { is_expected.to create_class('postfix::config::aliases') }
        it { is_expected.to contain_exec('postalias').that_subscribes_to('Concat[/etc/aliases]') }
        it { is_expected.to contain_concat('/etc/aliases') }
        it { is_expected.to contain_concat__fragment('main.alias') }
        it { is_expected.to contain_file('/etc/aliases.db').that_subscribes_to('Exec[postalias]') }

        [
          '/etc/postfix',
          '/etc/postfix/postfix-script',
          '/etc/postfix/post-install',
          '/etc/postfix/master.cf',
          '/etc/postfix/access',
          '/etc/postfix/canonical',
          '/etc/postfix/generic',
          '/etc/postfix/relocated',
          '/etc/postfix/transport',
          '/etc/postfix/virtual',
          '/etc/postfix/header_checks',
          '/etc/postfix/mime_header_checks',
          '/etc/postfix/nested_header_checks',
          '/etc/postfix/body_checks',
          '/usr/libexec/postfix',
          '/var/spool/postfix',
          '/var/spool/mail',
          '/var/mail'
        ].each do |file|
          it { is_expected.to contain_file(file) }
        end

        it { is_expected.to create_class('postfix::config::root') }
        it { is_expected.to contain_simp_file_line('/root/.bashrc') }
        it { is_expected.to contain_file('/root/.muttrc').with({ 'replace' => false }) }
      end

      context 'postfix class with main_cf_hash set' do
        let(:pre_condition) {<<-EOM.gsub(/^\s+/,'')
          class { 'postfix':
            main_cf_hash => {
              'address_verify_cache_cleanup_interval' => {
                'value' => '5h'
              },
              'allow_mail_to_commands' => {
                'value' => [ 'alias', 'forward', 'include' ]
              }
            }
          }
          EOM
        }

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_postfix_main_cf('inet_protocols') }
        it { is_expected.to contain_postfix_main_cf('address_verify_cache_cleanup_interval').with_value('5h') }
        it { is_expected.to contain_postfix_main_cf('allow_mail_to_commands').with_value('alias,forward,include') }
      end

      context 'postfix class with main_cf_hash set with dupes' do
        let(:pre_condition) {<<-EOM.gsub(/^\s+/,'')
          class { 'postfix':
            main_cf_hash => {
              'address_verify_cache_cleanup_interval' => {
                'value' => '5h'
              },
              'allow_mail_to_commands' => {
                'value' => [ 'alias', 'forward', 'include' ]
              },
              'inet_protocols' => {
                'value' => ['hello']
              }
            }
          }
          EOM
        }

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_postfix_main_cf('inet_protocols') }
        it { is_expected.to contain_postfix_main_cf('address_verify_cache_cleanup_interval').with_value('5h') }
        it { is_expected.to contain_postfix_main_cf('allow_mail_to_commands').with_value('alias,forward,include') }
        it { is_expected.to contain_notify('postfix::main_cf_hash: inet_protocols is already managed by this module, skipping.') }
      end

      context 'postfix class when ipv6_enabled fact false ' do
        let(:pre_condition) { 'include postfix' }
        let(:facts) { os_facts.merge({:ipv6_enabled => false}) }
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_postfix_main_cf('inet_protocols').with_value('ipv4') }

      end

      context 'postfix class when ipv6_enabled fact true ' do
        let(:pre_condition) { 'include postfix' }
        let(:facts) { os_facts.merge({:ipv6_enabled => true}) }
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_postfix_main_cf('inet_protocols').with_value('all') }
      end
    end
  end
end
