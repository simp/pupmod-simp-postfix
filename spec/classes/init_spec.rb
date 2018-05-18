require 'spec_helper'

describe 'postfix' do
  context 'supported operating systems' do
    on_supported_os.each do |os, facts|
      let(:facts) { facts }

      context 'base' do
        it { is_expected.to create_class('postfix::install') }
        it { is_expected.to create_class('postfix::config').that_requires('Class[postfix::install]') }
        it { is_expected.to create_class('postfix::service').that_requires('Class[postfix::config]') }
        it { is_expected.to compile.with_all_deps }
      end

      context 'with_server_enabled' do
        let(:params) {{ :enable_server => true }}
        it {is_expected.to create_class('postfix::server') }
        it { is_expected.to compile.with_all_deps }
      end

    end
  end
end
