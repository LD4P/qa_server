# frozen_string_literal: true
# Provide access to the scenario_results_history database table which tracks specific scenario runs over time.
module QaServer
  class PerformanceHistory < ActiveRecord::Base
    self.table_name = 'performance_history'

    enum action: [:fetch, :search]

    class_attribute :stats_calculator_class, :graph_data_service_class, :graphing_service_class, :authority_list_class
    self.stats_calculator_class = QaServer::PerformanceCalculatorService
    self.graph_data_service_class = QaServer::PerformanceGraphDataService
    self.graphing_service_class = QaServer::PerformanceGraphingService
    self.authority_list_class = QaServer::AuthorityListerService

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

      # Performance data for a day, a month, a year, and all time for each authority.
      # @param datatype [Symbol] what type of data should be calculated (e.g. :datatable, :graph, :all)
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
      #     { AGROVOC_LD4L_CACHE: ... # same data for each authority  }
      #   }
      def performance_data(datatype: :datatable)
        return if datatype == :none
        data = calculate_data(datatype)
        graphing_service_class.create_performance_graphs(performance_data: data) if calculate_graphdata? datatype
        data
      end

      private

        def calculate_datatable?(datatype)
          datatype == :datatable || datatype == :all
        end

        def calculate_graphdata?(datatype)
          datatype == :graph || datatype == :all
        end

        def calculate_data(datatype)
          data = {}
          auths = authority_list_class.authorities_list
          data[ALL_AUTH] = data_for_authority(datatype: datatype)
          auths.each { |auth_name| data[auth_name] = data_for_authority(authority_name: auth_name, datatype: datatype) }
          data
        end

        def data_for_authority(authority_name: nil, datatype:)
          data = {}
          data[FOR_LIFETIME] = lifetime(authority_name) if calculate_datatable?(datatype)
          if calculate_graphdata?(datatype)
            data[FOR_DAY] = graph_data_service_class.average_last_24_hours(authority_name)
            data[FOR_MONTH] = graph_data_service_class.average_last_30_days(authority_name)
            data[FOR_YEAR] = graph_data_service_class.average_last_12_months(authority_name)
          end
          data
        end

        # Get statistics for all available data.
        # @param [String] auth_name - limit statistics to records for the given authority (default: all authorities)
        # @returns [Hash] performance statistics across all records
        # @example
        #   { load_avg_ms: 12.3, normalization_avg_ms: 4.2, full_request_avg_ms: 16.5, etc. }
        def lifetime(auth_name = nil)
          records = auth_name.nil? ? PerformanceHistory.all : where(authority: auth_name)
          stats_calculator_class.calculate_stats(records)
        end
    end
  end
end
