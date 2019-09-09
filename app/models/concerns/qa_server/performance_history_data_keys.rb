# frozen_string_literal: true
# This module sets up the hash keys for performance data and allows them to be used across all classes
# setting and reading from the performance data hash.
module QaServer
  module PerformanceHistoryDataKeys
    ALL_AUTH = :all_authorities
    STATS = :stats
    FOR_DATATABLE = :datatable_stats

    FOR_DAY = :day
    BY_HOUR = :hour

    FOR_MONTH = :month
    BY_DAY = :day

    FOR_YEAR = :year
    BY_MONTH = :month

    LOW_LOAD = :low_load_ms
    LOW_NORM = :low_normalization_ms
    LOW_FULL = :low_full_request_ms
    AVG_LOAD = :avg_load_ms
    AVG_NORM = :avg_normalization_ms
    AVG_FULL = :avg_full_request_ms
    HIGH_LOAD = :max_load_ms
    HIGH_NORM = :max_normalization_ms
    HIGH_FULL = :max_full_request_ms
  end
end
