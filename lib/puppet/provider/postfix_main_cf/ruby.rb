Puppet::Type.type(:postfix_main_cf).provide(:ruby) do

  commands :postconf => 'postconf'

  # This works around a bug in postfix where the configuration cannot be
  # processed if IPv6 is disabled via sysctl
  def fix_inet_interfaces
    unless Facter.value('ipv6_enabled')
      begin
        postconf('inet_interfaces')
      rescue Puppet::ExecutionFailure => error
        if error.to_s =~ /::1/
          set_config('inet_interfaces', '127.0.0.1')
        end
      end
    end
  end

  def set_config(key, value)
    orig_selinux_context = resource.get_selinux_current_context('/etc/postfix/main.cf')
    postconf('-e',"#{key}=#{value}")
    resource.set_selinux_context('/etc/postfix/main.cf',orig_selinux_context)
  end

  def value
    retval = nil

    # This needs to happen prior to any query of postconf to work around the
    # IPv6 bug
    fix_inet_interfaces

    conf_check = postconf(@resource[:name])
    if conf_check =~ /.*=\s*(.*)$/ then
      retval = $1.chomp
    else
      fail(Puppet::Error,"'#{@resource[:name]}' is not recognized by postconf.")
    end

    retval
  end

  def value=(should)
    set_config(@resource[:name], should)
  end
end
