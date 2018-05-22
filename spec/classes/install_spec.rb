require 'spec_helper'

describe 'postfix::install' do
  context 'supported operating systems' do
    on_supported_os.each do |os, facts|
      let(:facts) { facts }

      context 'default postfix class parameters' do
        let(:pre_condition) { 'include postfix' }
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_group('postfix') }
        it { is_expected.to contain_group('postdrop') }
        it { is_expected.to contain_user('postfix') }
        it { is_expected.to contain_package('postfix').with_ensure('installed') }
        it { is_expected.to contain_package('mutt').with_ensure('installed') }
      end

      context 'postfix class with ensure parameters set' do
        let(:pre_condition) { <<EOM
class { 'postfix':
  postfix_ensure => 'latest',
  mutt_ensure    => '1.2.3'
}
EOM
        }

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_package('postfix').with_ensure('latest') }
        it { is_expected.to contain_package('mutt').with_ensure('1.2.3') }
      end
    end
  end
end
