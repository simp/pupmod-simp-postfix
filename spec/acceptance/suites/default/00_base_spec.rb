require 'spec_helper_acceptance'

test_name 'postfix'

describe 'postfix' do
  hosts.each do |host|

    context "basic postfix install" do
      let(:manifest) {
        <<-EOS
          include '::postfix'
        EOS
      }
      let(:hieradata) {{
        'simp_options::pki::source' => '/etc/pki/simp-testing/pki/'
      }}

      it 'should work with no errors' do
        set_hieradata_on(host, hieradata)
        apply_manifest_on(host, manifest, :catch_failures => true)
      end

      it 'should be idempotent' do
        apply_manifest_on(host, manifest, :catch_changes => true)
      end

      it 'should be installed' do
        on(host, 'puppet resource package postfix') do
          expect(stdout).to_not match(/ensure => 'absent'/)
        end
      end

      it 'should be running' do
        on(host, 'puppet resource service postfix') do
          expect(stdout).to match(/ensure => 'running'/)
          expect(stdout).to match(/enable => 'true'/)
        end
      end
    end
  end
end
