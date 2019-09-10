# frozen_string_literal: true
# This class calculates min, max, average stats for load, normalization, and full request times for a given set of performance records.
require 'matrix'
module QaServer
  class PerformanceCalculatorService
    include QaServer::PerformanceHistoryDataKeys

    attr_reader :records
    attr_reader :stats

    # @param records [Array <Qa::PerformanceHistory>] set of records used to calculate the statistics
    def initialize(records)
      @records = records
      @stats = {}
    end

    # Calculate performance statistics for a set of PerformanceHistory records.  Min is at the 10th percentile.  Max is at the 90th percentile.
    # @return [Hash] hash of the statistics
    # @example
    # { load_avg_ms: 12.3, normalization_avg_ms: 4.2, full_request_avg_ms: 16.5,
    #   load_min_ms: 12.3, normalization_min_ms: 4.2, full_request_min_ms: 16.5,
    #   load_max_ms: 12.3, normalization_max_ms: 4.2, full_request_max_ms: 16.5 }
    def calculate_stats(avg: false, low: false, high: false, load: true, norm: true, full: true) # rubocop:disable Metrics/ParameterLists
      calculate_load_stats(avg, low, high) if load
      calculate_norm_stats(avg, low, high) if norm
      calculate_full_stats(avg, low, high) if full
      stats
    end

    private

      def calculate_load_stats(avg, low, high)
        stats[AVG_LOAD] = calculate_average(load_times) if avg
        stats[LOW_LOAD] = calculate_10th_percentile(load_times_sorted) if low
        stats[HIGH_LOAD] = calculate_90th_percentile(load_times_sorted) if high
      end

      def calculate_norm_stats(avg, low, high)
        stats[AVG_NORM] = calculate_average(norm_times) if avg
        stats[LOW_NORM] = calculate_10th_percentile(norm_times_sorted) if low
        stats[HIGH_NORM] = calculate_90th_percentile(norm_times_sorted) if high
      end

      def calculate_full_stats(avg, low, high)
        stats[AVG_FULL] = calculate_average(full_times) if avg
        stats[LOW_FULL] = calculate_10th_percentile(full_times_sorted) if low
        stats[HIGH_FULL] = calculate_90th_percentile(full_times_sorted) if high
      end

      def count
        @count ||= records.count
      end

      def tenth_percentile_count
        return @tenth_percentile_count if @tenth_percentile_count.present?
        percentile_count = (count * 0.1).round
        percentile_count = 1 if percentile_count.zero? && count > 1
        @tenth_percentile_count = percentile_count
      end

      def load_times
        @load_times ||= records.pluck(:load_time_ms).to_a
      end

      def load_times_sorted
        @load_times_sorted ||= load_times.sort
      end

      def norm_times
        @norm_times ||= records.pluck(:normalization_time_ms).to_a
      end

      def norm_times_sorted
        @norm_times_sorted ||= norm_times.sort
      end

      def full_times
        @full_times ||= (Vector.elements(load_times) + Vector.elements(norm_times)).to_a
      end

      def full_times_sorted
        @full_times_sorted ||= full_times.sort
      end

      def calculate_average(times)
        return 0 if count.zero?
        return times[0] if count == 1
        times.inject(0.0) { |sum, el| sum + el } / count
      end

      def calculate_10th_percentile(sorted_times)
        return 0 if count.zero?
        return sorted_times[0] if count == 1
        sorted_times[tenth_percentile_count - 1]
      end

      def calculate_90th_percentile(sorted_times)
        return 0 if count.zero?
        return sorted_times[0] if count == 1
        sorted_times[count - tenth_percentile_count]
      end
  end
end
