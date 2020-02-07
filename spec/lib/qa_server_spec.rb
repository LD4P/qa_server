# frozen_string_literal: true
require 'spec_helper'

RSpec.describe QaServer do
  # rubocop:disable RSpec/MessageChain
  let(:timezone_name) { 'Eastern Time (US & Canada)' }
  before { allow(described_class).to receive_message_chain(:config, :preferred_time_zone_name).and_return(timezone_name) }

  describe '.current_time' do
    before do
      allow(Time).to receive(:now).and_return(DateTime.parse('2019-12-11 05:00:00 -0500').in_time_zone(timezone_name))
    end

    it 'returns the time in the preferred time zone' do
      expect(described_class.current_time.zone).to eq 'EST'
    end
  end

  describe '.monitoring_expires_at' do
    before do
      allow(described_class).to receive_message_chain(:config, :hour_offset_to_expire_cache).and_return(3)
    end

    context 'when current hour is before offset time' do
      before do
        allow(described_class).to receive(:current_time).and_return(DateTime.parse('2019-12-11 02:54:00 -0500').in_time_zone(timezone_name))
      end

      it 'returns expiration on current date at offset time' do
        expect(described_class.monitoring_expires_at).to eq DateTime.parse('2019-12-11 02:55:00 -0500').in_time_zone(timezone_name)
      end
    end

    context 'when current hour is after offset time' do
      before do
        allow(described_class).to receive(:current_time).and_return(DateTime.parse('2019-12-11 02:56:00 -0500').in_time_zone(timezone_name))
      end

      it 'returns expiration on previous date at offset time' do
        expect(described_class.monitoring_expires_at).to eq DateTime.parse('2019-12-12 02:55:00 -0500').in_time_zone(timezone_name)
      end
    end
  end

  describe '.cache_expiry' do
    before do
      allow(described_class).to receive_message_chain(:config, :hour_offset_to_expire_cache).and_return(3)
      allow(Time).to receive(:now).and_return(DateTime.parse('2019-12-11 02:54:59 -0500').in_time_zone(timezone_name))
    end

    it 'returns seconds until offset time (simulates 1 second before offset time)' do
      expect(described_class.cache_expiry).to eq 1.second
    end
  end

  # rubocop:disable RSpec/MessageSpies
  describe '.log_agent_info' do
    let(:request) { double }

    context 'when ip logging is suppressed' do
      before { allow(Qa).to receive_message_chain(:config, :suppress_ip_data_from_log).and_return(true) }

      it 'suppresses agent logging' do
        expect(Rails.logger).not_to receive(:info).with(/^\{browser: /)
        described_class.log_agent_info(request)
      end
    end

    context 'when ip logging is not suppressed' do
      before { allow(Qa).to receive_message_chain(:config, :suppress_ip_data_from_log).and_return(false) }

      context 'and user_agent is nil' do
        before { allow(request).to receive(:user_agent).and_return(nil) }
        it 'logs agent info as UNKNOWN' do
          expect(Rails.logger).to receive(:info).with("{browser: UNKNOWN, browser_version: UNKNOWN, platform: UNKNOWN, os: UNKNOWN}")
          described_class.log_agent_info(request)
        end
      end

      context 'and user_agent has data' do
        # rubocop:disable RSpec/AnyInstance
        before do
          allow(request).to receive(:user_agent).and_return("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/79.0.3945.79 Safari/537.36")
          allow_any_instance_of(UserAgent::Browsers::Chrome).to receive(:browser).and_return("Chrome")
          allow_any_instance_of(UserAgent::Browsers::Chrome).to receive(:version).and_return("v1.1")
          allow_any_instance_of(UserAgent::Browsers::Chrome).to receive(:platform).and_return("Mac")
          allow_any_instance_of(UserAgent::Browsers::Chrome).to receive(:os).and_return("10.14")
        end
        # rubocop:enable RSpec/AnyInstance

        it 'logs agent info as UNKNOWN' do
          expect(Rails.logger).to receive(:info).with("{browser: Chrome, browser_version: v1.1, platform: Mac, os: 10.14}")
          described_class.log_agent_info(request)
        end
      end
    end
  end
  # rubocop:enable RSpec/MessageSpies
  # rubocop:enable RSpec/MessageChain
end
