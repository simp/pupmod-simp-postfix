require 'spec_helper'

provider_class = Puppet::Type.type(:postfix_main_cf).provider(:ruby)

describe provider_class do
  before :each do
    @resource = Puppet::Type::Postfix_main_cf.new(name: 'mail_owner', value: 'postfix')
    @provider = provider_class.new(@resource)
    allow(@provider).to receive(:postconf).with('inet_interfaces').and_return "inet_interfaces = all\n"
  end

  context 'when matching' do
    it 'does nothing if the postconf command returns a matching value' do
      allow(@provider).to receive(:postconf).with('mail_owner').and_return "mail_owner = postfix\n"
      expect(@provider.value).to eq('postfix')
    end

    it 'returns an error if the postconf command returns an invalid result' do
      allow(@provider).to receive(:postconf).with('mail_owner').and_return "unknown entry\n"
      expect { expect(@provider.value).to }.to raise_error(Puppet::Error, %r{not recognized by postconf})
    end

    it 'attempts an update if the postconf command returns a non-matching value', skip: 'This test  is causing segfault errors for unknown reasons' do
      @provider.expects(:postconf).with('-e', 'mail_owner=foo')
      @provider.send(:value=, 'foo')
    end
  end
end
