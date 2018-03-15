require 'spec_helper'

describe Puppet::Type.type(:postfix_main_cf) do
  let :postfix_main_cf do
    Puppet::Type.type(:postfix_main_cf).new(:name => 'mail_owner', :value => 'postfix')
  end

  it 'should successfully activate with a valid name and value' do
    expect { postfix_main_cf }.to_not raise_error
  end

  it 'should require a value argument' do
    expect {
      postfix_main_cf = Puppet::Type.type(:postfix_main_cf).new(
        :name   => 'mail_owner',
        :value  => ''
      )
    }.to raise_error(Puppet::ResourceError,/You must supply.*value/)
  end
end
