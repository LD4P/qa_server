# frozen_string_literal: true
# This class sets performance stats for the last 24 hours, past 30 days, and the past 12 months.
module QaServer
  class PerformanceGraphDataService
    class << self
      include QaServer::PerformanceHistoryDataKeys

      class_attribute :stats_calculator_class, :performance_data_class
      self.stats_calculator_class = QaServer::PerformanceCalculatorService
      self.performance_data_class = QaServer::PerformanceHistory

      # Get hourly average for the past 24 hours.
      # @returns [Hash] performance statistics for the past 24 hours
      # @example
      #   { 0: { hour: '1400', stats: { load_avg_ms: 12.3, normalization_avg_ms: 4.2, full_request_avg_ms: 16.5, etc. }},
      #     1: { hour: '1500', stats: { load_avg_ms: 12.3, normalization_avg_ms: 4.2, full_request_avg_ms: 16.5, etc. }},
      #     2: { hour: '1600', stats: { load_avg_ms: 12.3, normalization_avg_ms: 4.2, full_request_avg_ms: 16.5, etc. }},
      #     ...,
      #     23: { hour: 'NOW', stats: { load_avg_ms: 12.3, normalization_avg_ms: 4.2, full_request_avg_ms: 16.5, etc. }}
      #   }
      def average_last_24_hours(authority_name: nil, action: nil)
        start_hour = Time.now.getlocal.beginning_of_hour - 23.hours
        avgs = {}
        0.upto(23).each do |idx|
          records = records_by(authority_name, action, start_hour..start_hour.end_of_hour)
          stats = stats_calculator_class.new(records).calculate_stats(avg: true, full: false)
          data = {}
          data[BY_HOUR] = performance_by_hour_label(idx, start_hour)
          data[STATS] = stats
          avgs[idx] = data
          start_hour += 1.hour
        end
        avgs
      end

      # Get daily average for the past 30 days.
      # @returns [Hash] performance statistics for the past 30 days
      # @example
      #   { 0: { day: '07-15-2019', stats: { load_avg_ms: 12.3, normalization_avg_ms: 4.2, full_request_avg_ms: 16.5, etc. }},
      #     1: { day: '07-16-2019', stats: { load_avg_ms: 12.3, normalization_avg_ms: 4.2, full_request_avg_ms: 16.5, etc. }},
      #     2: { day: '07-17-2019', stats: { load_avg_ms: 12.3, normalization_avg_ms: 4.2, full_request_avg_ms: 16.5, etc. }},
      #     ...,
      #     29: { day: 'TODAY', stats: { load_avg_ms: 12.3, normalization_avg_ms: 4.2, full_request_avg_ms: 16.5, etc. }}
      #   }
      def average_last_30_days(authority_name: nil, action: nil)
        start_day = Time.now.getlocal.beginning_of_day - 29.days
        avgs = {}
        0.upto(29).each do |idx|
          records = records_by(authority_name, action, start_day..start_day.end_of_day)
          stats = stats_calculator_class.new(records).calculate_stats(avg: true, full: false)
          data = {}
          data[BY_DAY] = performance_by_day_label(idx, start_day)
          data[STATS] = stats
          avgs[idx] = data
          start_day += 1.day
        end
        avgs
      end

      # Get daily average for the past 12 months.
      # @returns [Hash] performance statistics for the past 12 months
      # @example
      #   { 0: { month: '09-2019', stats: { load_avg_ms: 12.3, normalization_avg_ms: 4.2, full_request_avg_ms: 16.5, etc. }},
      #     1: { month: '10-2019', stats: { load_avg_ms: 12.3, normalization_avg_ms: 4.2, full_request_avg_ms: 16.5, etc. }},
      #     2: { month: '11-2019', stats: { load_avg_ms: 12.3, normalization_avg_ms: 4.2, full_request_avg_ms: 16.5, etc. }},
      #     ...,
      #     11: { month: '08-2019', stats: { load_avg_ms: 12.3, normalization_avg_ms: 4.2, full_request_avg_ms: 16.5, etc. }}
      #   }
      def average_last_12_months(authority_name: nil, action: nil)
        start_month = Time.now.getlocal.beginning_of_month - 11.months
        avgs = {}
        0.upto(11).each do |idx|
          records = records_by(authority_name, action, start_month..start_month.end_of_month)
          stats = stats_calculator_class.new(records).calculate_stats(avg: true, full: false)
          data = {}
          data[BY_MONTH] = start_month.strftime("%m-%Y")
          data[STATS] = stats
          avgs[idx] = data
          start_month += 1.month
        end
        avgs
      end

      private

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
    end
  end
end