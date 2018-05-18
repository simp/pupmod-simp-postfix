require 'spec_helper'

describe 'postfix::config' do
  context 'supported operating systems' do
    on_supported_os.each do |os, facts|
      let(:facts) { facts }

      context 'postfix config with default params' do
        let(:pre_condition) {'class { "postfix": main_cf_hash => { } }'}
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_simp_file_line('/root/.bashrc') }
        it { is_expected.to contain_exec('postalias').that_subscribes_to('Concat[/etc/aliases]') }
        it { is_expected.to contain_concat('/etc/aliases') }
        it { is_expected.to contain_concat__fragment('main.alias') }
        it { is_expected.to contain_file('/root/.muttrc').with({ 'replace' => false }) }
        it { is_expected.to create_class('postfix::config::main_cf') }
        it { is_expected.to contain_postfix_main_cf('inet_protocols') }
      end

    end
  end
end
