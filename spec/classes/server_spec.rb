require 'spec_helper'

describe 'postfix::server' do
  context 'supported operating systems' do
    on_supported_os.each do |os, os_facts|
      let(:facts) { os_facts }

      it { is_expected.to create_class('postfix::server') }

      context 'with default parameters' do
        it { is_expected.to compile.with_all_deps }
        it { is_expected.not_to create_class('iptables') }
        it { is_expected.not_to create_iptables__listen__tcp_stateful('allow_postfix') }
        it { is_expected.to create_postfix_main_cf('smtp_use_tls') }
        it { is_expected.to create_postfix_main_cf('smtp_enforce_tls') }
        it { is_expected.to create_postfix_main_cf('smtp_tls_mandatory_ciphers').with({ 'value' => 'high' }) }
        it { is_expected.to create_postfix_main_cf('smtp_tls_cert_file').with(:value => "/etc/pki/simp_apps/postfix/x509/public/#{facts[:fqdn]}.pub")}
        it { is_expected.to create_postfix_main_cf('smtp_tls_CApath').with(:value => "/etc/pki/simp_apps/postfix/x509/cacerts")}
        it { is_expected.to create_postfix_main_cf('smtp_tls_key_file').with(:value => "/etc/pki/simp_apps/postfix/x509/private/#{facts[:fqdn]}.pem")}
        it { is_expected.to_not contain_class('pki')}
        it { is_expected.to_not contain_pki__copy('postfix').that_notifies('Service[postfix]') }
        it { is_expected.not_to contain_class('haveged') }
      end

      context 'just_localhost' do
        let(:params){{ :inet_interfaces => ['localhost'] }}

        it { is_expected.to compile.with_all_deps }
        it { is_expected.not_to create_class('iptables') }
        it { is_expected.not_to create_iptables__listen__tcp_stateful('allow_postfix') }
        it { is_expected.not_to create_postfix_main_cf('smtp_use_tls') }
        it { is_expected.not_to create_postfix_main_cf('smtp_enforce_tls') }
        it { is_expected.not_to create_postfix_main_cf('smtp_tls_mandatory_ciphers').with({ 'value' => 'high' }) }
        it { is_expected.not_to create_class('pki') }
        it { is_expected.not_to contain_pki__copy('postfix').that_notifies('Service[postfix]') }
        it { is_expected.to_not contain_class('haveged') }
      end

      context 'iptables' do
        let(:params){{ :firewall => true }}

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to create_class('iptables') }
        it { is_expected.to create_iptables__listen__tcp_stateful('allow_postfix').with
          ({
            'dports' => ['25','587']
          })
        }
        it { is_expected.to create_postfix_main_cf('smtp_use_tls') }
        it { is_expected.to create_postfix_main_cf('smtp_enforce_tls') }
        it { is_expected.to create_postfix_main_cf('smtp_tls_mandatory_ciphers').with({ 'value' => 'high' }) }
        it { is_expected.to_not create_class('pki') }
        it { is_expected.to_not contain_pki__copy('postfix').that_notifies('Service[postfix]') }
      end

      context 'no_enable_user_connect' do
        let(:params) {{
          :enable_user_connect => false,
          :firewall => true
        }}

        it { is_expected.to create_iptables__listen__tcp_stateful('allow_postfix').with({ 'dports' => '25' }) }
      end

      context 'no_enable_tls' do
        let(:params){{
          :firewall => true,
          :enable_tls => false
        }}

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to create_class('iptables') }
        it { is_expected.to create_iptables__listen__tcp_stateful('allow_postfix') }
        it { is_expected.not_to create_postfix_main_cf('smtp_use_tls') }
        it { is_expected.not_to create_postfix_main_cf('smtp_enforce_tls') }
        it { is_expected.not_to create_postfix_main_cf('smtp_tls_mandatory_ciphers').with({ 'value' => 'high' }) }
        it { is_expected.to_not create_postfix_main_cf('smtp_tls_cert_file')}
        it { is_expected.to_not create_postfix_main_cf('smtp_tls__CApath')}
        it { is_expected.to_not create_postfix_main_cf('smtp_tls_key_file')}
        it { is_expected.not_to create_class('pki') }
        it { is_expected.not_to contain_pki__copy('postfix').that_notifies('Service[postfix]') }
        it { is_expected.to_not contain_class('haveged') }
      end

      context 'no_enforce_tls' do
        let(:params){{
          :firewall => true,
          :enforce_tls => false
        }}

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to create_class('iptables') }
        it { is_expected.to create_iptables__listen__tcp_stateful('allow_postfix') }
        it { is_expected.to create_postfix_main_cf('smtp_use_tls') }
        it { is_expected.not_to create_postfix_main_cf('smtp_enforce_tls') }
        it { is_expected.to create_postfix_main_cf('smtp_tls_mandatory_ciphers').with({ 'value' => 'high' }) }
        it { is_expected.to_not create_class('pki') }
        it { is_expected.to_not contain_pki__copy('postfix').that_notifies('Service[postfix]') }
        it { is_expected.not_to contain_class('haveged') }
      end

      context 'with pki => simp' do
        let(:params){{ :pki => 'simp' }}

        it { is_expected.to compile.with_all_deps }
        it { is_expected.not_to create_class('iptables') }
        it { is_expected.not_to create_iptables__listen__tcp_stateful('allow_postfix') }
        it { is_expected.to create_postfix_main_cf('smtp_use_tls') }
        it { is_expected.to create_postfix_main_cf('smtp_enforce_tls') }
        it { is_expected.to create_postfix_main_cf('smtp_tls_mandatory_ciphers').with({ 'value' => 'high' }) }
        it { is_expected.to create_class('pki') }
        it { is_expected.to contain_pki__copy('postfix').that_notifies('Service[postfix]') }
        it { is_expected.to create_file('/etc/pki/simp_apps/postfix/x509')}
        it { is_expected.not_to contain_class('haveged') }
      end

      context 'with haveged => true' do
        let(:params) {{:haveged => true}}
        it { is_expected.to contain_class('haveged') }
      end

    end
  end
end
