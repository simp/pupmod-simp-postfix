require 'spec_helper'

provider_class = Puppet::Type.type(:postfix_main_cf).provider(:ruby)

describe provider_class do
  before :each do
    @resource = Puppet::Type::Postfix_main_cf.new(:name  => 'mail_owner', :value => 'postfix')
    @provider = provider_class.new(@resource)
  end

  context "when matching" do
    it 'should do nothing if the postconf command returns a matching value' do
      @provider.stubs(:postconf).with('mail_owner').returns "mail_owner = postfix\n"
      @provider.value.should == 'postfix'
    end

    it 'should return an error if the postconf command returns an invalid result' do
      @provider.stubs(:postconf).with('mail_owner').returns "unknown entry\n"
      expect { @provider.value.should }.to raise_error(Puppet::Error,/not recognized by postconf/)
    end

    it 'should attempt an update if the postconf command returns a non-matching value' do
      @provider.expects(:postconf).with('-e','mail_owner=foo')
      @provider.send(:value=,'foo')
    end
  end
end
