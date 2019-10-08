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
      @action = action
      @stats = {}
    end

    # Calculate performance statistics for a set of PerformanceHistory records.  Min is at the 10th percentile.  Max is at the 90th percentile.
    # @return [Hash] hash of the statistics
    # @example
    # { retrieve_avg_ms: 12.3, graph_load_avg_ms: 2.1, normalization_avg_ms: 4.2, full_request_avg_ms: 16.5,
    #   retrieve_min_ms: 12.3, graph_load_min_ms: 12.3, normalization_min_ms: 4.2, full_request_min_ms: 16.5,
    #   retrieve_max_ms: 12.3, graph_load_max_ms: 12.3, normalization_max_ms: 4.2, full_request_max_ms: 16.5 }
    def calculate_stats(avg: false, low: false, high: false, load: true, norm: true, full: true) # rubocop:disable Metrics/ParameterLists
      calculate_retrieve_stats(avg, low, high) if load
      calculate_graph_load_stats(avg, low, high) if load
      calculate_normalization_stats(avg, low, high) if norm
      calculate_action_stats(avg, low, high) if full
      stats
    end

    private

      def calculate_retrieve_stats(avg, low, high)
        stats[AVG_RETR] = calculate_average(retrieve_times) if avg
        stats[LOW_RETR] = calculate_10th_percentile(retrieve_times_sorted) if low
        stats[HIGH_RETR] = calculate_90th_percentile(retrieve_times_sorted) if high
      end

      def calculate_graph_load_stats(avg, low, high)
        stats[AVG_GRPH] = calculate_average(graph_load_times) if avg
        stats[LOW_GRPH] = calculate_10th_percentile(graph_load_times_sorted) if low
        stats[HIGH_GRPH] = calculate_90th_percentile(graph_load_times_sorted) if high
      end

      def calculate_normalization_stats(avg, low, high)
        stats[AVG_NORM] = calculate_average(norm_times) if avg
        stats[LOW_NORM] = calculate_10th_percentile(norm_times_sorted) if low
        stats[HIGH_NORM] = calculate_90th_percentile(norm_times_sorted) if high
      end

      def calculate_action_stats(avg, low, high)
        stats[AVG_ACTN] = calculate_average(action_times) if avg
        stats[LOW_ACTN] = calculate_10th_percentile(action_times_sorted) if low
        stats[HIGH_ACTN] = calculate_90th_percentile(action_times_sorted) if high
      end

      def count
        @count ||= records.count
      end

      def tenth_percentile_count(times)
        percentile_count = (times.count * 0.1).round
        percentile_count = 1 if percentile_count.zero? && count > 1
        percentile_count
      end

      def retrieve_times
        where_clause = action.nil? ? "" : {"action" => action}
        @retrieve_times ||= records.where(where_clause).where.not(retrieve_time_ms: nil).pluck(:retrieve_time_ms)
      end

      def retrieve_times_sorted
        @retrieve_times_sorted ||= retrieve_times.sort
      end

      def graph_load_times
        where_clause = action.nil? ? "" : {"action" => action}
        @graph_load_times ||= records.where(where_clause).where.not(graph_load_time_ms: nil).pluck(:graph_load_time_ms)
      end

      def graph_load_times_sorted
        @graph_load_times_sorted ||= graph_load_times.sort
      end

      def norm_times
        where_clause = action.nil? ? "" : {"action" => action}
        @norm_times ||= records.where(where_clause).where.not(normalization_time_ms: nil).pluck(:normalization_time_ms)
      end

      def norm_times_sorted
        @norm_times_sorted ||= norm_times.sort
      end

      def action_times
        where_clause = action.nil? ? "" : {"action" => action}
        @action_times ||= records.where(where_clause).where.not(action_time_ms: nil).pluck(:action_time_ms)
      end

      def action_times_sorted
        @action_times_sorted ||= action_times.sort
      end

      def calculate_average(times)
        return 0 if count.zero?
        return times[0] if count == 1
        times.inject(0.0) { |sum, el| sum + el } / times.count
      end

      def calculate_10th_percentile(sorted_times)
        return 0 if sorted_times.count.zero?
        return sorted_times[0] if sorted_times.count == 1
        sorted_times[tenth_percentile_count(sorted_times) - 1]
      end

      def calculate_90th_percentile(sorted_times)
        return 0 if sorted_times.count.zero?
        return sorted_times[0] if sorted_times.count == 1
        sorted_times[sorted_times.count - tenth_percentile_count(sorted_times)]
      end
  end
end
