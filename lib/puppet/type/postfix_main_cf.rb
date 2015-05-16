module Puppet
  newtype(:postfix_main_cf) do
    require 'puppet/util/selinux'
    include Puppet::Util::SELinux

    @doc = "Modifies settings in the postfix main.cf configuration file."

    def initialize(args)
      super(args)

      if self[:notify] then
        self[:notify] += ['Service[postfix]']
      else
        self[:notify] = ['Service[postfix]']
      end
    end
    newparam(:name) do
      isnamevar
      desc "The parameter to modify."
    end

    newproperty(:value) do
      desc "The value to which to set the named parameter."
    end

    validate do
      must_supply = [:value]

      found = true
      must_supply.each do |var|
        not self[var] or self[var].empty? and found = false and break
      end

      raise(ArgumentError,"You must supply all of '#{must_supply.join(', ')}'") if not found
    end
  end
end
