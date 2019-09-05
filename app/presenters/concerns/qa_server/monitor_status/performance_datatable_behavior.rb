# frozen_string_literal: true
# This module provides access methods into the performance data hash.
module QaServer::MonitorStatus
  module PerformanceDatatableBehavior
    include QaServer::PerformanceHistoryDataKeys

    def lifetime_stats(authority_data)
      authority_data[FOR_LIFETIME]
    end

    def min_load(stats)
      format_stat stats[MIN_LOAD]
    end

    def min_normalization(stats)
      format_stat stats[MIN_NORM]
    end

    def min_full_request(stats)
      format_stat stats[MIN_FULL]
    end

    def max_load(stats)
      format_stat stats[MAX_LOAD]
    end

    def max_normalization(stats)
      format_stat stats[MAX_NORM]
    end

    def max_full_request(stats)
      format_stat stats[MAX_FULL]
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

    def min_load_style(stats)
      performance_style_class(stats, MIN_LOAD)
    end

    def min_normalization_style(stats)
      performance_style_class(stats, MIN_NORM)
    end

    def min_full_request_style(stats)
      performance_style_class(stats, MIN_FULL)
    end

    def max_load_style(stats)
      performance_style_class(stats, MAX_LOAD)
    end

    def max_normalization_style(stats)
      performance_style_class(stats, MAX_NORM)
    end

    def max_full_request_style(stats)
      performance_style_class(stats, MAX_FULL)
    end

    def avg_load_style(stats)
      performance_style_class(stats, AVG_LOAD)
    end

    def avg_normalization_style(stats)
      performance_style_class(stats, AVG_NORM)
    end

    def avg_full_request_style(stats)
      performance_style_class(stats, AVG_FULL)
    end

    private

      def all_authorities_performance_data
        performance_data[ALL_AUTH]
      end

      def format_stat(stat)
        format("%0.1f", stat)
      end

      def performance_style_class(stats, stat_key)
        return "status-bad" if max_threshold_exceeded(stats, stat_key)
        return "status-unknown" if min_threshold_not_met(stats, stat_key)
        "status-neutral"
      end

      MAX_THRESHOLD = 1000 # ms
      def max_threshold_exceeded(stats, stat_key)
        return true if stats[stat_key] > MAX_THRESHOLD
        false
      end

      MIN_THRESHOLD = 500 # ms
      def min_threshold_not_met(stats, stat_key)
        return true unless stats[stat_key] < MIN_THRESHOLD
        false
      end
  end
end
