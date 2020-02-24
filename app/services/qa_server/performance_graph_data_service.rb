# frozen_string_literal: true
# This class calculates performance averages to be used to generate graphs for the last 24 hours, 30 days, and 12 months.
module QaServer
  class PerformanceGraphDataService
    class << self
      include QaServer::PerformanceHistoryDataKeys

      class_attribute :stats_calculator_class, :performance_data_class
      self.stats_calculator_class = QaServer::PerformanceCalculatorService
      self.performance_data_class = QaServer::PerformanceHistory

      # Performance data for the last 12 months for a specific authority and action
      # @param authority_name [String] name of an authority
      # @param action [Symbol] :search, :fetch, or :all_actions
      # @returns [Hash] performance statistics for the past 12 months
      # @example returns
      #   { 0: { month: '09-2019', stats: { retrieve_avg_ms: 12.3, graph_load_avg_ms: 2.1, normalization_avg_ms: 4.2, full_request_avg_ms: 16.5, etc. }},
      #     1: { month: '10-2019', stats: { retrieve_avg_ms: 12.3, graph_load_avg_ms: 2.1, normalization_avg_ms: 4.2, full_request_avg_ms: 16.5, etc. }},
      #     2: { month: '11-2019', stats: { retrieve_avg_ms: 12.3, graph_load_avg_ms: 2.1, normalization_avg_ms: 4.2, full_request_avg_ms: 16.5, etc. }},
      #     ...,
      #     11: { month: '08-2019', stats: { retrieve_avg_ms: 12.3, graph_load_avg_ms: 2.1, normalization_avg_ms: 4.2, full_request_avg_ms: 16.5, etc. }}
      #   }
      def calculate_last_12_months(authority_name:, action:)
        start_month = QaServer::TimeService.current_time.beginning_of_month - 11.months
        0.upto(11).each_with_object({}) do |idx, averages|
          records = records_by(authority_name, action, start_month..start_month.end_of_month)
          averages[idx] = calculate_from_records(records, BY_MONTH, start_month.strftime("%m-%Y"))
          start_month += 1.month
        end
      end

      # Performance data for the last 30 days for a specific authority and action
      # @param authority_name [String] name of an authority
      # @param action [Symbol] :search, :fetch, or :all_actions
      # @returns [Hash] performance statistics for the past 30 days
      # @example returns
      #   { 0: { day: '07-15-2019', stats: { retrieve_avg_ms: 12.3, graph_load_avg_ms: 2.1, normalization_avg_ms: 4.2, full_request_avg_ms: 16.5, etc. }},
      #     1: { day: '07-16-2019', stats: { retrieve_avg_ms: 12.3, graph_load_avg_ms: 2.1, normalization_avg_ms: 4.2, full_request_avg_ms: 16.5, etc. }},
      #     2: { day: '07-17-2019', stats: { retrieve_avg_ms: 12.3, graph_load_avg_ms: 2.1, normalization_avg_ms: 4.2, full_request_avg_ms: 16.5, etc. }},
      #     ...,
      #     29: { day: 'TODAY', stats: { retrieve_avg_ms: 12.3, graph_load_avg_ms: 2.1, normalization_avg_ms: 4.2, full_request_avg_ms: 16.5, etc. }}
      #   }
      def calculate_last_30_days(authority_name:, action:)
        start_day = QaServer::TimeService.current_time.beginning_of_day - 29.days
        0.upto(29).each_with_object({}) do |idx, averages|
          records = records_by(authority_name, action, start_day..start_day.end_of_day)
          averages[idx] = calculate_from_records(records, BY_DAY, performance_by_day_label(idx, start_day))
          start_day += 1.day
        end
      end

      # Performance data for the last 24 hours for a specific authority and action
      # @param authority_name [String] name of an authority
      # @param action [Symbol] :search, :fetch, or :all_actions
      # @returns [Hash] performance statistics for the past 24 hours
      # @example returns
      #   { 0: { hour: '1400', stats: { retrieve_avg_ms: 12.3, graph_load_avg_ms: 2.1, normalization_avg_ms: 4.2, full_request_avg_ms: 16.5, etc. }},
      #     1: { hour: '1500', stats: { retrieve_avg_ms: 12.3, graph_load_avg_ms: 2.1, normalization_avg_ms: 4.2, full_request_avg_ms: 16.5, etc. }},
      #     2: { hour: '1600', stats: { retrieve_avg_ms: 12.3, graph_load_avg_ms: 2.1, normalization_avg_ms: 4.2, full_request_avg_ms: 16.5, etc. }},
      #     ...,
      #     23: { hour: 'NOW', retrieve_avg_ms: 12.3, graph_load_avg_ms: 2.1, normalization_avg_ms: 4.2, full_request_avg_ms: 16.5, etc. }}
      #   }
      def calculate_last_24_hours(authority_name:, action:)
        start_hour = QaServer::TimeService.current_time.beginning_of_hour - 23.hours
        0.upto(23).each_with_object({}) do |idx, averages|
          records = records_by(authority_name, action, start_hour..start_hour.end_of_hour)
          averages[idx] = calculate_from_records(records, BY_HOUR, performance_by_hour_label(idx, start_hour))
          start_hour += 1.hour
        end
      end

      # Performance data for the last 24 hours for a specific authority and action
      # @param authority_name [String] name of an authority
      # @param action [Symbol] :search, :fetch, or :all_actions
      # @param averages [Hash] existing data for each hour
      # @returns [Hash] existing hourly data with the last hour updated
      # @example returns
      #   { 0: { hour: '1400', stats: { retrieve_avg_ms: 12.3, graph_load_avg_ms: 2.1, normalization_avg_ms: 4.2, full_request_avg_ms: 16.5, etc. }},
      #     1: { hour: '1500', stats: { retrieve_avg_ms: 12.3, graph_load_avg_ms: 2.1, normalization_avg_ms: 4.2, full_request_avg_ms: 16.5, etc. }},
      #     2: { hour: '1600', stats: { retrieve_avg_ms: 12.3, graph_load_avg_ms: 2.1, normalization_avg_ms: 4.2, full_request_avg_ms: 16.5, etc. }},
      #     ...,
      #     23: { hour: 'NOW', retrieve_avg_ms: 12.3, graph_load_avg_ms: 2.1, normalization_avg_ms: 4.2, full_request_avg_ms: 16.5, etc. }}
      #   }
      def recalculate_last_hour(authority_name:, action:, averages:)
        return calculate_last_24_hours(authority_name: authority_name, action: action) if averages.nil? || averages.empty?
        start_hour = QaServer::TimeService.current_time.beginning_of_hour
        records = records_by(authority_name, action, start_hour..start_hour.end_of_hour)
        averages[23] = calculate_from_records(records, BY_HOUR, performance_by_hour_label(23, start_hour))
        averages
      end

      private

        def records_by(authority_name, action, time_period)
          where_clause = { dt_stamp: time_period }
          where_clause[:authority] = authority_name unless authority_name.nil? || authority_name == ALL_AUTH
          where_clause[:action] = action unless action.nil? || action == ALL_ACTIONS
          performance_data_class.where(where_clause)
        end

        def performance_by_hour_label(idx, start_hour)
          if idx == 23
            I18n.t('qa_server.monitor_status.performance.now')
          elsif ((idx + 1) % 2).zero?
            (start_hour.hour * 100).to_s
          else
            " "
          end
        end

        def performance_by_day_label(idx, start_day)
          if idx == 29
            I18n.t('qa_server.monitor_status.performance.today')
          elsif ((idx + 1) % 5).zero?
            start_day.strftime("%m-%d")
          else
            " "
          end
        end

        def calculate_from_records(records, range_idx, range_label)
          stats = stats_calculator_class.new(records).calculate_average_stats
          { STATS => stats, range_idx => range_label }
        end
    end
  end
end
