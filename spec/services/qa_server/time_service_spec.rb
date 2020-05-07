# frozen_string_literal: true
require 'spec_helper'

RSpec.describe QaServer::TimeService do
  let(:timezone_name) { 'Eastern Time (US & Canada)' }
  before do
    allow(described_class).to receive_message_chain(:config, :preferred_time_zone_name).and_return(timezone_name) # rubocop:disable RSpec/MessageChain
    allow(Time).to receive(:now).and_return(DateTime.parse('2019-12-11 05:00:00 -0500').in_time_zone(timezone_name))
  end

  describe '.current_time' do
    it 'returns the time in the preferred time zone' do
      expect(described_class.current_time.zone).to eq 'EST'
    end

    it 'returns the time current time' do
      expect(described_class.current_time).to eq DateTime.parse('2019-12-11 05:00:00 -0500').in_time_zone(timezone_name)
    end
  end

  describe '.current_time_s' do
    before do
      allow(Time).to receive(:now).and_return(DateTime.parse('1970-01-01 00:00:01 -0000').in_time_zone(timezone_name))
    end

    it 'number of seconds since epoch for current time' do
      expect(described_class.current_time_s).to eq 1
    end
  end

  describe '.pretty_time' do
    before do
      allow(Time).to receive(:now).and_return(DateTime.parse('2019-12-11 05:00:00 -0500').in_time_zone(timezone_name))
    end

    it 'converts dt_stamp to string formatted with date and time' do
      expect(described_class.pretty_time(described_class.current_time)).to eq '12/11/2019 - 05:00 AM'
    end
  end

  describe '.pretty_date' do
    before do
      allow(Time).to receive(:now).and_return(DateTime.parse('2019-12-11 05:00:00 -0500').in_time_zone(timezone_name))
    end

    it 'converts dt_stamp to string formatted with date' do
      expect(described_class.pretty_date(described_class.current_time)).to eq '12/11/2019'
    end
  end
end
