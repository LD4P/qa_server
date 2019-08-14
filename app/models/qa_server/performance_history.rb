# frozen_string_literal: true
# Provide access to the scenario_results_history database table which tracks specific scenario runs over time.
module QaServer
  class PerformanceHistory < ActiveRecord::Base
    self.table_name = 'performance_history'

    enum action: [:fetch, :search]

    PERFORMANCE_FOR_DAY_KEY = :day
    PERFORMANCE_BY_HOUR_KEY = :hour

    PERFORMANCE_FOR_MONTH_KEY = :month
    PERFORMANCE_BY_DAY_KEY = :day

    PERFORMANCE_FOR_YEAR_KEY = :year
    PERFORMANCE_BY_MONTH_KEY = :month

    LOAD_TIME_KEY = :load_avg_ms
    NORMALIZATION_TIME_KEY = :normalization_avg_ms
    COMBINED_TIME_KEY = :combined_avg_ms

    class << self

      # Save a scenario result
      # @param run_id [Integer] the run on which to gather statistics
      # @param result [Hash] the scenario result to be saved
      def save_result(dt_stamp:, authority:, action:, size_bytes:, load_time_ms:, normalization_time_ms: )
        QaServer::PerformanceHistory.create(dt_stamp: dt_stamp,
                                            authority: authority,
                                            action: action,
                                            size_bytes: size_bytes,
                                            load_time_ms: load_time_ms,
                                            normalization_time_ms: normalization_time_ms)
      end

      # Performance data for a day, a month, and a year.
      # @returns [Hash] performance statistics for the past 24 hours
      # @example
      #   { 0: { hour: 1400, load_avg_ms: 12.3, normalization_avg_ms: 4.2 },
      #     1: { hour: 1500, load_avg_ms: 12.3, normalization_avg_ms: 4.2 },
      #     2: { hour: 1600, load_avg_ms: 12.3, normalization_avg_ms: 4.2 },
      #     ...,
      #     23: { hour: 1300, load_avg_ms: 12.3, normalization_avg_ms: 4.2 }
      #   }
      def performance_data
        data = {}
        data[PERFORMANCE_FOR_DAY_KEY] = average_last_24_hours
        data[PERFORMANCE_FOR_MONTH_KEY] = average_last_30_days
        data[PERFORMANCE_FOR_YEAR_KEY] = average_last_12_months
        data
      end

      private

        # Get hourly average for the past 24 hours.
        # @returns [Hash] performance statistics for the past 24 hours
        # @example
        #   { 0: { hour: 1400, load_avg_ms: 12.3, normalization_avg_ms: 4.2, combined_avg_ms: 16.5 },
        #     1: { hour: 1500, load_avg_ms: 12.3, normalization_avg_ms: 4.2, combined_avg_ms: 16.5 },
        #     2: { hour: 1600, load_avg_ms: 12.3, normalization_avg_ms: 4.2, combined_avg_ms: 16.5 },
        #     ...,
        #     23: { hour: 1300, load_avg_ms: 12.3, normalization_avg_ms: 4.2, combined_avg_ms: 16.5 }
        #   }
        def average_last_24_hours
          start_hour = Time.now.beginning_of_hour - 23.hour
          avgs = {}
          0.upto(23).each do |idx|
            records = PerformanceHistory.where(dt_stamp: start_hour..start_hour.end_of_hour)
            averages = calculate_averages(records)
            data = {}
            data[PERFORMANCE_BY_HOUR_KEY] = idx == 23 ? I18n.t('qa_server.monitor_status.performance.now') : ((idx + 1) % 2 == 0 ? (start_hour.hour * 100).to_s : "")
            data[LOAD_TIME_KEY] = averages[:avg_load_time_ms]
            data[NORMALIZATION_TIME_KEY] = averages[:avg_normalization_time_ms]
            data[COMBINED_TIME_KEY] = averages[:avg_combined_time_ms]
            avgs[idx] = data
            start_hour = start_hour + 1.hour
          end
          avgs
        end

        # Get daily average for the past 30 days.
        # @returns [Hash] performance statistics for the past 30 days
        # @example
        #   { 0: { day: '07-15-2019', load_avg_ms: 12.3, normalization_avg_ms: 4.2, combined_avg_ms: 16.5 },
        #     1: { day: '07-16-2019', load_avg_ms: 12.3, normalization_avg_ms: 4.2, combined_avg_ms: 16.5 },
        #     2: { day: '07-17-2019', load_avg_ms: 12.3, normalization_avg_ms: 4.2, combined_avg_ms: 16.5 },
        #     ...,
        #     29: { day: '08-13-2019', load_avg_ms: 12.3, normalization_avg_ms: 4.2, combined_avg_ms: 16.5 }
        #   }
        def average_last_30_days
          start_day = Time.now.beginning_of_day - 29.day
          avgs = {}
          0.upto(29).each do |idx|
            records = PerformanceHistory.where(dt_stamp: start_day..start_day.end_of_day)
            averages = calculate_averages(records)
            data = {}
            data[PERFORMANCE_BY_DAY_KEY] = idx == 29 ? I18n.t('qa_server.monitor_status.performance.today') : ((idx + 1) % 5 == 0 ? (start_day).strftime("%m-%d") : "")
            data[LOAD_TIME_KEY] = averages[:avg_load_time_ms]
            data[NORMALIZATION_TIME_KEY] = averages[:avg_normalization_time_ms]
            data[COMBINED_TIME_KEY] = averages[:avg_combined_time_ms]
            avgs[idx] = data
            start_day = start_day + 1.day
          end
          avgs
        end

        # Get daily average for the past 12 months.
        # @returns [Hash] performance statistics for the past 12 months
        # @example
        #   { 0: { month: '09-2019', load_avg_ms: 12.3, normalization_avg_ms: 4.2, combined_avg_ms: 16.5 },
        #     1: { month: '10-2019', load_avg_ms: 12.3, normalization_avg_ms: 4.2, combined_avg_ms: 16.5 },
        #     2: { month: '11-2019', load_avg_ms: 12.3, normalization_avg_ms: 4.2, combined_avg_ms: 16.5 },
        #     ...,
        #     11: { month: '08-2019', load_avg_ms: 12.3, normalization_avg_ms: 4.2, combined_avg_ms: 16.5 }
        #   }
        def average_last_12_months
          start_month = Time.now.beginning_of_month - 11.month
          avgs = {}
          0.upto(11).each do |idx|
            records = PerformanceHistory.where(dt_stamp: start_month..start_month.end_of_month)
            averages = calculate_averages(records)
            data = {}
            data[PERFORMANCE_BY_MONTH_KEY] = (start_month).strftime("%m-%Y")
            data[LOAD_TIME_KEY] = averages[:avg_load_time_ms]
            data[NORMALIZATION_TIME_KEY] = averages[:avg_normalization_time_ms]
            data[COMBINED_TIME_KEY] = averages[:avg_combined_time_ms]
            avgs[idx] = data
            start_month = start_month + 1.month
          end
          avgs
        end

        def calculate_averages(records)
          return { avg_load_time_ms: 0, avg_normalization_time_ms: 0, avg_combined_time_ms: 0 } if records.count.zero?
          sum_load_times = 0
          sum_normalization_times = 0
          sum_combined_times = 0
          records.each do |record|
            sum_load_times += record.load_time_ms
            sum_normalization_times += record.normalization_time_ms
            sum_combined_times += (record.load_time_ms + record.normalization_time_ms)
          end
          {
            avg_load_time_ms: sum_load_times / records.count,
            avg_normalization_time_ms: sum_normalization_times / records.count,
            avg_combined_time_ms: sum_combined_times / records.count
          }
        end
    end
  end
end
