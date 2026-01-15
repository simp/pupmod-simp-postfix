require 'spec_helper_acceptance'

test_name 'postfix'

describe 'postfix' do
  hosts.each do |host|
    context 'with ipv6 explicitly disabled' do
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

      # SIMP-4418
      it 'disables ipv6 on the system, but not in the kernel' do
        on(host, 'sysctl -w net.ipv6.conf.all.disable_ipv6=1')
        on(host, 'sysctl -w net.ipv6.conf.default.disable_ipv6=1')
        on(host, 'sysctl -p')
      end

      it 'stops and disable postfix' do
        on(host, 'puppet resource service postfix ensure=stopped enable=false')
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
    end
  end
end
