# frozen_string_literal: true

require 'spec_helper'
require 'facter'
require 'facter/postfix_alias_database'

describe :postfix_alias_database, type: :fact do
  subject(:fact) { Facter.fact(:postfix_alias_database) }

  before :each do
    Facter.clear
  end

  context 'when postconf is not available' do
    before :each do
      allow(Facter::Core::Execution).to receive(:which).with('postconf').and_return(nil)
    end

    it 'returns nil' do
      expect(fact.value).to be_nil
    end
  end

  context 'when postconf is available' do
    let(:alias_database) { 'hash:/etc/aliases' }

    before :each do
      allow(Facter::Core::Execution).to receive(:which).with('postconf').and_return('/usr/sbin/postconf')
      allow(Facter::Core::Execution).to receive(:execute).with('postconf -h alias_database').and_return("#{alias_database}\n")
    end

    it 'returns the aliases filename based on alias_database' do
      expect(fact.value).to eq(alias_database)
    end
  end
end
