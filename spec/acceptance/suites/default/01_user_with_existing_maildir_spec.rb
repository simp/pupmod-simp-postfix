require 'spec_helper_acceptance'

test_name 'postfix'

describe 'postfix' do
  let(:manifest) {
    <<-EOS
      include '::postfix'
    EOS
  }

  let(:test_user) { 'test_user' }

  hosts.each do |host|
    context "basic postfix install" do
      it 'should work with no errors' do
        apply_manifest_on(host, manifest, :catch_failures => true)
      end

      it 'should be idempotent' do
        apply_manifest_on(host, manifest, :catch_changes => true)
      end

      it 'should have a test user' do
        on(host, %(puppet resource user #{test_user} ensure=present))
      end

      it 'should send mail to the test user' do
        host.install_package('mailx')
        on(host, %(echo 'Test' | mail -s 'Test Message' #{test_user}))
      end

      it 'should not have any changes during a puppet run' do
        apply_manifest_on(host, manifest, :catch_changes => true)
      end
    end
  end
end
