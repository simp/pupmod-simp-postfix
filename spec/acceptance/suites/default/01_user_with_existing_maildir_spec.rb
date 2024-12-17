require 'spec_helper_acceptance'

test_name 'postfix'

describe 'postfix' do
  hosts.each do |host|
    context 'basic postfix install' do
      let(:manifest) do
        <<-EOS
          include '::postfix'
        EOS
      end
      let(:hieradata) do
        {
          'simp_options::pki::source' => '/etc/pki/simp-testing/pki/'
        }
      end

      let(:test_user) { 'test_user' }

      it 'works with no errors' do
        set_hieradata_on(host, hieradata)
        apply_manifest_on(host, manifest, catch_failures: true)
      end

      it 'is idempotent' do
        apply_manifest_on(host, manifest, catch_changes: true)
      end

      it 'has a test user' do
        on(host, %(puppet resource user #{test_user} ensure=present))
      end

      it 'sends mail to the test user' do
        host.install_package('mailx')
        on(host, %(echo 'Test' | mail -s 'Test Message' #{test_user}))
      end

      it 'does not have any changes during a puppet run' do
        apply_manifest_on(host, manifest, catch_changes: true)
      end
    end
  end
end
