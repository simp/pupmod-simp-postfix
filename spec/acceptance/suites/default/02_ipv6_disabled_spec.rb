require 'spec_helper_acceptance'

test_name 'postfix'

describe 'postfix' do
  hosts.each do |host|

    context 'with ipv6 explicitly disabled' do
      let(:manifest) {
        <<-EOS
          include '::postfix'
        EOS
      }
      let(:hieradata) {{
        'simp_options::pki::source' => '/etc/pki/simp-testing/pki/'
      }}

      # SIMP-4418
      it 'should disable ipv6' do
        on(host, 'sysctl -w net.ipv6.conf.all.disable_ipv6=1')
        on(host, 'sysctl -w net.ipv6.conf.default.disable_ipv6=1')
        on(host, 'sysctl -p')
        on(host, 'puppet resource kernel_parameter ipv6.disable ensure=present value=1')
        host.reboot
      end
      it 'should stop and disable postfix' do
        case host[:platform]
        when /el-6-x86_64/
          on(host, 'service postfix stop')
          on(host, 'chkconfig postfix off')
        when /el-7-x86_64/
          on(host, 'systemctl disable postfix --now')
        end
      end

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
