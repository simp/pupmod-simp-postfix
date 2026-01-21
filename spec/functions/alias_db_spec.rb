# frozen_string_literal: true

require 'spec_helper'

describe 'postfix::alias_db' do
  context 'without postfix_alias_database fact' do
    {
      'lmdb:/etc/aliases'    => '/etc/aliases.lmdb',
      'hash:/etc/aliases'    => '/etc/aliases.db',
      'btree:/etc/aliases'   => '/etc/aliases.db',
      'cdb:/etc/aliases'     => '/etc/aliases.cdb',
      'dbm:/etc/aliases'     => '/etc/aliases.dir',
      'sdbm:/etc/aliases'    => '/etc/aliases.dir',
      ':/etc/aliases'        => nil,
      'unknown:/etc/aliases' => nil,
      'unknown:'             => nil,
      'invalid'              => nil,
      'invalid::'            => nil,
      nil                    => nil,
    }.each do |alias_database, aliases_filename|
      it { is_expected.to run.with_params(alias_database).and_return(aliases_filename) }
    end
  end

  context 'with postfix_alias_database fact' do
    let(:facts) do
      { postfix_alias_database: 'hash:/etc/aliases' }
    end

    it 'falls back to the fact value' do
      is_expected.to run.with_params(nil).and_return('/etc/aliases.db')
    end

    it 'uses the supplied value' do
      is_expected.to run.with_params('lmdb:/etc/aliases').and_return('/etc/aliases.lmdb')
    end
  end
end
