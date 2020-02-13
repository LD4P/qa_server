# frozen_string_literal: true
# This class calculates min, max, average stats for load, normalization, and full request times for a given set of performance records.
require 'matrix'
module QaServer
  class PerformanceCalculatorService
    include QaServer::PerformanceHistoryDataKeys

    attr_reader :records, :stats, :action

    # @param records [Array <Qa::PerformanceHistory>] set of records used to calculate the statistics
    def initialize(records, action: nil)
      @records = records
      @action = [:search, :fetch].include?(action) ? action : nil
      @stats = {}
    end

    # Calculate performance statistics with percentiles.  Min is at the 10th percentile.  Max is at the 90th percentile.
    # @return [Hash] hash of the statistics
    # @example
    #   { retrieve_avg_ms: 12.3, graph_load_avg_ms: 2.1, normalization_avg_ms: 4.2, full_request_avg_ms: 16.5,
    #     retrieve_10th_ms: 12.3, graph_load_10th_ms: 12.3, normalization_10th_ms: 4.2, full_request_10th_ms: 16.5,
    #     retrieve_90th_ms: 12.3, graph_load_90th_ms: 12.3, normalization_90th_ms: 4.2, full_request_90th_ms: 16.5 }
    def calculate_stats_with_percentiles
      calculate_retrieve_stats(true, true, true)
      calculate_graph_load_stats(true, true, true)
      calculate_normalization_stats(true, true, true)
      calculate_action_stats(true, true, true)
      stats
    end

    # Calculate performance statistics including averages only.
    # @return [Hash] hash of the statistics
    # @example
    #   { retrieve_avg_ms: 12.3, graph_load_avg_ms: 2.1, normalization_avg_ms: 4.2, full_request_avg_ms: 16.5 }
    def calculate_average_stats
      calculate_load_stats(true, false, false) # used for backward compatibility only
      calculate_retrieve_stats(true, false, false)
      calculate_graph_load_stats(true, false, false)
      calculate_normalization_stats(true, false, false)
      stats
    end

    private

      def calculate_load_stats(avg, low, high)
        stats[AVG_LOAD] = calculate_average(full_load_times) if avg
        stats[LOW_LOAD] = calculate_10th_percentile(full_load_times) if low
        stats[HIGH_LOAD] = calculate_90th_percentile(full_load_times) if high
      end

      def calculate_retrieve_stats(avg, low, high)
        stats[AVG_RETR] = calculate_average(retrieve_times) if avg
        stats[LOW_RETR] = calculate_10th_percentile(retrieve_times) if low
        stats[HIGH_RETR] = calculate_90th_percentile(retrieve_times) if high
      end

      def calculate_graph_load_stats(avg, low, high)
        stats[AVG_GRPH] = calculate_average(graph_load_times) if avg
        stats[LOW_GRPH] = calculate_10th_percentile(graph_load_times) if low
        stats[HIGH_GRPH] = calculate_90th_percentile(graph_load_times) if high
      end

      def calculate_normalization_stats(avg, low, high)
        stats[AVG_NORM] = calculate_average(norm_times) if avg
        stats[LOW_NORM] = calculate_10th_percentile(norm_times) if low
        stats[HIGH_NORM] = calculate_90th_percentile(norm_times) if high
      end

      def calculate_action_stats(avg, low, high)
        stats[AVG_ACTN] = calculate_average(action_times) if avg
        stats[LOW_ACTN] = calculate_10th_percentile(action_times) if low
        stats[HIGH_ACTN] = calculate_90th_percentile(action_times) if high
      end

      def tenth_percentile_count(times)
        percentile_count = (times.count * 0.1).round
        percentile_count = 1 if percentile_count.zero? && times.count > 1
        percentile_count
      end

      def times(column)
        where_clause = action.nil? ? "" : { "action" => action }
        records.where(where_clause).where.not(column => nil).order(column).pluck(column)
      end

      def full_load_times
        @full_load_times ||= times(:retrieve_plus_graph_load_time_ms)
      end

      def retrieve_times
        @retrieve_times ||= times(:retrieve_time_ms)
      end

      def graph_load_times
        @graph_load_times ||= times(:graph_load_time_ms)
      end

      def norm_times
        @norm_times ||= times(:normalization_time_ms)
      end

      def action_times
        @action_times ||= times(:action_time_ms)
      end

      def calculate_average(times)
        return 0 if times.count.zero?
        return times[0] if times.count == 1
        times.inject(0.0) { |sum, el| sum + el } / times.count
      end

      def calculate_10th_percentile(times)
        return 0 if times.count.zero?
        return times[0] if times.count == 1
        times[tenth_percentile_count(times) - 1]
      end

      def calculate_90th_percentile(times)
        return 0 if times.count.zero?
        return times[0] if times.count == 1
        times[times.count - tenth_percentile_count(times)]
      end
  end
end
