require 'spec_helper'

describe 'postfix' do
  it { should create_class('postfix') }

  base_facts = {
    :operatingsystem => 'RedHat',
    :grub_version => '2.0',
    :uid_min => '500'
  }
  let(:facts){base_facts}

  context 'base' do
    it { should compile.with_all_deps }
    it { should contain_simp_file_line('/root/.bashrc') }
    it { should contain_exec('postalias').that_requires('Package[postfix]') }
    it { should contain_exec('postalias').that_subscribes_to('File[/etc/aliases]') }
    it { should contain_file('/etc/aliases').that_subscribes_to('Concat_build[postfix]') }
    it { should contain_package('postfix') }
    it { should contain_package('mutt') }
    it { should contain_user('postfix') }
    it { should contain_file('/root/.muttrc').with({ 'replace' => false }) }
  end

  context 'with_server_enabled' do
    let(:params) {{ :enable_server => true }}
    it {should create_class('postfix::server') }
    it { should compile.with_all_deps }
  end
end
