# frozen_string_literal: true
# This module sets up the hash keys for performance data and allows them to be used across all classes
# setting and reading from the performance data hash.
module QaServer
  module PerformanceHistoryDataKeys
    ALL_AUTH = :all_authorities
    STATS = :stats
    FOR_LIFETIME = :lifetime_stats

    FOR_DAY = :day
    BY_HOUR = :hour

    FOR_MONTH = :month
    BY_DAY = :day

    FOR_YEAR = :year
    BY_MONTH = :month

    SUM_LOAD = :load_sum_ms
    SUM_NORM = :normalization_sum_ms
    SUM_FULL = :full_request_sum_ms
    MIN_LOAD = :load_min_ms
    MIN_NORM = :normalization_min_ms
    MIN_FULL = :full_request_min_ms
    MAX_LOAD = :load_max_ms
    MAX_NORM = :normalization_max_ms
    MAX_FULL = :full_request_max_ms
    AVG_LOAD = :load_avg_ms
    AVG_NORM = :normalization_avg_ms
    AVG_FULL = :full_request_avg_ms
  end
end
