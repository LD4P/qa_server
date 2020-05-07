# frozen_string_literal: true
# This module sets up the hash keys for performance data and allows them to be used across all classes
# setting and reading from the performance data hash.
module QaServer
  module PerformanceHistoryDataKeys
    ALL_AUTH = :all_authorities
    SEARCH = :search
    FETCH = :fetch
    ALL_ACTIONS = :all_actions

    STATS = :stats
    FOR_DATATABLE = :datatable_stats

    FOR_DAY = :day
    BY_HOUR = :hour

    FOR_MONTH = :month
    BY_DAY = :day

    FOR_YEAR = :year
    BY_MONTH = :month

    LOW_LOAD = :low_load_ms
    LOW_RETR = :low_retrieve_ms
    LOW_GRPH = :low_load_graph_ms
    LOW_NORM = :low_normalization_ms
    LOW_ACTN = :low_action_request_ms
    LOW_FULL = :low_full_request_ms
    AVG_LOAD = :avg_load_ms
    AVG_RETR = :avg_retrieve_ms
    AVG_GRPH = :avg_load_graph_ms
    AVG_NORM = :avg_normalization_ms
    AVG_ACTN = :avg_action_request_ms
    AVG_FULL = :avg_full_request_ms
    HIGH_LOAD = :high_load_ms
    HIGH_RETR = :high_retrieve_ms
    HIGH_GRPH = :high_load_graph_ms
    HIGH_NORM = :high_normalization_ms
    HIGH_ACTN = :high_action_request_ms
    HIGH_FULL = :high_full_request_ms

    SRC_BYTES = :data_raw_bytes_from_source
    BPMS_RETR = :retrieve_bytes_per_ms
    MSPB_RETR = :retrieve_ms_per_byte
    BPMS_GRPH = :load_graph_bytes_per_ms
    MSPB_GRPH = :load_graph_ms_per_byte
    BPMS_NORM = :normalization_bytes_per_ms
    MSPB_NORM = :normalization_ms_per_byte
  end
end
