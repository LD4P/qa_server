# frozen_string_literal: true
require 'spec_helper'

RSpec.describe QaServer::CacheExpiryService do
  # rubocop:disable RSpec/MessageChain
  let(:timezone_name) { 'Eastern Time (US & Canada)' }
  before { allow(described_class).to receive_message_chain(:config, :preferred_time_zone_name).and_return(timezone_name) }

  describe '.cache_expiry' do
    before do
      allow(described_class).to receive_message_chain(:config, :hour_offset_to_expire_cache).and_return(3)
      allow(Time).to receive(:now).and_return(DateTime.parse('2019-12-11 02:54:59 -0500').in_time_zone(timezone_name))
    end

    it 'returns seconds until offset time (simulates 1 second before offset time)' do
      expect(described_class.cache_expiry).to eq 1.second
    end
  end
  # rubocop:enable RSpec/MessageChain
end
