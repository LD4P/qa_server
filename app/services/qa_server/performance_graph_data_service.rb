# frozen_string_literal: true
# This class sets performance stats for the last 24 hours, past 30 days, and the past 12 months.
module QaServer
  class PerformanceGraphDataService # rubocop:disable Metrics/ClassLength
    class << self
      include QaServer::PerformanceHistoryDataKeys

      class_attribute :stats_calculator_class, :performance_data_class, :authority_list_class
      self.stats_calculator_class = QaServer::PerformanceCalculatorService
      self.performance_data_class = QaServer::PerformanceHistory
      self.authority_list_class = QaServer::AuthorityListerService

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
      def calculate_graph_data(force:)
        QaServer.config.performance_cache.write_all
        data = {}
        auths = authority_list_class.authorities_list
        calculate_all = force || cache_expired?
        QaServer.config.monitor_logger.debug("(QaServer::PerformanceGraphDataService##{__method__}) - CALCULATING performance graph data (calculate_all: #{calculate_all})")
        data[ALL_AUTH] = graph_data_for_authority(force: force, calculate_all: calculate_all)
        auths.each { |auth_name| data[auth_name] = graph_data_for_authority(authority_name: auth_name, force: force, calculate_all: calculate_all) }
        data
      end

      private

        def graph_data_for_authority(authority_name: nil, force:, calculate_all:)
          [:search, :fetch, :all_actions].each_with_object({}) do |action, hash|
            data = {}
            data[FOR_DAY] = average_last_24_hours(authority_name: authority_name, action: action, force: force)
            data[FOR_MONTH] = average_last_30_days(authority_name: authority_name, action: action, force: force) if calculate_all
            data[FOR_YEAR] = average_last_12_months(authority_name: authority_name, action: action, force: force) if calculate_all
            hash[action] = data
          end
        end

        # Get hourly average for the past 24 hours.
        # @param authority_name [String] limit statistics to records for the given authority (default: all authorities)
        # @param action [Symbol] one of :search, :fetch, :all_actions
        # @param force [Boolean] if true, forces cache to regenerate; otherwise, returns value from cache unless expired
        # @returns [Hash] performance statistics for the past 24 hours
        # @example
        #   { 0: { hour: '1400', stats: { load_avg_ms: 12.3, normalization_avg_ms: 4.2, full_request_avg_ms: 16.5, etc. }},
        #     1: { hour: '1500', stats: { load_avg_ms: 12.3, normalization_avg_ms: 4.2, full_request_avg_ms: 16.5, etc. }},
        #     2: { hour: '1600', stats: { load_avg_ms: 12.3, normalization_avg_ms: 4.2, full_request_avg_ms: 16.5, etc. }},
        #     ...,
        #     23: { hour: 'NOW', stats: { load_avg_ms: 12.3, normalization_avg_ms: 4.2, full_request_avg_ms: 16.5, etc. }}
        #   }
        def average_last_24_hours(authority_name: nil, action: nil, force: false)
          avgs = Rails.cache.fetch("QaServer::PerformanceGraphDataService/#{__method__}/#{authority_name || ALL_AUTH}/#{action}/#{FOR_DAY}",
                                   expires_in: QaServer::TimeService.current_time.end_of_hour - QaServer::TimeService.current_time,
                                   race_condition_ttl: 1.hour, force: force) do
            calculate_last_24_hours(authority_name, action)
          end
          calculate_last_hour(authority_name, action, avgs)
        end

        # Get daily average for the past 30 days.
        # @param authority_name [String] limit statistics to records for the given authority (default: all authorities)
        # @param action [Symbol] one of :search, :fetch, :all_actions
        # @param force [Boolean] if true, forces cache to regenerate; otherwise, returns value from cache unless expired
        # @returns [Hash] performance statistics for the past 30 days
        # @example
        #   { 0: { day: '07-15-2019', stats: { load_avg_ms: 12.3, normalization_avg_ms: 4.2, full_request_avg_ms: 16.5, etc. }},
        #     1: { day: '07-16-2019', stats: { load_avg_ms: 12.3, normalization_avg_ms: 4.2, full_request_avg_ms: 16.5, etc. }},
        #     2: { day: '07-17-2019', stats: { load_avg_ms: 12.3, normalization_avg_ms: 4.2, full_request_avg_ms: 16.5, etc. }},
        #     ...,
        #     29: { day: 'TODAY', stats: { load_avg_ms: 12.3, normalization_avg_ms: 4.2, full_request_avg_ms: 16.5, etc. }}
        #   }
        def average_last_30_days(authority_name: nil, action: nil, force: false)
          Rails.cache.fetch("QaServer::PerformanceGraphDataService/#{__method__}/#{authority_name || ALL_AUTH}/#{action}/#{FOR_MONTH}",
                            expires_in: QaServer::CacheExpiryService.cache_expiry, race_condition_ttl: 1.hour, force: force) do
            calculate_last_30_days(authority_name, action)
          end
        end

        # Get daily average for the past 12 months.
        # @param authority_name [String] limit statistics to records for the given authority (default: all authorities)
        # @param action [Symbol] one of :search, :fetch, :all_actions
        # @param force [Boolean] if true, forces cache to regenerate; otherwise, returns value from cache unless expired
        # @returns [Hash] performance statistics for the past 12 months
        # @example
        #   { 0: { month: '09-2019', stats: { load_avg_ms: 12.3, normalization_avg_ms: 4.2, full_request_avg_ms: 16.5, etc. }},
        #     1: { month: '10-2019', stats: { load_avg_ms: 12.3, normalization_avg_ms: 4.2, full_request_avg_ms: 16.5, etc. }},
        #     2: { month: '11-2019', stats: { load_avg_ms: 12.3, normalization_avg_ms: 4.2, full_request_avg_ms: 16.5, etc. }},
        #     ...,
        #     11: { month: '08-2019', stats: { load_avg_ms: 12.3, normalization_avg_ms: 4.2, full_request_avg_ms: 16.5, etc. }}
        #   }
        def average_last_12_months(authority_name: nil, action: nil, force: false)
          Rails.cache.fetch("QaServer::PerformanceGraphDataService/#{__method__}/#{authority_name || ALL_AUTH}/#{action}/#{FOR_YEAR}",
                            expires_in: QaServer::CacheExpiryService.cache_expiry, race_condition_ttl: 1.hour, force: force) do
            calculate_last_12_months(authority_name, action)
          end
        end

        def records_by(authority_name, action, time_period)
          where_clause = { dt_stamp: time_period }
          where_clause[:authority] = authority_name unless authority_name.nil?
          where_clause[:action] = action unless action.nil? || action == :all_actions
          performance_data_class.where(where_clause)
        end

        def performance_by_hour_label(idx, start_hour)
          if idx == 23
            I18n.t('qa_server.monitor_status.performance.now')
          elsif ((idx + 1) % 2).zero?
            (start_hour.hour * 100).to_s
          else
            ""
          end
        end

        def performance_by_day_label(idx, start_day)
          if idx == 29
            I18n.t('qa_server.monitor_status.performance.today')
          elsif ((idx + 1) % 5).zero?
            start_day.strftime("%m-%d")
          else
            ""
          end
        end

        def calculate_from_records(records, range_idx, range_label)
          stats = stats_calculator_class.new(records).calculate_average_stats
          { STATS => stats, range_idx => range_label }
        end

        def calculate_last_hour(authority_name, action, avgs)
          start_hour = QaServer::TimeService.current_time.beginning_of_hour
          records = records_by(authority_name, action, start_hour..start_hour.end_of_hour)
          avgs[23] = calculate_from_records(records, BY_HOUR, performance_by_hour_label(23, start_hour))
          avgs
        end

        def calculate_last_24_hours(authority_name, action)
          start_hour = QaServer::TimeService.current_time.beginning_of_hour - 23.hours
          0.upto(23).each_with_object({}) do |idx, avgs|
            records = records_by(authority_name, action, start_hour..start_hour.end_of_hour)
            avgs[idx] = calculate_from_records(records, BY_HOUR, performance_by_hour_label(idx, start_hour))
            start_hour += 1.hour
          end
        end

        def calculate_last_30_days(authority_name, action)
          start_day = QaServer::TimeService.current_time.beginning_of_day - 29.days
          0.upto(29).each_with_object({}) do |idx, avgs|
            records = records_by(authority_name, action, start_day..start_day.end_of_day)
            avgs[idx] = calculate_from_records(records, BY_DAY, performance_by_day_label(idx, start_day))
            start_day += 1.day
          end
        end

        def calculate_last_12_months(authority_name, action)
          start_month = QaServer::TimeService.current_time.beginning_of_month - 11.months
          0.upto(11).each_with_object({}) do |idx, avgs|
            records = records_by(authority_name, action, start_month..start_month.end_of_month)
            avgs[idx] = calculate_from_records(records, BY_MONTH, start_month.strftime("%m-%Y"))
            start_month += 1.month
          end
        end

        # @returns [Boolean] true if cache has expired; otherwise, false
        def cache_expired?
          expired = Rails.cache.fetch("QaServer::PerformanceGraphDataService/#{__method__}", expires_in: 5.seconds) { true }
          Rails.cache.fetch("QaServer::PerformanceGraphDataService/#{__method__}", expires_in: QaServer::CacheExpiryService.cache_expiry, force: expired) { false } # reset if expired
          expired
        end
    end
  end
end
