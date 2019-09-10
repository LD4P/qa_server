# frozen_string_literal: true
# This module provides access methods into the performance data hash.
module QaServer::MonitorStatus
  module PerformanceDatatableBehavior
    include QaServer::PerformanceHistoryDataKeys

    def datatable_stats(authority_data)
      authority_data[FOR_DATATABLE]
    end

    def low_load(stats)
      format_stat stats[LOW_LOAD]
    end

    def low_normalization(stats)
      format_stat stats[LOW_NORM]
    end

    def low_full_request(stats)
      format_stat stats[LOW_FULL]
    end

    def high_load(stats)
      format_stat stats[HIGH_LOAD]
    end

    def high_normalization(stats)
      format_stat stats[HIGH_NORM]
    end

    def high_full_request(stats)
      format_stat stats[HIGH_FULL]
    end

    def avg_load(stats)
      format_stat stats[AVG_LOAD]
    end

    def avg_normalization(stats)
      format_stat stats[AVG_NORM]
    end

    def avg_full_request(stats)
      format_stat stats[AVG_FULL]
    end

    def low_full_request_style(stats)
      performance_style_class(stats, LOW_FULL)
    end

    def high_full_request_style(stats)
      performance_style_class(stats, HIGH_FULL)
    end

    def avg_full_request_style(stats)
      performance_style_class(stats, AVG_FULL)
    end

    def performance_table_description
      case expected_time_period
      when :day
        I18n.t('qa_server.monitor_status.performance.datatable_day_desc')
      when :month
        I18n.t('qa_server.monitor_status.performance.datatable_month_desc')
      when :year
        I18n.t('qa_server.monitor_status.performance.datatable_year_desc')
      else
        I18n.t('qa_server.monitor_status.performance.datatable_all_desc')
      end
    end

    private

      def expected_time_period
        QaServer.config.performance_datatable_default_time_period
      end

      def format_stat(stat)
        format("%0.1f", stat)
      end

      def performance_style_class(stats, stat_key)
        return "status-bad" if max_threshold_exceeded(stats, stat_key)
        return "status-unknown" if desired_threshold_not_met(stats, stat_key)
        "status-good"
      end

      def max_threshold_exceeded(stats, stat_key)
        return true if stats[stat_key] > QaServer.config.performance_datatable_max_threshold
        false
      end

      def desired_threshold_not_met(stats, stat_key)
        return true unless stats[stat_key] < QaServer.config.performance_datatable_warning_threshold
        false
      end
  end
end
