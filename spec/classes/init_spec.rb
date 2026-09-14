require 'spec_helper'

describe 'postfix' do
  context 'supported operating systems' do
    on_supported_os.each do |os, facts|
      context "on #{os}" do
        let(:facts) { facts }

        context 'default parameters' do
          it { is_expected.to compile.with_all_deps }
          it { is_expected.to create_class('postfix::install') }
          it { is_expected.to create_class('postfix::config').that_requires('Class[postfix::install]') }
          it { is_expected.to create_class('postfix::config').that_notifies('Class[postfix::service]') }

          # postfix::config 'contain's main_cf, so the chain above reaches it.
          # main.cf needs 'postconf' from the package and has to restart the
          # daemon.
          it do
            is_expected.to create_class('postfix::config::main_cf')
              .that_requires('Class[postfix::install]')
          end
          it do
            is_expected.to create_class('postfix::config::main_cf')
              .that_notifies('Class[postfix::service]')
          end
        end

        context 'with a main_cf_hash setting' do
          let(:params) do
            { main_cf_hash: { 'inet_interfaces' => { 'value' => 'loopback-only' } } }
          end

          it { is_expected.to compile.with_all_deps }
          it do
            is_expected.to contain_postfix_main_cf('inet_interfaces')
              .with_value('loopback-only')
              .that_requires('Package[postfix]')
          end
          it do
            is_expected.to contain_postfix_main_cf('inet_interfaces')
              .that_notifies('Service[postfix]')
          end
        end

        context 'with server_enabled=true' do
          let(:params) { { enable_server: true } }

          it { is_expected.to compile.with_all_deps }
          it { is_expected.to create_class('postfix::server').that_notifies('Class[postfix::service]') }
        end

        context 'with aliases defined' do
          let(:params) do
            {
              aliases: {
                'root' => 'system.administrator@mail.mil',
                'foo.bar' => 'fbar, fbar@example.com',
              },
            }
          end

          it { is_expected.to compile.with_all_deps }
          it do
            is_expected.to contain_concat__fragment('postfix+root.alias').with(
              'content' => "root: system.administrator@mail.mil\n",
            )
          end
          it do
            is_expected.to contain_concat__fragment('postfix+foo.bar.alias').with(
              'content' => "foo.bar: fbar, fbar@example.com\n",
            )
          end
        end
      end
    end
  end
end
