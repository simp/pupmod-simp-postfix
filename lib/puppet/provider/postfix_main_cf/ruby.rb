Puppet::Type.type(:postfix_main_cf).provide(:ruby) do

  commands :postconf => 'postconf'

  def value
    retval = nil

    conf_check = postconf(@resource[:name])
    if conf_check =~ /.*=\s*(.*)$/ then
      retval = $1.chomp
    else
      fail(Puppet::Error,"'#{@resource[:name]}' is not recognized by postconf.")
    end

    retval
  end

  def value=(should)
    orig_selinux_context = resource.get_selinux_current_context('/etc/postfix/main.cf')
    postconf('-e',"#{@resource[:name]}=#{should}")
    resource.set_selinux_context('/etc/postfix/main.cf',orig_selinux_context)
  end
end
