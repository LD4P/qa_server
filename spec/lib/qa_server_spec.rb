require 'spec_helper'

RSpec.describe QaServer do
  describe '.current_time' do
    before do
      allow(QaServer).to receive_message_chain(:config, :preferred_time_zone_name).and_return('Eastern Time (US & Canada)')
      allow(Time).to receive(:now).and_return(DateTime.parse('2019-12-11 05:00:00 -0500'))
    end

    it 'returns the time in the preferred time zone' do
      expect(described_class.current_time.zone).to eq 'EST'
    end
  end


  describe '.monitoring_expires_at' do
    before do
      allow(QaServer).to receive_message_chain(:config, :hour_offset_to_run_monitoring_tests).and_return(3)
    end

    context 'when current hour is after offset time' do
      before do
        allow(QaServer).to receive(:current_time).and_return(DateTime.parse('2019-12-11 05:00:00 -0500'))
      end

      it 'returns expiration on current date at offset time' do
        expect(described_class.monitoring_expires_at).to eq DateTime.parse('2019-12-11 03:00:00 -0500')
      end
    end

    context 'when current hour is before offset time' do
      before do
        allow(QaServer).to receive(:current_time).and_return(DateTime.parse('2019-12-11 01:00:00 -0500'))
      end

      it 'returns expiration on previous date at offset time' do
        expect(described_class.monitoring_expires_at).to eq DateTime.parse('2019-12-10 03:00:00 -0500')
      end
    end
  end
end
