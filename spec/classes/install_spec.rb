require 'spec_helper'

describe 'postfix::install' do
  context 'supported operating systems' do
    on_supported_os.each do |os, facts|
      let(:facts) { facts }

      context 'base' do
        let(:pre_condition) { 'include postfix'}
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_package('postfix') }
        it { is_expected.to contain_package('mutt') }
        it { is_expected.to contain_user('postfix') }
      end

    end
  end
end
