# frozen_string_literal: true
require 'spec_helper'

RSpec.describe QaServer::Configuration do
  let(:config) { described_class.new }

  describe '#preferred_time_zone_name' do
    it 'returns default as Eastern Time' do
      expect(config.preferred_time_zone_name).to eq 'Eastern Time (US & Canada)'
    end

    it 'returns set time zone name' do
      config.preferred_time_zone_name = 'Pacific Time (US & Canada)'
      expect(config.preferred_time_zone_name).to eq 'Pacific Time (US & Canada)'
    end
  end

  describe '#hour_offset_to_expire_cache=' do
    it 'raises exception if offset is negative' do
      expect { config.hour_offset_to_expire_cache = -1 }.to raise_error ArgumentError, 'offset must be between 0 and 23'
    end

    it 'raises exception if offset is greater than 23' do
      expect { config.hour_offset_to_expire_cache = 24 }.to raise_error ArgumentError, 'offset must be between 0 and 23'
    end

    it 'sets offset if between 0..23' do
      expect(config.hour_offset_to_expire_cache = 5).to eq 5
    end
  end

  describe '#hour_offset_to_expire_cache' do
    it 'returns default as 3' do
      expect(config.hour_offset_to_expire_cache).to eq 3
    end

    it 'returns set offset' do
      config.hour_offset_to_expire_cache = 2
      expect(config.hour_offset_to_expire_cache).to eq 2
    end
  end

  describe '#display_historical_graph?' do
    it 'return default as false' do
      expect(config.display_historical_graph?).to eq false
    end

    it 'returns set value' do
      config.display_historical_graph = true
      expect(config.display_historical_graph?).to eq true
    end
  end

  describe '#display_historical_datatable?' do
    it 'return default as true' do
      expect(config.display_historical_datatable?).to eq true
    end

    it 'returns set value' do
      config.display_historical_datatable = false
      expect(config.display_historical_datatable?).to eq false
    end
  end

  describe '#display_performance_graph?' do
    it 'return default as false' do
      expect(config.display_performance_graph?).to eq false
    end

    it 'returns set value' do
      config.display_performance_graph = true
      expect(config.display_performance_graph?).to eq true
    end
  end

  describe '#performance_y_axis_max' do
    it 'return default as 4000' do
      expect(config.performance_y_axis_max).to eq 4000
    end

    it 'returns set value' do
      config.performance_y_axis_max = 3500
      expect(config.performance_y_axis_max).to eq 3500
    end
  end

  describe '#performance_retrieve_color' do
    it 'return default as #ABC3C9' do
      expect(config.performance_retrieve_color).to eq '#ABC3C9'
    end

    it 'returns set value' do
      config.performance_retrieve_color = '#FFFFFF'
      expect(config.performance_retrieve_color).to eq '#FFFFFF'
    end
  end

  describe '#performance_graph_load_color' do
    it 'return default as #ABC3C9' do
      expect(config.performance_graph_load_color).to eq '#E8DCD3'
    end

    it 'returns set value' do
      config.performance_graph_load_color = '#FFFFFF'
      expect(config.performance_graph_load_color).to eq '#FFFFFF'
    end
  end

  describe '#performance_normalization_color' do
    it 'return default as #ABC3C9' do
      expect(config.performance_normalization_color).to eq '#CCBE9F'
    end

    it 'returns set value' do
      config.performance_normalization_color = '#FFFFFF'
      expect(config.performance_normalization_color).to eq '#FFFFFF'
    end
  end

  describe '#performance_graph_default_time_period=' do
    it 'raises exception if time_period is invalid' do
      expect { config.performance_graph_default_time_period = :decade }.to raise_error ArgumentError, 'time_period must be one of :day, :month, or :year'
    end

    it 'sets time_period if valid' do
      expect(config.performance_graph_default_time_period = :day).to eq :day
      expect(config.performance_graph_default_time_period = :month).to eq :month
      expect(config.performance_graph_default_time_period = :year).to eq :year
    end
  end

  describe '#performance_graph_default_time_period' do
    it 'return default as :month' do
      expect(config.performance_graph_default_time_period).to eq :month
    end

    it 'returns set value' do
      config.performance_graph_default_time_period = :day
      expect(config.performance_graph_default_time_period).to eq :day
    end
  end

  describe '#display_performance_datatable?' do
    it 'return default as true' do
      expect(config.display_performance_datatable?).to eq true
    end

    it 'returns set value' do
      config.display_performance_datatable = false
      expect(config.display_performance_datatable?).to eq false
    end
  end

  describe '#performance_datatable_default_time_period=' do
    it 'raises exception if time_period is invalid' do
      expect { config.performance_datatable_default_time_period = :decade }.to raise_error ArgumentError, 'time_period must be one of :day, :month, :year, or :all'
    end

    it 'sets time_period if valid' do
      expect(config.performance_datatable_default_time_period = :day).to eq :day
      expect(config.performance_datatable_default_time_period = :month).to eq :month
      expect(config.performance_datatable_default_time_period = :year).to eq :year
      expect(config.performance_datatable_default_time_period = :all).to eq :all
    end
  end

  describe '#performance_datatable_default_time_period' do
    it 'return default as :year' do
      expect(config.performance_datatable_default_time_period).to eq :year
    end

    it 'returns set value' do
      config.performance_datatable_default_time_period = :day
      expect(config.performance_datatable_default_time_period).to eq :day
    end
  end

  describe '#performance_datatable_max_threshold' do
    it 'return default as 1500 (e.g. 1.5s)' do
      expect(config.performance_datatable_max_threshold).to eq 1500
    end

    it 'returns set value' do
      config.performance_datatable_max_threshold = 1200
      expect(config.performance_datatable_max_threshold).to eq 1200
    end
  end

  describe '#performance_datatable_warning_threshold' do
    it 'return default as 1000 (e.g. 1s)' do
      expect(config.performance_datatable_warning_threshold).to eq 1000
    end

    it 'returns set value' do
      config.performance_datatable_warning_threshold = 500
      expect(config.performance_datatable_warning_threshold).to eq 500
    end
  end
end
