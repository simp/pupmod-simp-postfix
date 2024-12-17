require 'spec_helper'

describe Puppet::Type.type(:postfix_main_cf) do
  let :postfix_main_cf do
    Puppet::Type.type(:postfix_main_cf).new(name: 'mail_owner', value: 'postfix')
  end

  it 'successfullies activate with a valid name and value' do
    expect { postfix_main_cf }.not_to raise_error
  end

  it 'requires a value argument' do
    expect {
      Puppet::Type.type(:postfix_main_cf).new(
        name: 'mail_owner',
        value: '',
      )
    }.to raise_error(Puppet::ResourceError, %r{You must supply.*value})
  end
end
