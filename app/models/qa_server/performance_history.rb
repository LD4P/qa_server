# frozen_string_literal: true
# Provide access to the scenario_results_history database table which tracks specific scenario runs over time.
module QaServer
  class PerformanceHistory < ActiveRecord::Base # rubocop:disable Metrics/ClassLength
    self.table_name = 'performance_history'

    enum action: [:fetch, :search]

    PERFORMANCE_ALL_KEY = :all_authorities
    PERFORMANCE_STATS_KEY = :stats

    PERFORMANCE_FOR_DAY_KEY = :day
    PERFORMANCE_BY_HOUR_KEY = :hour

    PERFORMANCE_FOR_MONTH_KEY = :month
    PERFORMANCE_BY_DAY_KEY = :day

    PERFORMANCE_FOR_YEAR_KEY = :year
    PERFORMANCE_BY_MONTH_KEY = :month

    SUM_LOAD_TIME_KEY = :load_sum_ms
    SUM_NORMALIZATION_TIME_KEY = :normalization_sum_ms
    SUM_COMBINED_TIME_KEY = :combined_sum_ms
    MIN_LOAD_TIME_KEY = :load_min_ms
    MIN_NORMALIZATION_TIME_KEY = :normalization_min_ms
    MIN_COMBINED_TIME_KEY = :combined_min_ms
    MAX_LOAD_TIME_KEY = :load_max_ms
    MAX_NORMALIZATION_TIME_KEY = :normalization_max_ms
    MAX_COMBINED_TIME_KEY = :combined_max_ms
    AVG_LOAD_TIME_KEY = :load_avg_ms
    AVG_NORMALIZATION_TIME_KEY = :normalization_avg_ms
    AVG_COMBINED_TIME_KEY = :combined_avg_ms

    class << self
      # Save a scenario result
      # @param run_id [Integer] the run on which to gather statistics
      # @param result [Hash] the scenario result to be saved
      def save_result(dt_stamp:, authority:, action:, size_bytes:, load_time_ms:, normalization_time_ms:) # rubocop:disable Metrics/ParameterLists
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
        data[PERFORMANCE_ALL_KEY] = {
          PERFORMANCE_FOR_DAY_KEY => average_last_24_hours,
          PERFORMANCE_FOR_MONTH_KEY => average_last_30_days,
          PERFORMANCE_FOR_YEAR_KEY => average_last_12_months
        }
        data
      end

      private

        # Get hourly average for the past 24 hours.
        # @returns [Hash] performance statistics for the past 24 hours
        # @example
        #   { 0: { hour: 1400, stats: { load_avg_ms: 12.3, normalization_avg_ms: 4.2, combined_avg_ms: 16.5, etc. }},
        #     1: { hour: 1500, stats: { load_avg_ms: 12.3, normalization_avg_ms: 4.2, combined_avg_ms: 16.5, etc. }},
        #     2: { hour: 1600, stats: { load_avg_ms: 12.3, normalization_avg_ms: 4.2, combined_avg_ms: 16.5, etc. }},
        #     ...,
        #     23: { hour: 1300, stats: { load_avg_ms: 12.3, normalization_avg_ms: 4.2, combined_avg_ms: 16.5, etc. }}
        #   }
        def average_last_24_hours
          start_hour = Time.now.beginning_of_hour - 23.hours
          avgs = {}
          0.upto(23).each do |idx|
            records = PerformanceHistory.where(dt_stamp: start_hour..start_hour.end_of_hour)
            stats = calculate_stats(records)
            data = {}
            data[PERFORMANCE_BY_HOUR_KEY] = performance_by_hour_label(idx, start_hour)
            data[PERFORMANCE_STATS_KEY] = stats
            avgs[idx] = data
            start_hour += 1.hour
          end
          avgs
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

        # Get daily average for the past 30 days.
        # @returns [Hash] performance statistics for the past 30 days
        # @example
        #   { 0: { day: '07-15-2019', stats: { load_avg_ms: 12.3, normalization_avg_ms: 4.2, combined_avg_ms: 16.5, etc. }},
        #     1: { day: '07-16-2019', stats: { load_avg_ms: 12.3, normalization_avg_ms: 4.2, combined_avg_ms: 16.5, etc. }},
        #     2: { day: '07-17-2019', stats: { load_avg_ms: 12.3, normalization_avg_ms: 4.2, combined_avg_ms: 16.5, etc. }},
        #     ...,
        #     29: { day: '08-13-2019', stats: { load_avg_ms: 12.3, normalization_avg_ms: 4.2, combined_avg_ms: 16.5, etc. }}
        #   }
        def average_last_30_days
          start_day = Time.now.beginning_of_day - 29.days
          avgs = {}
          0.upto(29).each do |idx|
            records = PerformanceHistory.where(dt_stamp: start_day..start_day.end_of_day)
            stats = calculate_stats(records)
            data = {}
            data[PERFORMANCE_BY_DAY_KEY] = performance_by_day_label(idx, start_day)
            data[PERFORMANCE_STATS_KEY] = stats
            avgs[idx] = data
            start_day += 1.day
          end
          avgs
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

        # Get daily average for the past 12 months.
        # @returns [Hash] performance statistics for the past 12 months
        # @example
        #   { 0: { month: '09-2019', stats: { load_avg_ms: 12.3, normalization_avg_ms: 4.2, combined_avg_ms: 16.5, etc. }},
        #     1: { month: '10-2019', stats: { load_avg_ms: 12.3, normalization_avg_ms: 4.2, combined_avg_ms: 16.5, etc. }},
        #     2: { month: '11-2019', stats: { load_avg_ms: 12.3, normalization_avg_ms: 4.2, combined_avg_ms: 16.5, etc. }},
        #     ...,
        #     11: { month: '08-2019', stats: { load_avg_ms: 12.3, normalization_avg_ms: 4.2, combined_avg_ms: 16.5, etc. }}
        #   }
        def average_last_12_months
          start_month = Time.now.beginning_of_month - 11.months
          avgs = {}
          0.upto(11).each do |idx|
            records = PerformanceHistory.where(dt_stamp: start_month..start_month.end_of_month)
            stats = calculate_stats(records)
            data = {}
            data[PERFORMANCE_BY_MONTH_KEY] = start_month.strftime("%m-%Y")
            data[PERFORMANCE_STATS_KEY] = stats
            avgs[idx] = data
            start_month += 1.month
          end
          avgs
        end

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

        MIN_STARTING_TIME = 999_999_999
        def init_stats
          stats = {}
          stats[SUM_LOAD_TIME_KEY] = 0
          stats[SUM_NORMALIZATION_TIME_KEY] = 0
          stats[SUM_COMBINED_TIME_KEY] = 0
          stats[AVG_LOAD_TIME_KEY] = 0
          stats[AVG_NORMALIZATION_TIME_KEY] = 0
          stats[AVG_COMBINED_TIME_KEY] = 0
          stats[MIN_LOAD_TIME_KEY] = MIN_STARTING_TIME
          stats[MIN_NORMALIZATION_TIME_KEY] = MIN_STARTING_TIME
          stats[MIN_COMBINED_TIME_KEY] = MIN_STARTING_TIME
          stats[MAX_LOAD_TIME_KEY] = 0
          stats[MAX_NORMALIZATION_TIME_KEY] = 0
          stats[MAX_COMBINED_TIME_KEY] = 0
          stats
        end

        def update_sum_stats(stats, record)
          stats[SUM_LOAD_TIME_KEY] += record.load_time_ms
          stats[SUM_NORMALIZATION_TIME_KEY] += record.normalization_time_ms
          stats[SUM_COMBINED_TIME_KEY] += combined_time_ms(record)
        end

        def update_min_stats(stats, record)
          stats[MIN_LOAD_TIME_KEY] = [stats[MIN_LOAD_TIME_KEY], record.load_time_ms].min
          stats[MIN_NORMALIZATION_TIME_KEY] = [stats[MIN_NORMALIZATION_TIME_KEY], record.normalization_time_ms].min
          stats[MIN_COMBINED_TIME_KEY] = [stats[MIN_COMBINED_TIME_KEY], combined_time_ms(record)].min
        end

        def update_max_stats(stats, record)
          stats[MAX_LOAD_TIME_KEY] = [stats[MAX_LOAD_TIME_KEY], record.load_time_ms].max
          stats[MAX_NORMALIZATION_TIME_KEY] = [stats[MAX_NORMALIZATION_TIME_KEY], record.normalization_time_ms].max
          stats[MAX_COMBINED_TIME_KEY] = [stats[MAX_COMBINED_TIME_KEY], combined_time_ms(record)].max
        end

        def calculate_avg_stats(stats, records)
          stats[AVG_LOAD_TIME_KEY] = stats[SUM_LOAD_TIME_KEY] / records.count
          stats[AVG_NORMALIZATION_TIME_KEY] = stats[SUM_NORMALIZATION_TIME_KEY] / records.count
          stats[AVG_COMBINED_TIME_KEY] = stats[SUM_COMBINED_TIME_KEY] / records.count
        end

        def combined_time_ms(record)
          record.load_time_ms + record.normalization_time_ms
        end
    end
  end
end
