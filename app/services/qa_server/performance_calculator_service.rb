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
    def calculate_stats
      calculate_load_stats
      calculate_norm_stats
      calculate_full_stats
      stats
    end

    private

      def calculate_load_stats
        stats[AVG_LOAD] = calculate_average(load_times)
        stats[LOW_LOAD] = calculate_10th_percentile(load_times_sorted)
        stats[HIGH_LOAD] = calculate_90th_percentile(load_times_sorted)
      end

      def calculate_norm_stats
        stats[AVG_NORM] = calculate_average(norm_times)
        stats[LOW_NORM] = calculate_10th_percentile(norm_times_sorted)
        stats[HIGH_NORM] = calculate_90th_percentile(norm_times_sorted)
      end

      def calculate_full_stats
        stats[AVG_FULL] = calculate_average(full_times)
        stats[LOW_FULL] = calculate_10th_percentile(full_times_sorted)
        stats[HIGH_FULL] = calculate_90th_percentile(full_times_sorted)
      end

      def count
        @count ||= records.count
      end

      def tenth_percentile_count
        @tenth_percentile_count ||= (records.count*0.1).round
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
        times.inject(0.0) { |sum, el| sum + el } / count
      end

      def calculate_10th_percentile(sorted_times)
        sorted_times[tenth_percentile_count-1]
      end

      def calculate_90th_percentile(sorted_times)
        sorted_times[count-tenth_percentile_count]
      end
  end
end
