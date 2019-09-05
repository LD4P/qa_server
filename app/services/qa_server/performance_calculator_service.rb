# frozen_string_literal: true
# This class calculates min, max, average stats for load, normalization, and full request times for a given set of performance records.
module QaServer
  class PerformanceCalculatorService
    class << self
      include QaServer::PerformanceHistoryDataKeys

      MIN_STARTING_TIME = 999_999_999

      # Calculate performance statistics for a set of PerformanceHistory records
      # @param records [Array <Qa::PerformanceHistory>] set of records used to calculate the statistics
      # @return [Hash] hash of the statistics
      # @example
      # { load_avg_ms: 12.3, normalization_avg_ms: 4.2, full_request_avg_ms: 16.5,
      #   load_min_ms: 12.3, normalization_min_ms: 4.2, full_request_min_ms: 16.5,
      #   load_max_ms: 12.3, normalization_max_ms: 4.2, full_request_max_ms: 16.5 }
      def calculate_stats(records)
        stats = init_stats
        return stats if records.count.zero?
        first = true
        records.each do |record|
          update_sum_stats(stats, record)
          update_min_stats(stats, record)
          update_max_stats(stats, record)
          first = false
        end
        calculate_avg_stats(stats, records)
        stats
      end

      private

        def init_stats
          stats = {}
          stats[SUM_LOAD] = 0
          stats[SUM_NORM] = 0
          stats[SUM_FULL] = 0
          stats[AVG_LOAD] = 0
          stats[AVG_NORM] = 0
          stats[AVG_FULL] = 0
          stats[MIN_LOAD] = MIN_STARTING_TIME
          stats[MIN_NORM] = MIN_STARTING_TIME
          stats[MIN_FULL] = MIN_STARTING_TIME
          stats[MAX_LOAD] = 0
          stats[MAX_NORM] = 0
          stats[MAX_FULL] = 0
          stats
        end

        def update_sum_stats(stats, record)
          stats[SUM_LOAD] += record.load_time_ms
          stats[SUM_NORM] += record.normalization_time_ms
          stats[SUM_FULL] += full_request_time_ms(record)
        end

        def update_min_stats(stats, record)
          stats[MIN_LOAD] = [stats[MIN_LOAD], record.load_time_ms].min
          stats[MIN_NORM] = [stats[MIN_NORM], record.normalization_time_ms].min
          stats[MIN_FULL] = [stats[MIN_FULL], full_request_time_ms(record)].min
        end

        def update_max_stats(stats, record)
          stats[MAX_LOAD] = [stats[MAX_LOAD], record.load_time_ms].max
          stats[MAX_NORM] = [stats[MAX_NORM], record.normalization_time_ms].max
          stats[MAX_FULL] = [stats[MAX_FULL], full_request_time_ms(record)].max
        end

        def calculate_avg_stats(stats, records)
          stats[AVG_LOAD] = stats[SUM_LOAD] / records.count
          stats[AVG_NORM] = stats[SUM_NORM] / records.count
          stats[AVG_FULL] = stats[SUM_FULL] / records.count
        end

        def full_request_time_ms(record)
          record.load_time_ms + record.normalization_time_ms
        end
    end
  end
end
