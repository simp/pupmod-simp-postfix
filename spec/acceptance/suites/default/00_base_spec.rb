require 'spec_helper_acceptance'

test_name 'postfix'

describe 'postfix' do
  hosts.each do |host|
    context "on #{host}" do
      context 'noop mode' do
        it 'applies with no errors' do
          on(host, 'puppet resource package postfix ensure=absent')
          apply_manifest_on(host, <<~EOS, catch_failures: true, noop: true)
            include 'postfix'
          EOS
        end
      end

      context 'basic postfix install' do
        let(:manifest) do
          <<~EOS
            include 'postfix'
          EOS
        end

        let(:hieradata) do
          {
            'simp_options::pki::source' => '/etc/pki/simp-testing/pki/',
          }
        end

        it 'works with no errors' do
          set_hieradata_on(host, hieradata)
          apply_manifest_on(host, manifest, catch_failures: true)
        end

        it 'is idempotent' do
          apply_manifest_on(host, manifest, catch_changes: true)
        end

        it 'is installed' do
          on(host, 'puppet resource package postfix') do |result|
            expect(result.stdout).not_to match(%r{ensure\s*=> 'absent'})
          end
        end

        it 'is running' do
          on(host, 'puppet resource service postfix') do |result|
            expect(result.stdout).to match(%r{ensure\s*=> 'running'})
            expect(result.stdout).to match(%r{enable\s*=> 'true'})
          end
        end

        it 'adds postfix::main_cf_hash options to file' do
          result = shell('cat /etc/postfix/main.cf').stdout
          expect(result).to include('smtpd_client_restrictions = permit_mynetworks,reject')
        end
      end
    end
  end
end
