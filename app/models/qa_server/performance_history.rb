# frozen_string_literal: true
# Provide access to the scenario_results_history database table which tracks specific scenario runs over time.
module QaServer
  class PerformanceHistory < ApplicationRecord
    self.table_name = 'performance_history'

    enum action: { fetch: 0, search: 1 }

    class_attribute :datatable_data_service_class, :graph_data_service_class
    self.datatable_data_service_class = QaServer::PerformanceDatatableService
    self.graph_data_service_class = QaServer::PerformanceGraphDataService

    class << self
      include QaServer::PerformanceHistoryDataKeys

      # Save a scenario result
      # @param authority [String] name of the authority
      # @param action [Symbol] type of action being evaluated (e.g. :fetch, :search)
      # @param dt_stamp [Time] defaults to current time in preferred time zone
      # @return ActveRecord::Base for the new performance history record
      def create_record(authority:, action:, dt_stamp: QaServer::TimeService.current_time)
        create(dt_stamp: dt_stamp,
               authority: authority,
               action: action)
      end

      # Performance data for a day, a month, a year, and all time for each authority.
      # @param datatype [Symbol] what type of data should be calculated (e.g. :datatable, :graph, :all)
      # @returns [Hash] performance statistics for the past 24 hours
      # @example
      #   { all_authorities:
      #     { search:
      #       { retrieve_avg_ms: 12.3, graph_load_avg_ms: 2.1, normalization_avg_ms: 4.2, full_request_avg_ms: 16.5,
      #         retrieve_10th_ms: 12.3, graph_load_10th_ms: 12.3, normalization_10th_ms: 4.2, full_request_10th_ms: 16.5,
      #         retrieve_90th_ms: 12.3, graph_load_90th_ms: 12.3, normalization_90th_ms: 4.2, full_request_90th_ms: 16.5 },
      #       fetch: { ... # same data as for search_stats },
      #       all: { ... # same data as for search_stats }
      #     },
      #     AGROVOC_LD4L_CACHE: { ... # same data for each authority  }
      #   }
      def performance_table_data(force: false)
        datatable_data_service_class.calculate_datatable_data(force: force)
      end

      # Performance data for a day, a month, a year, and all time for each authority.
      # @param datatype [Symbol] what type of data should be calculated (e.g. :datatable, :graph, :all)
      # @returns [Hash] performance statistics for the past 24 hours
      # @example
      #   { all_authorities:
      #     { search:
      #       {
      #         day:
      #           { 0: { hour: '1400', stats: { retrieve_avg_ms: 12.3, graph_load_avg_ms: 2.1, normalization_avg_ms: 4.2, full_request_avg_ms: 16.5, etc. }},
      #             1: { hour: '1500', stats: { retrieve_avg_ms: 12.3, graph_load_avg_ms: 2.1, normalization_avg_ms: 4.2, full_request_avg_ms: 16.5, etc. }},
      #             2: { hour: '1600', stats: { retrieve_avg_ms: 12.3, graph_load_avg_ms: 2.1, normalization_avg_ms: 4.2, full_request_avg_ms: 16.5, etc. }},
      #             ...,
      #             23: { hour: 'NOW', retrieve_avg_ms: 12.3, graph_load_avg_ms: 2.1, normalization_avg_ms: 4.2, full_request_avg_ms: 16.5, etc. }}
      #           },
      #         month:
      #           { 0: { day: '07-15-2019', stats: { retrieve_avg_ms: 12.3, graph_load_avg_ms: 2.1, normalization_avg_ms: 4.2, full_request_avg_ms: 16.5, etc. }},
      #             1: { day: '07-16-2019', stats: { retrieve_avg_ms: 12.3, graph_load_avg_ms: 2.1, normalization_avg_ms: 4.2, full_request_avg_ms: 16.5, etc. }},
      #             2: { day: '07-17-2019', stats: { retrieve_avg_ms: 12.3, graph_load_avg_ms: 2.1, normalization_avg_ms: 4.2, full_request_avg_ms: 16.5, etc. }},
      #             ...,
      #             29: { day: 'TODAY', stats: { retrieve_avg_ms: 12.3, graph_load_avg_ms: 2.1, normalization_avg_ms: 4.2, full_request_avg_ms: 16.5, etc. }}
      #           },
      #         year:
      #           { 0: { month: '09-2019', stats: { retrieve_avg_ms: 12.3, graph_load_avg_ms: 2.1, normalization_avg_ms: 4.2, full_request_avg_ms: 16.5, etc. }},
      #             1: { month: '10-2019', stats: { retrieve_avg_ms: 12.3, graph_load_avg_ms: 2.1, normalization_avg_ms: 4.2, full_request_avg_ms: 16.5, etc. }},
      #             2: { month: '11-2019', stats: { retrieve_avg_ms: 12.3, graph_load_avg_ms: 2.1, normalization_avg_ms: 4.2, full_request_avg_ms: 16.5, etc. }},
      #             ...,
      #             11: { month: '08-2019', stats: { retrieve_avg_ms: 12.3, graph_load_avg_ms: 2.1, normalization_avg_ms: 4.2, full_request_avg_ms: 16.5, etc. }}
      #           }
      #       },
      #       fetch: { ... # same data as for search_stats },
      #       all: { ... # same data as for search_stats }
      #     },
      #     AGROVOC_LD4L_CACHE: { ... # same data for each authority  }
      #   }
      def performance_graph_data(force: false)
        graph_data_service_class.calculate_graph_data(force: force)
      end
    end
  end
end
