require 'spec_helper'

describe 'postfix::server' do

  base_facts = {
    :operatingsystem => 'RedHat',
    :grub_version => '2.0',
    :uid_min => '500'
  }
  let(:facts){base_facts}

  it { is_expected.to create_class('postfix') }
  it { is_expected.to create_class('postfix::server') }

  context 'base' do
    it { is_expected.to compile.with_all_deps }
    it { is_expected.to create_class('iptables') }
    it { is_expected.to create_class('pki') }
    it { is_expected.to create_iptables__add_tcp_stateful_listen('allow_postfix').with
      ({
        'dports' => ['25','587']
      })
    }
    it { is_expected.to create_postfix_main_cf('smtp_use_tls') }
    it { is_expected.to create_postfix_main_cf('smtp_enforce_tls') }
    it { is_expected.to create_postfix_main_cf('smtp_tls_mandatory_ciphers').with({ 'value' => 'high' }) }
    it { is_expected.to contain_pki__copy('/etc/postfix').that_notifies('Service[postfix]') }
  end

  context 'mandatory_cipher_validation' do
    err = 'bad stuff'
    let(:params){{ :mandatory_ciphers => err }}
    it {
      expect {
        is_expected.to compile.with_all_deps
      }.to raise_error(/does not contain '#{err}'/)
    }
  end

  context 'just_localhost' do
    let(:params){{ :inet_interfaces => ['localhost'] }}

    it { is_expected.to compile.with_all_deps }
    it { is_expected.not_to create_class('iptables') }
    it { is_expected.not_to create_class('pki') }
    it { is_expected.not_to create_iptables__add_tcp_stateful_listen('allow_postfix') }
    it { is_expected.not_to create_postfix_main_cf('smtp_use_tls') }
    it { is_expected.not_to create_postfix_main_cf('smtp_enforce_tls') }
    it { is_expected.not_to create_postfix_main_cf('smtp_tls_mandatory_ciphers').with({ 'value' => 'high' }) }
    it { is_expected.not_to contain_pki__copy('/etc/postfix').that_notifies('Service[postfix]') }
  end

  context 'no_iptables' do
    let(:params){{ :enable_iptables => false }}

    it { is_expected.to compile.with_all_deps }
    it { is_expected.not_to create_class('iptables') }
    it { is_expected.to create_class('pki') }
    it { is_expected.not_to create_iptables__add_tcp_stateful_listen('allow_postfix') }
    it { is_expected.to create_postfix_main_cf('smtp_use_tls') }
    it { is_expected.to create_postfix_main_cf('smtp_enforce_tls') }
    it { is_expected.to create_postfix_main_cf('smtp_tls_mandatory_ciphers').with({ 'value' => 'high' }) }
    it { is_expected.to contain_pki__copy('/etc/postfix').that_notifies('Service[postfix]') }
  end

  context 'no_enable_user_connect' do
    let(:params){{ :enable_user_connect => false }}

    it { is_expected.to create_iptables__add_tcp_stateful_listen('allow_postfix').with({ 'dports' => '25' }) }
  end

  context 'no_enable_tls' do
    let(:params){{ :enable_tls => false }}

    it { is_expected.to compile.with_all_deps }
    it { is_expected.to create_class('iptables') }
    it { is_expected.not_to create_class('pki') }
    it { is_expected.to create_iptables__add_tcp_stateful_listen('allow_postfix') }
    it { is_expected.not_to create_postfix_main_cf('smtp_use_tls') }
    it { is_expected.not_to create_postfix_main_cf('smtp_enforce_tls') }
    it { is_expected.not_to create_postfix_main_cf('smtp_tls_mandatory_ciphers').with({ 'value' => 'high' }) }
    it { is_expected.not_to contain_pki__copy('/etc/postfix').that_notifies('Service[postfix]') }
  end

  context 'no_enforce_tls' do
    let(:params){{ :enforce_tls => false }}

    it { is_expected.to compile.with_all_deps }
    it { is_expected.to create_class('iptables') }
    it { is_expected.to create_class('pki') }
    it { is_expected.to create_iptables__add_tcp_stateful_listen('allow_postfix') }
    it { is_expected.to create_postfix_main_cf('smtp_use_tls') }
    it { is_expected.not_to create_postfix_main_cf('smtp_enforce_tls') }
    it { is_expected.to create_postfix_main_cf('smtp_tls_mandatory_ciphers').with({ 'value' => 'high' }) }
    it { is_expected.to contain_pki__copy('/etc/postfix').that_notifies('Service[postfix]') }
  end

  context 'no_enable_simp_pki' do
    let(:params){{ :enable_simp_pki => false }}

    it { is_expected.to compile.with_all_deps }
    it { is_expected.to create_class('iptables') }
    it { is_expected.not_to create_class('pki') }
    it { is_expected.to create_iptables__add_tcp_stateful_listen('allow_postfix') }
    it { is_expected.to create_postfix_main_cf('smtp_use_tls') }
    it { is_expected.to create_postfix_main_cf('smtp_enforce_tls') }
    it { is_expected.to create_postfix_main_cf('smtp_tls_mandatory_ciphers').with({ 'value' => 'high' }) }
    it { is_expected.not_to contain_pki__copy('/etc/postfix').that_notifies('Service[postfix]') }
  end
end
