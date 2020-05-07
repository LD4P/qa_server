# frozen_string_literal: true
require 'spec_helper'

RSpec.describe QaServer do
  # rubocop:disable RSpec/MessageChain
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
