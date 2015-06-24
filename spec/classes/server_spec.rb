require 'spec_helper'

describe 'postfix::server' do

  base_facts = {
    :operatingsystem => 'RedHat',
    :grub_version => '2.0',
    :uid_min => '500'
  }
  let(:facts){base_facts}

  it { should create_class('postfix') }
  it { should create_class('postfix::server') }

  context 'base' do
    it { should compile.with_all_deps }
    it { should create_class('iptables') }
    it { should create_class('pki') }
    it { should create_iptables__add_tcp_stateful_listen('allow_postfix').with
      ({
        'dports' => ['25','587']
      })
    }
    it { should create_postfix_main_cf('smtp_use_tls') }
    it { should create_postfix_main_cf('smtp_enforce_tls') }
    it { should create_postfix_main_cf('smtp_tls_mandatory_ciphers').with({ 'value' => 'high' }) }
    it { should contain_pki__copy('/etc/postfix').that_notifies('Service[postfix]') }
  end

  context 'mandatory_cipher_validation' do
    err = 'bad stuff'
    let(:params){{ :mandatory_ciphers => err }}
    it {
      expect {
        should compile.with_all_deps
      }.to raise_error(/does not contain '#{err}'/)
    }
  end

  context 'just_localhost' do
    let(:params){{ :inet_interfaces => ['localhost'] }}

    it { should compile.with_all_deps }
    it { should_not create_class('iptables') }
    it { should_not create_class('pki') }
    it { should_not create_iptables__add_tcp_stateful_listen('allow_postfix') }
    it { should_not create_postfix_main_cf('smtp_use_tls') }
    it { should_not create_postfix_main_cf('smtp_enforce_tls') }
    it { should_not create_postfix_main_cf('smtp_tls_mandatory_ciphers').with({ 'value' => 'high' }) }
    it { should_not contain_pki__copy('/etc/postfix').that_notifies('Service[postfix]') }
  end

  context 'no_iptables' do
    let(:params){{ :enable_iptables => false }}

    it { should compile.with_all_deps }
    it { should_not create_class('iptables') }
    it { should create_class('pki') }
    it { should_not create_iptables__add_tcp_stateful_listen('allow_postfix') }
    it { should create_postfix_main_cf('smtp_use_tls') }
    it { should create_postfix_main_cf('smtp_enforce_tls') }
    it { should create_postfix_main_cf('smtp_tls_mandatory_ciphers').with({ 'value' => 'high' }) }
    it { should contain_pki__copy('/etc/postfix').that_notifies('Service[postfix]') }
  end

  context 'no_enable_user_connect' do
    let(:params){{ :enable_user_connect => false }}

    it { should create_iptables__add_tcp_stateful_listen('allow_postfix').with({ 'dports' => '25' }) }
  end

  context 'no_enable_tls' do
    let(:params){{ :enable_tls => false }}

    it { should compile.with_all_deps }
    it { should create_class('iptables') }
    it { should_not create_class('pki') }
    it { should create_iptables__add_tcp_stateful_listen('allow_postfix') }
    it { should_not create_postfix_main_cf('smtp_use_tls') }
    it { should_not create_postfix_main_cf('smtp_enforce_tls') }
    it { should_not create_postfix_main_cf('smtp_tls_mandatory_ciphers').with({ 'value' => 'high' }) }
    it { should_not contain_pki__copy('/etc/postfix').that_notifies('Service[postfix]') }
  end

  context 'no_enforce_tls' do
    let(:params){{ :enforce_tls => false }}

    it { should compile.with_all_deps }
    it { should create_class('iptables') }
    it { should create_class('pki') }
    it { should create_iptables__add_tcp_stateful_listen('allow_postfix') }
    it { should create_postfix_main_cf('smtp_use_tls') }
    it { should_not create_postfix_main_cf('smtp_enforce_tls') }
    it { should create_postfix_main_cf('smtp_tls_mandatory_ciphers').with({ 'value' => 'high' }) }
    it { should contain_pki__copy('/etc/postfix').that_notifies('Service[postfix]') }
  end

  context 'no_enable_simp_pki' do
    let(:params){{ :enable_simp_pki => false }}

    it { should compile.with_all_deps }
    it { should create_class('iptables') }
    it { should_not create_class('pki') }
    it { should create_iptables__add_tcp_stateful_listen('allow_postfix') }
    it { should create_postfix_main_cf('smtp_use_tls') }
    it { should create_postfix_main_cf('smtp_enforce_tls') }
    it { should create_postfix_main_cf('smtp_tls_mandatory_ciphers').with({ 'value' => 'high' }) }
    it { should_not contain_pki__copy('/etc/postfix').that_notifies('Service[postfix]') }
  end
end
