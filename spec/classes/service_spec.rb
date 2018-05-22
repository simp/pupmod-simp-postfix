require 'spec_helper'

describe 'postfix::service' do
  context 'supported operating systems' do
    on_supported_os.each do |os, os_facts|
      let(:facts) { os_facts }

      context 'default postfix class parameters' do
        let(:pre_condition) { 'include postfix' }
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_service('postfix').with({
          'ensure' => 'running',
          'enable' => true,
          'hasrestart' => true,
          'hasstatus' => true
        })}
      end
    end
  end
end
