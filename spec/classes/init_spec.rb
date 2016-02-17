require 'spec_helper'

describe 'postfix' do
  it { is_expected.to create_class('postfix') }

  base_facts = {
    :operatingsystem => 'RedHat',
    :grub_version => '2.0',
    :uid_min => '500'
  }
  let(:facts){base_facts}

  context 'base' do
    it { is_expected.to compile.with_all_deps }
    it { is_expected.to contain_simp_file_line('/root/.bashrc') }
    it { is_expected.to contain_exec('postalias').that_requires('Package[postfix]') }
    it { is_expected.to contain_exec('postalias').that_subscribes_to('File[/etc/aliases]') }
    it { is_expected.to contain_file('/etc/aliases').that_subscribes_to('Concat_build[postfix]') }
    it { is_expected.to contain_package('postfix') }
    it { is_expected.to contain_package('mutt') }
    it { is_expected.to contain_user('postfix') }
    it { is_expected.to contain_file('/root/.muttrc').with({ 'replace' => false }) }
  end

  context 'with_server_enabled' do
    let(:params) {{ :enable_server => true }}
    it {is_expected.to create_class('postfix::server') }
    it { is_expected.to compile.with_all_deps }
  end
end
