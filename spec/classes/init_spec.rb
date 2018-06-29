require 'spec_helper'

describe 'postfix' do
  context 'supported operating systems' do
    on_supported_os.each do |os, facts|
      let(:facts) { facts }

      context 'default parameters' do
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to create_class('postfix::install') }
        it { is_expected.to create_class('postfix::config').that_requires('Class[postfix::install]') }
        it { is_expected.to create_class('postfix::config').that_notifies('Class[postfix::service]') }
      end

      context 'with server_enabled=true' do
        let(:params) {{ :enable_server => true }}
        it { is_expected.to compile.with_all_deps }
        it {is_expected.to create_class('postfix::server').that_notifies('Class[postfix::service]') }
      end

    end
  end
end
