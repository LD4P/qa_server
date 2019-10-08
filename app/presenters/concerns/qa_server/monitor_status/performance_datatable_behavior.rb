# frozen_string_literal: true
# This module provides access methods into the performance data hash.
module QaServer::MonitorStatus
  module PerformanceDatatableBehavior
    include QaServer::PerformanceHistoryDataKeys

    def datatable_stats(authority_data)
      authority_data[FOR_DATATABLE]
    end

    def low_retrieve(stats)
      format_stat stats[LOW_RETR]
    end

    def low_graph_load(stats)
      format_stat stats[LOW_GRPH]
    end

    def low_normalization(stats)
      format_stat stats[LOW_NORM]
    end

    def low_full_request(stats)
      format_stat stats[LOW_ACTN]
    end

    def high_retrieve(stats)
      format_stat stats[HIGH_RETR]
    end

    def high_graph_load(stats)
      format_stat stats[HIGH_GRPH]
    end

    def high_normalization(stats)
      format_stat stats[HIGH_NORM]
    end

    def high_full_request(stats)
      format_stat stats[HIGH_ACTN]
    end

    def avg_retrieve(stats)
      format_stat stats[AVG_RETR]
    end

    def avg_graph_load(stats)
      format_stat stats[AVG_GRPH]
    end

    def avg_normalization(stats)
      format_stat stats[AVG_NORM]
    end

    def avg_full_request(stats)
      format_stat stats[AVG_ACTN]
    end

    def low_full_request_style(stats)
      performance_style_class(stats, LOW_ACTN)
    end

    def high_full_request_style(stats)
      performance_style_class(stats, HIGH_ACTN)
    end

    def avg_full_request_style(stats)
      performance_style_class(stats, AVG_ACTN)
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
        return '' if stat.nil?
        format("%0.1f", stat)
      end

      def performance_style_class(stats, stat_key)
        return "status-bad" if max_threshold_exceeded(stats, stat_key)
        return "status-unknown" if desired_threshold_not_met(stats, stat_key)
        "status-good"
      end

      def max_threshold_exceeded(stats, stat_key)
        return false if stats[stat_key].nil?
        return true if stats[stat_key] > QaServer.config.performance_datatable_max_threshold
        false
      end

      def desired_threshold_not_met(stats, stat_key)
        return false if stats[stat_key].nil?
        return true unless stats[stat_key] < QaServer.config.performance_datatable_warning_threshold
        false
      end
  end
end
