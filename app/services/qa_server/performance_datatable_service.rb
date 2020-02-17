# frozen_string_literal: true
# This class calculates performance stats for the performance datatable.
module QaServer
  class PerformanceDatatableService
    class << self
      include QaServer::PerformanceHistoryDataKeys

      class_attribute :stats_calculator_class, :performance_data_class, :authority_list_class
      self.stats_calculator_class = QaServer::PerformanceCalculatorService
      self.performance_data_class = QaServer::PerformanceHistory
      self.authority_list_class = QaServer::AuthorityListerService

      # Summary of performance by action for each authority for the configured time period (e.g. :day, :month, :year, :all).
      # @param force [Boolean] if true, calculate the stats even if the cache hasn't expired; otherwise, use cache if not expired
      # @returns [Hash] performance statistics for configured time period by action for each authority
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
      def calculate_datatable_data(force:)
        Rails.cache.fetch("QaServer::PerformanceDatatableService/#{__method__}", expires_in: QaServer::MonitorCacheService.cache_expiry, race_condition_ttl: 5.minutes, force: force) do
          QaServer.config.monitor_logger.debug("(QaServer::PerformanceDatatableService##{__method__}) - CALCULATING performance datatable stats - cache expired or refresh requested (force: #{force})")
          data = {}
          auths = authority_list_class.authorities_list
          data[ALL_AUTH] = datatable_data_for_authority
          auths.each { |auth_name| data[auth_name] = datatable_data_for_authority(authority_name: auth_name) }
          data
        end
      end

      private

        def datatable_data_for_authority(authority_name: nil)
          [:search, :fetch, :all_actions].each_with_object({}) do |action, hash|
            hash[action] = data_table_stats(authority_name, action)
          end
        end

        # Get statistics for data table.
        # @param auth_name [String] limit statistics to records for the given authority (default: all authorities)
        # @param action [Symbol] one of :search, :fetch, :all_actions
        # @returns [Hash] performance statistics for the datatable during the expected time period
        # @example
        #   { retrieve_avg_ms: 12.3, graph_load_avg_ms: 2.1, normalization_avg_ms: 4.2, full_request_avg_ms: 16.5,
        #     retrieve_10th_ms: 12.3, graph_load_10th_ms: 12.3, normalization_10th_ms: 4.2, full_request_10th_ms: 16.5,
        #     retrieve_90th_ms: 12.3, graph_load_90th_ms: 12.3, normalization_90th_ms: 4.2, full_request_90th_ms: 16.5 }
        def data_table_stats(auth_name, action)
          records = records_for_authority(auth_name)
          stats_calculator_class.new(records, action: action).calculate_stats_with_percentiles
        end

        def expected_time_period
          QaServer.config.performance_datatable_default_time_period
        end

        def records_for_authority(auth_name)
          case expected_time_period
          when :day
            QaServer.config.performance_cache.write_all # only need to write if just using today's data
            performance_data_class.where(QaServer::TimePeriodService.where_clause_for_last_24_hours(auth_name: auth_name))
          when :month
            performance_data_class.where(QaServer::TimePeriodService.where_clause_for_last_30_days(auth_name: auth_name))
          when :year
            performance_data_class.where(QaServer::TimePeriodService.where_clause_for_last_12_months(auth_name: auth_name))
          else
            all_records(auth_name)
          end
        end

        def all_records(auth_name)
          auth_name.nil? ? performance_data_class.all : performance_data_class.where(authority: auth_name)
        end
    end
  end
end
