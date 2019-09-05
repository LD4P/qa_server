# frozen_string_literal: true
# Provide access to the scenario_results_history database table which tracks specific scenario runs over time.
module QaServer
  class PerformanceHistory < ActiveRecord::Base
    self.table_name = 'performance_history'

    enum action: [:fetch, :search]

    class_attribute :stats_calculator_class, :graph_service_class
    self.stats_calculator_class = QaServer::PerformanceCalculatorService
    self.graph_service_class = QaServer::PerformanceGraphService

    class << self
      include QaServer::PerformanceHistoryDataKeys

      # Save a scenario result
      # @param run_id [Integer] the run on which to gather statistics
      # @param result [Hash] the scenario result to be saved
      def save_result(dt_stamp:, authority:, action:, size_bytes:, load_time_ms:, normalization_time_ms:) # rubocop:disable Metrics/ParameterLists
        create(dt_stamp: dt_stamp,
               authority: authority,
               action: action,
               size_bytes: size_bytes,
               load_time_ms: load_time_ms,
               normalization_time_ms: normalization_time_ms)
      end

      # Performance data for a day, a month, and a year.
      # @returns [Hash] performance statistics for the past 24 hours
      # @example
      #   { all_authorities:
      #     { lifetime_stats:
      #       { load_avg_ms: 12.3, normalization_avg_ms: 4.2, full_request_avg_ms: 16.5, etc. }
      #     }
      #     { day:
      #       { 0: { hour: '1400', stats: { load_avg_ms: 12.3, normalization_avg_ms: 4.2, full_request_avg_ms: 16.5, etc. }},
      #         1: { hour: '1500', stats: { load_avg_ms: 12.3, normalization_avg_ms: 4.2, full_request_avg_ms: 16.5, etc. }},
      #         2: { hour: '1600', stats: { load_avg_ms: 12.3, normalization_avg_ms: 4.2, full_request_avg_ms: 16.5, etc. }},
      #         ...,
      #         23: { hour: 'NOW', load_avg_ms: 12.3, normalization_avg_ms: 4.2, full_request_avg_ms: 16.5, etc. }}
      #       }
      #     }
      #     { month:
      #       { 0: { day: '07-15-2019', stats: { load_avg_ms: 12.3, normalization_avg_ms: 4.2, full_request_avg_ms: 16.5, etc. }},
      #         1: { day: '07-16-2019', stats: { load_avg_ms: 12.3, normalization_avg_ms: 4.2, full_request_avg_ms: 16.5, etc. }},
      #         2: { day: '07-17-2019', stats: { load_avg_ms: 12.3, normalization_avg_ms: 4.2, full_request_avg_ms: 16.5, etc. }},
      #         ...,
      #         29: { day: 'TODAY', stats: { load_avg_ms: 12.3, normalization_avg_ms: 4.2, full_request_avg_ms: 16.5, etc. }}
      #       }
      #     }
      #     { year:
      #       { 0: { month: '09-2019', stats: { load_avg_ms: 12.3, normalization_avg_ms: 4.2, full_request_avg_ms: 16.5, etc. }},
      #         1: { month: '10-2019', stats: { load_avg_ms: 12.3, normalization_avg_ms: 4.2, full_request_avg_ms: 16.5, etc. }},
      #         2: { month: '11-2019', stats: { load_avg_ms: 12.3, normalization_avg_ms: 4.2, full_request_avg_ms: 16.5, etc. }},
      #         ...,
      #         11: { month: '08-2019', stats: { load_avg_ms: 12.3, normalization_avg_ms: 4.2, full_request_avg_ms: 16.5, etc. }}
      #       }
      #     }
      #   }
      def performance_data
        data = {}
        data[ALL_AUTH] = {
          FOR_LIFETIME => lifetime,
          FOR_DAY => graph_service_class.average_last_24_hours,
          FOR_MONTH => graph_service_class.average_last_30_days,
          FOR_YEAR => graph_service_class.average_last_12_months
        }
        data
      end

      private

        # Get hourly average for the past 24 hours.
        # @returns [Hash] performance statistics across all records
        # @example
        #   { load_avg_ms: 12.3, normalization_avg_ms: 4.2, full_request_avg_ms: 16.5, etc. }
        def lifetime
          records = PerformanceHistory.all
          stats_calculator_class.calculate_stats(records)
        end
    end
  end
end
