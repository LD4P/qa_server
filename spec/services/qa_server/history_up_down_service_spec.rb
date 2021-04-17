# frozen_string_literal: true
require 'spec_helper'

RSpec.describe QaServer::HistoryUpDownService do
  let(:service) { described_class.new }

  context 'when total_count is 0' do
    let(:good_count) { 0 }
    let(:unknown_count) { 0 }
    let(:bad_count) { 0 }
    let(:timeout_count) { 0 }
    it 'returns :no_data' do
      status = service.send(:status_determination, good_count, unknown_count, bad_count, timeout_count)
      expect(status).to eq :no_data
    end
  end

  context 'when all queries failed' do
    let(:good_count) { 0 }
    let(:unknown_count) { 0 }
    let(:bad_count) { 5 }
    let(:timeout_count) { 0 }
    it 'returns :down' do
      status = service.send(:status_determination, good_count, unknown_count, bad_count, timeout_count)
      expect(status).to eq :down
    end
  end

  context 'when all queries passed' do
    let(:good_count) { 5 }
    let(:unknown_count) { 0 }
    let(:bad_count) { 0 }
    let(:timeout_count) { 0 }
    it 'returns :fully_up' do
      status = service.send(:status_determination, good_count, unknown_count, bad_count, timeout_count)
      expect(status).to eq :fully_up
    end
  end

  context 'when all queries are unknown' do
    let(:good_count) { 0 }
    let(:unknown_count) { 5 }
    let(:bad_count) { 0 }
    let(:timeout_count) { 0 }
    it 'returns :barely_up' do
      status = service.send(:status_determination, good_count, unknown_count, bad_count, timeout_count)
      expect(status).to eq :barely_up
    end
  end

  context 'when too many queries timed out' do
    let(:threshold) { 0.5 }
    let(:good_count) { 100 - bad_count }
    let(:unknown_count) { 0 }
    let(:bad_count) { timeout_count + 2 }
    let(:timeout_count) { threshold * 100 + 1 }
    it 'returns :good' do
      status = service.send(:status_determination, good_count, unknown_count, bad_count, timeout_count)
      expect(status).to eq :timeouts
    end
  end

  context 'when almost all queries pass' do
    let(:threshold) { 0.95 }
    let(:good_count) { threshold * 100 + 1 }
    let(:unknown_count) { 0 }
    let(:bad_count) { 100 - good_count }
    let(:timeout_count) { 0 }
    it 'returns :good' do
      status = service.send(:status_determination, good_count, unknown_count, bad_count, timeout_count)
      expect(status).to eq :mostly_up
    end
  end

  context 'when too many queries fail' do
    let(:threshold) { 0.95 }
    let(:good_count) { threshold * 100 - 1 }
    let(:unknown_count) { 0 }
    let(:bad_count) { 100 - good_count }
    let(:timeout_count) { 0 }
    it 'returns :good' do
      status = service.send(:status_determination, good_count, unknown_count, bad_count, timeout_count)
      expect(status).to eq :barely_up
    end
  end
end
