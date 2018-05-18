require 'spec_helper'

describe 'postfix::service' do
  context 'supported operating systems' do
    on_supported_os.each do |os, facts|
      let(:facts) { facts }

      context 'postfix service' do
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
