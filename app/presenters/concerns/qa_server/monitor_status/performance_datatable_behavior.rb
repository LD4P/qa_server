# frozen_string_literal: true
# This module provides access methods into the performance data hash.
module QaServer::MonitorStatus
  module PerformanceDatatableBehavior # rubocop:disable Metrics/ModuleLength
    include QaServer::PerformanceHistoryDataKeys

    def datatable_search_stats(authority_data)
      data_table_for(authority_data, SEARCH)
    end

    def datatable_fetch_stats(authority_data)
      data_table_for(authority_data, FETCH)
    end

    def datatable_all_actions_stats(authority_data)
      data_table_for(authority_data, ALL_ACTIONS)
    end

    def low_retrieve(stats)
      format_stat stats, LOW_RETR
    end

    def low_graph_load(stats)
      format_stat stats, LOW_GRPH
    end

    def low_normalization(stats)
      format_stat stats, LOW_NORM
    end

    def low_full_request(stats)
      format_stat stats, LOW_ACTN
    end

    def high_retrieve(stats)
      format_stat stats, HIGH_RETR
    end

    def high_graph_load(stats)
      format_stat stats, HIGH_GRPH
    end

    def high_normalization(stats)
      format_stat stats, HIGH_NORM
    end

    def high_full_request(stats)
      format_stat stats, HIGH_ACTN
    end

    def avg_retrieve(stats)
      format_stat stats, AVG_RETR
    end

    def avg_graph_load(stats)
      format_stat stats, AVG_GRPH
    end

    def avg_normalization(stats)
      format_stat stats, AVG_NORM
    end

    def avg_full_request(stats)
      format_stat stats, AVG_ACTN
    end

    def datatable_data_style(stats)
      return "status-not-supported" if unsupported_action?(stats)
      "status-neutral"
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

    def performance_data_start
      start_dt = case expected_time_period
                 when :day
                   performance_data_end_dt - 1.day
                 when :month
                   performance_data_end_dt - 1.month
                 when :year
                   performance_data_end_dt - 1.year
                 else
                   @parent.first_updated_dt
                 end
      QaServer::TimeService.pretty_date(start_dt)
    end

    def performance_data_end_dt
      @parent.last_updated_dt
    end

    def performance_data_end
      QaServer::TimeService.pretty_date(performance_data_end_dt)
    end

    private

      def expected_time_period
        QaServer.config.performance_datatable_default_time_period
      end

      def data_table_for(authority_data, action)
        authority_data[action][FOR_DATATABLE]
      end

      def unsupported_action?(stats)
        values = stats.values
        return true if values.all?(&:zero?)
        values.any? { |v| v.respond_to?(:nan?) && v.nan? }
      end

      def format_stat(stats, idx)
        return '' if stats[idx].nil? || unsupported_action?(stats)
        format("%0.1f", stats[idx])
      end

      def performance_style_class(stats, stat_key)
        return "status-not-supported" if unsupported_action?(stats)
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
